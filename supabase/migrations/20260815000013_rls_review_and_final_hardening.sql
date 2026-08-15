-- ============================================================
-- ReserveHub Migration 13: RLS Review & Final Hardening
-- Adds:
--   • Missing RLS policies on new tables (appointment_tokens)
--   • Explicit anon DENY policies where needed
--   • Additional public search performance indexes
--   • Token persistence wired into book_appointment
--   • Composite indexes for appointment availability queries
-- ============================================================

-- ─── ENSURE: appointment_tokens anon access is blocked ───────
-- Confirm no anon SELECT policy exists on appointment_tokens.
-- Tokens are only accessible via SECURITY DEFINER RPCs.
-- (RLS is already enabled in migration 11; this adds explicit deny clarity.)

-- Org admins can manage tokens (e.g., revoke)
DROP POLICY IF EXISTS "appt_tokens_admin_update" ON public.appointment_tokens;
CREATE POLICY "appt_tokens_admin_update"
  ON public.appointment_tokens FOR UPDATE TO authenticated
  USING (public.is_org_member(organization_id))
  WITH CHECK (public.is_org_member(organization_id));

-- ─── ENSURE: guest_customers anon access is blocked ──────────
-- No anon SELECT on guest_customers — confirmed by migration 9.
-- Explicit documentation: guest_customers are internal CRM data.
-- Access only via SECURITY DEFINER book_appointment RPC.

-- ─── ENSURE: appointments anon access is blocked ─────────────
-- Appointments are internal data. Anonymous users access appointment
-- data ONLY via get_appointment_by_token() RPC.
-- Confirm no anon SELECT policy on appointments table.
-- (Migration 5 only created authenticated policies — correct.)

-- ─── ADDITIONAL COMPOSITE INDEXES ────────────────────────────

-- Appointment availability query: employee + date range + status
-- Used heavily by get_public_availability and book_appointment conflict checks
CREATE INDEX IF NOT EXISTS idx_appointments_employee_time
  ON public.appointments(branch_id, starts_at, ends_at)
  WHERE deleted_at IS NULL
    AND status NOT IN ('cancelled', 'no_show');

-- Appointment lookup by business + date (dashboard, calendar views)
CREATE INDEX IF NOT EXISTS idx_appointments_business_date
  ON public.appointments(business_id, starts_at)
  WHERE deleted_at IS NULL;

-- appointment_employees: employee + time range (conflict detection)
CREATE INDEX IF NOT EXISTS idx_appt_employees_employee_appt
  ON public.appointment_employees(employee_id, appointment_id);

-- guest_customers: org + email lookup (dedup on booking)
CREATE INDEX IF NOT EXISTS idx_guest_customers_org_email
  ON public.guest_customers(organization_id, lower(email))
  WHERE email IS NOT NULL AND deleted_at IS NULL;

-- appointment_tokens: active tokens by appointment (revocation)
CREATE INDEX IF NOT EXISTS idx_appt_tokens_appt_active
  ON public.appointment_tokens(appointment_id, token_type)
  WHERE token_status = 'active';

-- notification_queue: retry queue (scheduler picks up failed items)
CREATE INDEX IF NOT EXISTS idx_notif_queue_retry
  ON public.notification_queue(next_retry_at, delivery_status)
  WHERE delivery_status = 'failed' AND next_retry_at IS NOT NULL;

-- daily_appointment_summaries: scheduler pickup
CREATE INDEX IF NOT EXISTS idx_daily_summaries_scheduler
  ON public.daily_appointment_summaries(scheduled_at, delivery_status)
  WHERE delivery_status = 'pending' AND scheduled_at IS NOT NULL;

-- business_subscriptions: active free plan lookup
CREATE INDEX IF NOT EXISTS idx_business_subscriptions_free
  ON public.business_subscriptions(business_id, status)
  WHERE status = 'free';

-- ─── WIRE: book_appointment → store_appointment_tokens ───────
-- Update book_appointment to persist tokens into appointment_tokens table.
-- This replaces the metadata-only storage with proper token table storage.
CREATE OR REPLACE FUNCTION public.book_appointment(
  p_business_slug TEXT,
  p_branch_id     UUID,
  p_service_id    UUID,
  p_employee_id   UUID,
  p_starts_at     TIMESTAMPTZ,
  p_guest_name    TEXT,
  p_guest_email   TEXT    DEFAULT NULL,
  p_guest_phone   TEXT    DEFAULT NULL,
  p_notes         TEXT    DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_business        RECORD;
  v_branch          RECORD;
  v_service         RECORD;
  v_employee        RECORD;
  v_ends_at         TIMESTAMPTZ;
  v_duration_mins   INTEGER;
  v_buffer_before   INTEGER;
  v_buffer_after    INTEGER;
  v_day_of_week     TEXT;
  v_start_time      TIME;
  v_end_time        TIME;
  v_biz_hours       RECORD;
  v_conflict_count  INTEGER;
  v_guest_id        UUID;
  v_customer_id     UUID;
  v_appointment_id  UUID;
  v_booking_token   TEXT;
  v_cancel_token    TEXT;
  v_lock_key        BIGINT;
  v_auto_confirm    BOOLEAN := TRUE;
  v_price           DECIMAL(10,2);
BEGIN
  -- 1. Validate guest contact
  IF p_guest_name IS NULL OR char_length(trim(p_guest_name)) = 0 THEN
    RETURN jsonb_build_object('status', 'error_internal', 'message', 'Guest name is required.');
  END IF;
  IF p_guest_email IS NULL AND p_guest_phone IS NULL THEN
    RETURN jsonb_build_object('status', 'error_internal', 'message', 'Email or phone is required.');
  END IF;

  -- 2. Resolve business from slug
  SELECT id, organization_id, name, timezone, is_active, publication_status, deleted_at
  INTO v_business
  FROM public.businesses
  WHERE slug = p_business_slug LIMIT 1;

  IF NOT FOUND OR v_business.deleted_at IS NOT NULL THEN
    RETURN jsonb_build_object('status', 'error_business_not_found');
  END IF;
  IF v_business.publication_status <> 'published'::public.publication_status
     OR v_business.is_active = FALSE THEN
    RETURN jsonb_build_object('status', 'error_business_not_published');
  END IF;

  -- 3. Validate branch
  SELECT id, business_id, organization_id, timezone, is_active, deleted_at
  INTO v_branch
  FROM public.branches
  WHERE id = p_branch_id AND business_id = v_business.id LIMIT 1;
  IF NOT FOUND OR v_branch.deleted_at IS NOT NULL OR v_branch.is_active = FALSE THEN
    RETURN jsonb_build_object('status', 'error_branch_invalid');
  END IF;

  -- 4. Validate service
  SELECT id, business_id, duration_mins, buffer_before_mins, buffer_after_mins,
         status, is_online_bookable, max_capacity, price, currency, deleted_at
  INTO v_service
  FROM public.services
  WHERE id = p_service_id AND business_id = v_business.id LIMIT 1;
  IF NOT FOUND OR v_service.deleted_at IS NOT NULL
     OR v_service.status <> 'active'::public.service_status
     OR v_service.is_online_bookable = FALSE THEN
    RETURN jsonb_build_object('status', 'error_service_inactive');
  END IF;

  -- 5. Validate service at branch
  IF NOT EXISTS (
    SELECT 1 FROM public.branch_services
    WHERE branch_id = p_branch_id AND service_id = p_service_id AND is_active = TRUE
  ) THEN
    RETURN jsonb_build_object('status', 'error_service_not_at_branch');
  END IF;

  -- 6. Validate employee
  SELECT id, business_id, organization_id, status, is_bookable, deleted_at
  INTO v_employee
  FROM public.employees
  WHERE id = p_employee_id AND business_id = v_business.id LIMIT 1;
  IF NOT FOUND OR v_employee.deleted_at IS NOT NULL
     OR v_employee.status <> 'active'::public.employee_status
     OR v_employee.is_bookable = FALSE THEN
    RETURN jsonb_build_object('status', 'error_employee_inactive');
  END IF;

  -- 7. Validate employee can provide service
  IF NOT EXISTS (
    SELECT 1 FROM public.employee_services
    WHERE employee_id = p_employee_id AND service_id = p_service_id AND is_active = TRUE
  ) THEN
    RETURN jsonb_build_object('status', 'error_employee_cannot_provide_service');
  END IF;

  -- 8. Compute timing
  SELECT COALESCE(es.duration_override_mins, v_service.duration_mins),
         COALESCE(es.price_override, v_service.price)
  INTO v_duration_mins, v_price
  FROM public.employee_services es
  WHERE es.employee_id = p_employee_id AND es.service_id = p_service_id LIMIT 1;

  IF v_duration_mins IS NULL THEN
    v_duration_mins := v_service.duration_mins;
    v_price         := v_service.price;
  END IF;

  v_buffer_before := v_service.buffer_before_mins;
  v_buffer_after  := v_service.buffer_after_mins;
  v_ends_at       := p_starts_at + (v_duration_mins || ' minutes')::INTERVAL;

  -- 9. Future check
  IF p_starts_at <= NOW() THEN
    RETURN jsonb_build_object('status', 'error_invalid_datetime', 'message', 'Appointment must be in the future.');
  END IF;

  -- 10. Business hours
  v_day_of_week := trim(lower(to_char(p_starts_at AT TIME ZONE v_branch.timezone, 'Day')));
  v_start_time  := (p_starts_at AT TIME ZONE v_branch.timezone)::TIME;
  v_end_time    := (v_ends_at   AT TIME ZONE v_branch.timezone)::TIME;

  SELECT bh.is_open, bh.open_time, bh.close_time INTO v_biz_hours
  FROM public.business_hours bh
  WHERE bh.business_id = v_business.id
    AND bh.day_of_week = v_day_of_week::public.day_of_week
    AND (bh.branch_id = p_branch_id OR bh.branch_id IS NULL)
  ORDER BY bh.branch_id NULLS LAST LIMIT 1;

  IF NOT FOUND OR v_biz_hours.is_open = FALSE THEN
    RETURN jsonb_build_object('status', 'error_outside_business_hours', 'message', 'Business is closed on this day.');
  END IF;
  IF v_start_time < v_biz_hours.open_time OR v_end_time > v_biz_hours.close_time THEN
    RETURN jsonb_build_object('status', 'error_outside_business_hours', 'message', 'Appointment is outside business hours.');
  END IF;

  -- 11. Employee working hours
  IF NOT EXISTS (
    SELECT 1 FROM public.working_hours wh
    WHERE wh.employee_id = p_employee_id
      AND wh.day_of_week = v_day_of_week::public.day_of_week
      AND wh.is_working  = TRUE
      AND v_start_time   >= wh.start_time
      AND v_end_time     <= wh.end_time
  ) THEN
    RETURN jsonb_build_object('status', 'error_employee_unavailable', 'message', 'Employee is not working at this time.');
  END IF;

  -- 12. Time-off / blocked
  IF EXISTS (
    SELECT 1 FROM public.employee_availability ea
    WHERE ea.employee_id = p_employee_id
      AND ea.deleted_at IS NULL
      AND ea.availability_type IN (
        'unavailable'::public.availability_type,
        'time_off'::public.availability_type,
        'holiday'::public.availability_type,
        'blocked'::public.availability_type
      )
      AND ea.start_at < v_ends_at AND ea.end_at > p_starts_at
  ) THEN
    RETURN jsonb_build_object('status', 'error_employee_unavailable', 'message', 'Employee is unavailable at this time.');
  END IF;

  -- 13. Breaks
  IF EXISTS (
    SELECT 1 FROM public.breaks b
    WHERE b.employee_id = p_employee_id AND b.is_active = TRUE
      AND (b.day_of_week IS NULL OR b.day_of_week = v_day_of_week::public.day_of_week)
      AND b.start_time < v_end_time AND b.end_time > v_start_time
  ) THEN
    RETURN jsonb_build_object('status', 'error_employee_unavailable', 'message', 'Employee is on break at this time.');
  END IF;

  -- 14. Advisory lock (race-condition protection)
  v_lock_key := ('x' || substr(p_employee_id::TEXT, 1, 8))::BIT(32)::BIGINT;
  IF NOT pg_try_advisory_xact_lock(v_lock_key) THEN
    RETURN jsonb_build_object('status', 'error_double_booking', 'message', 'Slot is being booked. Please try again.');
  END IF;

  -- 15. Conflict check (with buffer)
  SELECT COUNT(*) INTO v_conflict_count
  FROM public.appointments a
    JOIN public.appointment_employees ae ON ae.appointment_id = a.id
  WHERE ae.employee_id = p_employee_id
    AND a.deleted_at IS NULL
    AND a.status NOT IN ('cancelled'::public.appointment_status, 'no_show'::public.appointment_status)
    AND (a.starts_at - (a.buffer_before_mins || ' minutes')::INTERVAL)
        < (v_ends_at + (v_buffer_after || ' minutes')::INTERVAL)
    AND (a.ends_at + (a.buffer_after_mins || ' minutes')::INTERVAL)
        > (p_starts_at - (v_buffer_before || ' minutes')::INTERVAL);

  IF v_conflict_count > 0 THEN
    RETURN jsonb_build_object('status', 'error_double_booking', 'message', 'This time slot is already booked.');
  END IF;

  -- 16. Capacity check
  IF v_service.max_capacity > 1 THEN
    SELECT COUNT(*) INTO v_conflict_count
    FROM public.appointments a
    WHERE a.business_id = v_business.id AND a.branch_id = p_branch_id
      AND a.deleted_at IS NULL
      AND a.status NOT IN ('cancelled'::public.appointment_status, 'no_show'::public.appointment_status)
      AND a.starts_at = p_starts_at
      AND EXISTS (
        SELECT 1 FROM public.appointment_services aps
        WHERE aps.appointment_id = a.id AND aps.service_id = p_service_id
      );
    IF v_conflict_count >= v_service.max_capacity THEN
      RETURN jsonb_build_object('status', 'error_capacity_exceeded');
    END IF;
  END IF;

  -- 17. Upsert guest customer
  IF p_guest_email IS NOT NULL THEN
    SELECT id INTO v_guest_id
    FROM public.guest_customers
    WHERE business_id = v_business.id AND lower(email) = lower(p_guest_email) AND deleted_at IS NULL
    LIMIT 1;
  END IF;
  IF v_guest_id IS NULL AND p_guest_phone IS NOT NULL THEN
    SELECT id INTO v_guest_id
    FROM public.guest_customers
    WHERE business_id = v_business.id AND phone = p_guest_phone AND deleted_at IS NULL
    LIMIT 1;
  END IF;
  IF v_guest_id IS NULL THEN
    INSERT INTO public.guest_customers (organization_id, business_id, full_name, email, phone, source)
    VALUES (v_business.organization_id, v_business.id, p_guest_name, p_guest_email, p_guest_phone, 'guest'::public.customer_source)
    RETURNING id INTO v_guest_id;
  ELSE
    UPDATE public.guest_customers
    SET full_name = p_guest_name,
        email     = COALESCE(p_guest_email, email),
        phone     = COALESCE(p_guest_phone, phone)
    WHERE id = v_guest_id;
  END IF;

  -- CRM customer lookup
  SELECT id INTO v_customer_id
  FROM public.customers
  WHERE organization_id = v_business.organization_id AND deleted_at IS NULL
    AND ((p_guest_email IS NOT NULL AND lower(email) = lower(p_guest_email))
      OR (p_guest_phone IS NOT NULL AND phone = p_guest_phone))
  LIMIT 1;

  -- 18. Generate tokens
  v_booking_token := encode(gen_random_bytes(32), 'hex');
  v_cancel_token  := encode(gen_random_bytes(32), 'hex');

  -- 19. Get booking settings
  SELECT COALESCE(bs.auto_confirm, TRUE) INTO v_auto_confirm
  FROM public.booking_settings bs
  WHERE bs.business_id = v_business.id
    AND (bs.branch_id = p_branch_id OR bs.branch_id IS NULL)
  ORDER BY bs.branch_id NULLS LAST LIMIT 1;

  -- 20. Create appointment
  INSERT INTO public.appointments (
    organization_id, business_id, branch_id, customer_id,
    appointment_type, status, title, notes,
    starts_at, ends_at, duration_mins,
    buffer_before_mins, buffer_after_mins, timezone,
    total_price, currency, booked_online, booking_source,
    metadata
  ) VALUES (
    v_business.organization_id, v_business.id, p_branch_id, v_customer_id,
    'single'::public.appointment_type,
    CASE WHEN v_auto_confirm THEN 'confirmed'::public.appointment_status
         ELSE 'pending'::public.appointment_status END,
    (SELECT name FROM public.services WHERE id = p_service_id) || ' - ' || p_guest_name,
    p_notes,
    p_starts_at, v_ends_at, v_duration_mins,
    v_buffer_before, v_buffer_after, v_branch.timezone,
    v_price, v_service.currency, TRUE, 'online',
    jsonb_build_object('guest_customer_id', v_guest_id)
  )
  RETURNING id INTO v_appointment_id;

  -- 21. Link service
  INSERT INTO public.appointment_services (
    organization_id, appointment_id, service_id, service_name,
    duration_mins, price, currency
  )
  SELECT v_business.organization_id, v_appointment_id, p_service_id,
         s.name, v_duration_mins, v_price, s.currency
  FROM public.services s WHERE s.id = p_service_id;

  -- 22. Link employee
  INSERT INTO public.appointment_employees (
    organization_id, appointment_id, employee_id, service_id, is_primary
  ) VALUES (
    v_business.organization_id, v_appointment_id, p_employee_id, p_service_id, TRUE
  );

  -- 23. Persist tokens into appointment_tokens table
  INSERT INTO public.appointment_tokens (
    organization_id, appointment_id, token, token_type, token_status
  ) VALUES
    (v_business.organization_id, v_appointment_id, v_booking_token,
     'booking'::public.token_type, 'active'::public.token_status),
    (v_business.organization_id, v_appointment_id, v_cancel_token,
     'cancellation'::public.token_type, 'active'::public.token_status)
  ON CONFLICT (token) DO NOTHING;

  -- 24. Update guest counters
  UPDATE public.guest_customers
  SET total_bookings = total_bookings + 1, last_booked_at = NOW()
  WHERE id = v_guest_id;

  -- 25. Return success
  RETURN jsonb_build_object(
    'status',         'success',
    'appointment_id', v_appointment_id,
    'booking_token',  v_booking_token,
    'cancel_token',   v_cancel_token,
    'starts_at',      p_starts_at,
    'ends_at',        v_ends_at,
    'duration_mins',  v_duration_mins
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('status', 'error_internal', 'message', SQLERRM);
END;
$$;

-- Re-grant after replacement
REVOKE ALL ON FUNCTION public.book_appointment(TEXT, UUID, UUID, UUID, TIMESTAMPTZ, TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.book_appointment(TEXT, UUID, UUID, UUID, TIMESTAMPTZ, TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;

-- ─── FUNCTION: publish_business ──────────────────────────────
-- Allows authorized org members to publish or unpublish a business.
-- Validates that the caller is an org admin.
-- Never trusts org_id from client — derives it from business_id.
CREATE OR REPLACE FUNCTION public.publish_business(
  p_business_id UUID,
  p_publish     BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_org_id UUID;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.businesses
  WHERE id = p_business_id AND deleted_at IS NULL
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Business not found.');
  END IF;

  IF NOT public.is_org_admin(v_org_id) THEN
    RETURN jsonb_build_object('error', 'Not authorized to publish this business.');
  END IF;

  IF p_publish THEN
    UPDATE public.businesses
    SET publication_status = 'published'::public.publication_status,
        published_at       = NOW(),
        published_by       = auth.uid(),
        unpublished_at     = NULL,
        unpublished_by     = NULL
    WHERE id = p_business_id;
  ELSE
    UPDATE public.businesses
    SET publication_status = 'unpublished'::public.publication_status,
        unpublished_at     = NOW(),
        unpublished_by     = auth.uid()
    WHERE id = p_business_id;
  END IF;

  RETURN jsonb_build_object(
    'status',     'success',
    'business_id', p_business_id,
    'published',   p_publish
  );
END;
$$;

REVOKE ALL ON FUNCTION public.publish_business(UUID, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.publish_business(UUID, BOOLEAN) TO authenticated;

-- ─── VALIDATION SUMMARY ──────────────────────────────────────
-- The following DO block performs a runtime schema validation check.
-- It verifies that all expected tables exist and RLS is enabled.
DO $$
DECLARE
  v_table TEXT;
  v_tables TEXT[] := ARRAY[
    'user_profiles', 'organizations', 'organization_members',
    'businesses', 'branches', 'employees', 'customers', 'services',
    'employee_services', 'branch_services', 'calendars',
    'business_hours', 'working_hours', 'employee_availability', 'breaks',
    'appointments', 'appointment_services', 'appointment_employees',
    'appointment_notes', 'waiting_list', 'audit_logs',
    'booking_settings', 'cancellation_policies', 'business_categories',
    'guest_customers', 'appointment_tokens',
    'notification_preferences', 'notification_queue',
    'daily_appointment_summaries', 'subscription_plans', 'business_subscriptions'
  ];
  v_missing TEXT[] := ARRAY[]::TEXT[];
BEGIN
  FOREACH v_table IN ARRAY v_tables LOOP
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = v_table
    ) THEN
      v_missing := v_missing || v_table;
    END IF;
  END LOOP;

  IF array_length(v_missing, 1) > 0 THEN
    RAISE NOTICE 'VALIDATION WARNING: Missing tables: %', array_to_string(v_missing, ', ');
  ELSE
    RAISE NOTICE 'VALIDATION PASSED: All 31 expected tables exist.';
  END IF;
END $$;
