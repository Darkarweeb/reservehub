-- ============================================================
-- ReserveHub Migration 10: Secure Public Booking RPC
-- Creates the atomic, race-condition-safe public booking function.
--
-- Architecture:
--   • Anonymous clients call public.book_appointment() RPC only.
--   • No direct INSERT/UPDATE on appointments for anon role.
--   • All tenant identifiers (org_id, business_id) are derived
--     server-side from the validated business slug — never trusted
--     from the client.
--   • Advisory lock prevents double-booking race conditions.
--   • All validation is atomic within a single transaction.
-- ============================================================

-- ─── ENUM: Booking Result Status ─────────────────────────────
DROP TYPE IF EXISTS public.booking_result_status CASCADE;
CREATE TYPE public.booking_result_status AS ENUM (
  'success',
  'error_business_not_found',
  'error_business_not_published',
  'error_branch_invalid',
  'error_service_inactive',
  'error_service_not_at_branch',
  'error_employee_inactive',
  'error_employee_cannot_provide_service',
  'error_slot_unavailable',
  'error_outside_business_hours',
  'error_employee_unavailable',
  'error_double_booking',
  'error_capacity_exceeded',
  'error_invalid_datetime',
  'error_internal'
);

-- ─── FUNCTION: book_appointment (public RPC) ─────────────────
-- Called by anonymous or authenticated clients.
-- Returns a booking result with appointment_id and secure token on success.
--
-- Parameters (all supplied by client):
--   p_business_slug  — public slug of the business (used to derive org/business IDs)
--   p_branch_id      — UUID of the selected branch
--   p_service_id     — UUID of the selected service
--   p_employee_id    — UUID of the selected employee
--   p_starts_at      — requested appointment start (TIMESTAMPTZ, UTC)
--   p_guest_name     — customer full name
--   p_guest_email    — customer email (optional if phone provided)
--   p_guest_phone    — customer phone (optional if email provided)
--   p_notes          — customer notes (optional)
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
BEGIN
  -- ── 1. Validate guest contact ─────────────────────────────
  IF p_guest_name IS NULL OR char_length(trim(p_guest_name)) = 0 THEN
    RETURN jsonb_build_object('status', 'error_internal', 'message', 'Guest name is required.');
  END IF;
  IF p_guest_email IS NULL AND p_guest_phone IS NULL THEN
    RETURN jsonb_build_object('status', 'error_internal', 'message', 'Email or phone is required.');
  END IF;

  -- ── 2. Resolve business from slug (never trust client-supplied IDs) ──
  SELECT id, organization_id, name, timezone, is_active, publication_status, deleted_at
  INTO v_business
  FROM public.businesses
  WHERE slug = p_business_slug
  LIMIT 1;

  IF NOT FOUND OR v_business.deleted_at IS NOT NULL THEN
    RETURN jsonb_build_object('status', 'error_business_not_found');
  END IF;

  IF v_business.publication_status <> 'published'::public.publication_status
     OR v_business.is_active = FALSE THEN
    RETURN jsonb_build_object('status', 'error_business_not_published');
  END IF;

  -- ── 3. Validate branch belongs to this business ───────────
  SELECT id, business_id, organization_id, timezone, is_active, deleted_at
  INTO v_branch
  FROM public.branches
  WHERE id          = p_branch_id
    AND business_id = v_business.id
  LIMIT 1;

  IF NOT FOUND OR v_branch.deleted_at IS NOT NULL OR v_branch.is_active = FALSE THEN
    RETURN jsonb_build_object('status', 'error_branch_invalid');
  END IF;

  -- ── 4. Validate service is active and belongs to this business ──
  SELECT id, business_id, duration_mins, buffer_before_mins, buffer_after_mins,
         status, is_online_bookable, max_capacity, deleted_at
  INTO v_service
  FROM public.services
  WHERE id          = p_service_id
    AND business_id = v_business.id
  LIMIT 1;

  IF NOT FOUND OR v_service.deleted_at IS NOT NULL
     OR v_service.status <> 'active'::public.service_status
     OR v_service.is_online_bookable = FALSE THEN
    RETURN jsonb_build_object('status', 'error_service_inactive');
  END IF;

  -- ── 5. Validate service is available at this branch ───────
  IF NOT EXISTS (
    SELECT 1 FROM public.branch_services bs
    WHERE bs.branch_id  = p_branch_id
      AND bs.service_id = p_service_id
      AND bs.is_active  = TRUE
  ) THEN
    RETURN jsonb_build_object('status', 'error_service_not_at_branch');
  END IF;

  -- ── 6. Validate employee is active ────────────────────────
  SELECT id, business_id, organization_id, status, is_bookable, deleted_at
  INTO v_employee
  FROM public.employees
  WHERE id          = p_employee_id
    AND business_id = v_business.id
  LIMIT 1;

  IF NOT FOUND OR v_employee.deleted_at IS NOT NULL
     OR v_employee.status <> 'active'::public.employee_status
     OR v_employee.is_bookable = FALSE THEN
    RETURN jsonb_build_object('status', 'error_employee_inactive');
  END IF;

  -- ── 7. Validate employee can provide the service ──────────
  IF NOT EXISTS (
    SELECT 1 FROM public.employee_services es
    WHERE es.employee_id = p_employee_id
      AND es.service_id  = p_service_id
      AND es.is_active   = TRUE
  ) THEN
    RETURN jsonb_build_object('status', 'error_employee_cannot_provide_service');
  END IF;

  -- ── 8. Compute appointment end time ───────────────────────
  -- Use employee-specific duration override if present
  SELECT COALESCE(es.duration_override_mins, v_service.duration_mins)
  INTO v_duration_mins
  FROM public.employee_services es
  WHERE es.employee_id = p_employee_id
    AND es.service_id  = p_service_id
  LIMIT 1;

  IF v_duration_mins IS NULL THEN
    v_duration_mins := v_service.duration_mins;
  END IF;

  v_buffer_before := v_service.buffer_before_mins;
  v_buffer_after  := v_service.buffer_after_mins;
  v_ends_at       := p_starts_at + (v_duration_mins || ' minutes')::INTERVAL;

  -- ── 9. Validate starts_at is in the future ─────────────────
  IF p_starts_at <= NOW() THEN
    RETURN jsonb_build_object('status', 'error_invalid_datetime', 'message', 'Appointment must be in the future.');
  END IF;

  -- ── 10. Validate business hours ───────────────────────────
  -- Use branch timezone for day/time calculation
  v_day_of_week := lower(to_char(p_starts_at AT TIME ZONE v_branch.timezone, 'Day'));
  v_day_of_week := trim(v_day_of_week);
  v_start_time  := (p_starts_at AT TIME ZONE v_branch.timezone)::TIME;
  v_end_time    := (v_ends_at   AT TIME ZONE v_branch.timezone)::TIME;

  SELECT bh.is_open, bh.open_time, bh.close_time
  INTO v_biz_hours
  FROM public.business_hours bh
  WHERE bh.business_id  = v_business.id
    AND bh.day_of_week  = v_day_of_week::public.day_of_week
    AND (bh.branch_id   = p_branch_id OR bh.branch_id IS NULL)
  ORDER BY bh.branch_id NULLS LAST
  LIMIT 1;

  IF NOT FOUND OR v_biz_hours.is_open = FALSE THEN
    RETURN jsonb_build_object('status', 'error_outside_business_hours', 'message', 'Business is closed on this day.');
  END IF;

  IF v_start_time < v_biz_hours.open_time OR v_end_time > v_biz_hours.close_time THEN
    RETURN jsonb_build_object('status', 'error_outside_business_hours', 'message', 'Appointment is outside business hours.');
  END IF;

  -- ── 11. Validate employee working hours ───────────────────
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

  -- ── 12. Check employee time-off / blocked availability ────
  IF EXISTS (
    SELECT 1 FROM public.employee_availability ea
    WHERE ea.employee_id       = p_employee_id
      AND ea.deleted_at        IS NULL
      AND ea.availability_type IN (
        'unavailable'::public.availability_type,
        'time_off'::public.availability_type,
        'holiday'::public.availability_type,
        'blocked'::public.availability_type
      )
      AND ea.start_at < v_ends_at
      AND ea.end_at   > p_starts_at
  ) THEN
    RETURN jsonb_build_object('status', 'error_employee_unavailable', 'message', 'Employee is unavailable at this time.');
  END IF;

  -- ── 13. Check employee breaks ─────────────────────────────
  IF EXISTS (
    SELECT 1 FROM public.breaks b
    WHERE b.employee_id = p_employee_id
      AND b.is_active   = TRUE
      AND (b.day_of_week IS NULL OR b.day_of_week = v_day_of_week::public.day_of_week)
      AND b.start_time  < v_end_time
      AND b.end_time    > v_start_time
  ) THEN
    RETURN jsonb_build_object('status', 'error_employee_unavailable', 'message', 'Employee is on break at this time.');
  END IF;

  -- ── 14. Acquire advisory lock to prevent race conditions ──
  -- Lock key is derived from employee_id to serialize concurrent bookings
  -- for the same employee. Uses pg_try_advisory_xact_lock (released at tx end).
  v_lock_key := ('x' || substr(p_employee_id::TEXT, 1, 8))::BIT(32)::BIGINT;

  IF NOT pg_try_advisory_xact_lock(v_lock_key) THEN
    RETURN jsonb_build_object('status', 'error_double_booking', 'message', 'Slot is being booked. Please try again.');
  END IF;

  -- ── 15. Check for conflicting appointments (with buffer) ──
  SELECT COUNT(*)
  INTO v_conflict_count
  FROM public.appointments a
    JOIN public.appointment_employees ae ON ae.appointment_id = a.id
  WHERE ae.employee_id = p_employee_id
    AND a.deleted_at   IS NULL
    AND a.status NOT IN (
      'cancelled'::public.appointment_status,
      'no_show'::public.appointment_status
    )
    AND (a.starts_at - (a.buffer_before_mins || ' minutes')::INTERVAL)
        < (v_ends_at + (v_buffer_after || ' minutes')::INTERVAL)
    AND (a.ends_at   + (a.buffer_after_mins  || ' minutes')::INTERVAL)
        > (p_starts_at - (v_buffer_before || ' minutes')::INTERVAL);

  IF v_conflict_count > 0 THEN
    RETURN jsonb_build_object('status', 'error_double_booking', 'message', 'This time slot is already booked.');
  END IF;

  -- ── 16. Check service capacity ────────────────────────────
  IF v_service.max_capacity > 1 THEN
    SELECT COUNT(*)
    INTO v_conflict_count
    FROM public.appointments a
    WHERE a.business_id = v_business.id
      AND a.branch_id   = p_branch_id
      AND a.deleted_at  IS NULL
      AND a.status NOT IN (
        'cancelled'::public.appointment_status,
        'no_show'::public.appointment_status
      )
      AND a.starts_at = p_starts_at
      AND EXISTS (
        SELECT 1 FROM public.appointment_services aps
        WHERE aps.appointment_id = a.id
          AND aps.service_id     = p_service_id
      );

    IF v_conflict_count >= v_service.max_capacity THEN
      RETURN jsonb_build_object('status', 'error_capacity_exceeded');
    END IF;
  END IF;

  -- ── 17. Upsert guest customer record ──────────────────────
  -- Avoid duplicate guest records per business per contact.
  IF p_guest_email IS NOT NULL THEN
    SELECT id INTO v_guest_id
    FROM public.guest_customers
    WHERE business_id = v_business.id
      AND lower(email) = lower(p_guest_email)
      AND deleted_at IS NULL
    LIMIT 1;
  END IF;

  IF v_guest_id IS NULL AND p_guest_phone IS NOT NULL THEN
    SELECT id INTO v_guest_id
    FROM public.guest_customers
    WHERE business_id = v_business.id
      AND phone       = p_guest_phone
      AND deleted_at  IS NULL
    LIMIT 1;
  END IF;

  IF v_guest_id IS NULL THEN
    INSERT INTO public.guest_customers (
      organization_id, business_id, full_name, email, phone, source
    ) VALUES (
      v_business.organization_id, v_business.id,
      p_guest_name, p_guest_email, p_guest_phone,
      'guest'::public.customer_source
    )
    RETURNING id INTO v_guest_id;
  ELSE
    -- Update name/contact if changed
    UPDATE public.guest_customers
    SET full_name = p_guest_name,
        email     = COALESCE(p_guest_email, email),
        phone     = COALESCE(p_guest_phone, phone)
    WHERE id = v_guest_id;
  END IF;

  -- Check if there is a matching internal CRM customer
  SELECT id INTO v_customer_id
  FROM public.customers
  WHERE organization_id = v_business.organization_id
    AND deleted_at IS NULL
    AND (
      (p_guest_email IS NOT NULL AND lower(email) = lower(p_guest_email))
      OR
      (p_guest_phone IS NOT NULL AND phone = p_guest_phone)
    )
  LIMIT 1;

  -- ── 18. Generate secure tokens ────────────────────────────
  v_booking_token := encode(gen_random_bytes(32), 'hex');
  v_cancel_token  := encode(gen_random_bytes(32), 'hex');

  -- ── 19. Create appointment (atomic) ───────────────────────
  INSERT INTO public.appointments (
    organization_id,
    business_id,
    branch_id,
    customer_id,
    appointment_type,
    status,
    title,
    notes,
    starts_at,
    ends_at,
    duration_mins,
    buffer_before_mins,
    buffer_after_mins,
    timezone,
    total_price,
    currency,
    booked_online,
    booking_source,
    metadata
  )
  SELECT
    v_business.organization_id,
    v_business.id,
    p_branch_id,
    v_customer_id,
    'single'::public.appointment_type,
    CASE WHEN bs.auto_confirm THEN 'confirmed'::public.appointment_status
         ELSE 'pending'::public.appointment_status END,
    v_service.id::TEXT,  -- will be overwritten below
    p_notes,
    p_starts_at,
    v_ends_at,
    v_duration_mins,
    v_buffer_before,
    v_buffer_after,
    v_branch.timezone,
    COALESCE(es.price_override, v_service.price),
    'USD',
    TRUE,
    'online',
    jsonb_build_object(
      'guest_customer_id', v_guest_id,
      'booking_token',     v_booking_token,
      'cancel_token',      v_cancel_token
    )
  FROM public.booking_settings bs
  LEFT JOIN public.employee_services es
    ON es.employee_id = p_employee_id AND es.service_id = p_service_id
  WHERE bs.business_id = v_business.id
    AND (bs.branch_id = p_branch_id OR bs.branch_id IS NULL)
  ORDER BY bs.branch_id NULLS LAST
  LIMIT 1
  RETURNING id INTO v_appointment_id;

  -- Fallback if no booking_settings row exists yet
  IF v_appointment_id IS NULL THEN
    INSERT INTO public.appointments (
      organization_id, business_id, branch_id, customer_id,
      appointment_type, status, notes,
      starts_at, ends_at, duration_mins,
      buffer_before_mins, buffer_after_mins, timezone,
      total_price, currency, booked_online, booking_source, metadata
    ) VALUES (
      v_business.organization_id, v_business.id, p_branch_id, v_customer_id,
      'single'::public.appointment_type, 'pending'::public.appointment_status, p_notes,
      p_starts_at, v_ends_at, v_duration_mins,
      v_buffer_before, v_buffer_after, v_branch.timezone,
      v_service.price, 'USD', TRUE, 'online',
      jsonb_build_object(
        'guest_customer_id', v_guest_id,
        'booking_token',     v_booking_token,
        'cancel_token',      v_cancel_token
      )
    )
    RETURNING id INTO v_appointment_id;
  END IF;

  -- Update appointment title now that we have the service name
  UPDATE public.appointments
  SET title = (SELECT name FROM public.services WHERE id = p_service_id) || ' - ' || p_guest_name
  WHERE id = v_appointment_id;

  -- ── 20. Link appointment ↔ service ────────────────────────
  INSERT INTO public.appointment_services (
    organization_id, appointment_id, service_id, service_name,
    duration_mins, price, currency
  )
  SELECT
    v_business.organization_id,
    v_appointment_id,
    p_service_id,
    s.name,
    v_duration_mins,
    COALESCE(es.price_override, s.price),
    s.currency
  FROM public.services s
  LEFT JOIN public.employee_services es
    ON es.employee_id = p_employee_id AND es.service_id = p_service_id
  WHERE s.id = p_service_id;

  -- ── 21. Link appointment ↔ employee ───────────────────────
  INSERT INTO public.appointment_employees (
    organization_id, appointment_id, employee_id, service_id, is_primary
  ) VALUES (
    v_business.organization_id, v_appointment_id, p_employee_id, p_service_id, TRUE
  );

  -- ── 22. Update guest customer booking counters ────────────
  UPDATE public.guest_customers
  SET total_bookings = total_bookings + 1,
      last_booked_at = NOW()
  WHERE id = v_guest_id;

  -- ── 23. Return success ────────────────────────────────────
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
    RETURN jsonb_build_object(
      'status',  'error_internal',
      'message', SQLERRM
    );
END;
$$;

-- Grant to anon (public booking) and authenticated
REVOKE ALL ON FUNCTION public.book_appointment(TEXT, UUID, UUID, UUID, TIMESTAMPTZ, TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.book_appointment(TEXT, UUID, UUID, UUID, TIMESTAMPTZ, TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;

-- ─── FUNCTION: get_public_availability ───────────────────────
-- Returns available time slots for a given service/employee/branch/date.
-- Safe for anonymous callers.
CREATE OR REPLACE FUNCTION public.get_public_availability(
  p_business_slug TEXT,
  p_branch_id     UUID,
  p_service_id    UUID,
  p_employee_id   UUID,
  p_date          DATE
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_business      RECORD;
  v_branch        RECORD;
  v_service       RECORD;
  v_duration_mins INTEGER;
  v_buffer_after  INTEGER;
  v_day_of_week   TEXT;
  v_biz_hours     RECORD;
  v_work_hours    RECORD;
  v_slot_start    TIME;
  v_slot_end      TIME;
  v_slot_step     INTEGER := 15; -- minutes between slot starts
  v_slots         JSONB   := '[]'::JSONB;
  v_slot_ts       TIMESTAMPTZ;
  v_slot_end_ts   TIMESTAMPTZ;
  v_is_available  BOOLEAN;
BEGIN
  -- Resolve business
  SELECT id, organization_id, timezone, publication_status, is_active, deleted_at
  INTO v_business
  FROM public.businesses
  WHERE slug = p_business_slug LIMIT 1;

  IF NOT FOUND OR v_business.deleted_at IS NOT NULL
     OR v_business.publication_status <> 'published'::public.publication_status
     OR v_business.is_active = FALSE THEN
    RETURN jsonb_build_object('error', 'Business not found or not published.');
  END IF;

  -- Resolve branch
  SELECT id, timezone FROM public.branches
  WHERE id = p_branch_id AND business_id = v_business.id
    AND is_active = TRUE AND deleted_at IS NULL
  INTO v_branch LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Branch not found.');
  END IF;

  -- Resolve service duration
  SELECT COALESCE(es.duration_override_mins, s.duration_mins),
         s.buffer_after_mins
  INTO v_duration_mins, v_buffer_after
  FROM public.services s
  LEFT JOIN public.employee_services es
    ON es.employee_id = p_employee_id AND es.service_id = s.id
  WHERE s.id = p_service_id AND s.business_id = v_business.id
    AND s.status = 'active'::public.service_status
    AND s.deleted_at IS NULL
  LIMIT 1;

  IF v_duration_mins IS NULL THEN
    RETURN jsonb_build_object('error', 'Service not found.');
  END IF;

  v_day_of_week := trim(lower(to_char(p_date, 'Day')));

  -- Get business/branch hours for the day
  SELECT bh.is_open, bh.open_time, bh.close_time
  INTO v_biz_hours
  FROM public.business_hours bh
  WHERE bh.business_id = v_business.id
    AND bh.day_of_week = v_day_of_week::public.day_of_week
    AND (bh.branch_id = p_branch_id OR bh.branch_id IS NULL)
  ORDER BY bh.branch_id NULLS LAST LIMIT 1;

  IF NOT FOUND OR v_biz_hours.is_open = FALSE THEN
    RETURN jsonb_build_object('slots', '[]'::JSONB, 'date', p_date);
  END IF;

  -- Get employee working hours
  SELECT wh.is_working, wh.start_time, wh.end_time
  INTO v_work_hours
  FROM public.working_hours wh
  WHERE wh.employee_id = p_employee_id
    AND wh.day_of_week = v_day_of_week::public.day_of_week
  LIMIT 1;

  IF NOT FOUND OR v_work_hours.is_working = FALSE THEN
    RETURN jsonb_build_object('slots', '[]'::JSONB, 'date', p_date);
  END IF;

  v_slot_start := GREATEST(v_biz_hours.open_time, v_work_hours.start_time);
  v_slot_end   := LEAST(v_biz_hours.close_time, v_work_hours.end_time);

  -- Iterate slots
  WHILE v_slot_start + (v_duration_mins || ' minutes')::INTERVAL <= v_slot_end LOOP
    v_slot_ts     := (p_date::TEXT || ' ' || v_slot_start::TEXT)::TIMESTAMPTZ
                     AT TIME ZONE v_branch.timezone;
    v_slot_end_ts := v_slot_ts + (v_duration_mins || ' minutes')::INTERVAL;

    -- Skip past slots
    IF v_slot_ts > NOW() THEN
      -- Check conflicts
      SELECT NOT EXISTS (
        SELECT 1
        FROM public.appointments a
          JOIN public.appointment_employees ae ON ae.appointment_id = a.id
        WHERE ae.employee_id = p_employee_id
          AND a.deleted_at IS NULL
          AND a.status NOT IN ('cancelled'::public.appointment_status, 'no_show'::public.appointment_status)
          AND (a.starts_at - (a.buffer_before_mins || ' minutes')::INTERVAL) < v_slot_end_ts
          AND (a.ends_at   + (a.buffer_after_mins  || ' minutes')::INTERVAL) > v_slot_ts
      )
      AND NOT EXISTS (
        SELECT 1 FROM public.employee_availability ea
        WHERE ea.employee_id = p_employee_id
          AND ea.deleted_at IS NULL
          AND ea.availability_type IN (
            'unavailable'::public.availability_type,
            'time_off'::public.availability_type,
            'holiday'::public.availability_type,
            'blocked'::public.availability_type
          )
          AND ea.start_at < v_slot_end_ts
          AND ea.end_at   > v_slot_ts
      )
      AND NOT EXISTS (
        SELECT 1 FROM public.breaks b
        WHERE b.employee_id = p_employee_id
          AND b.is_active = TRUE
          AND (b.day_of_week IS NULL OR b.day_of_week = v_day_of_week::public.day_of_week)
          AND b.start_time < (v_slot_start + (v_duration_mins || ' minutes')::INTERVAL)::TIME
          AND b.end_time   > v_slot_start
      )
      INTO v_is_available;

      IF v_is_available THEN
        v_slots := v_slots || jsonb_build_object(
          'starts_at', v_slot_ts,
          'ends_at',   v_slot_end_ts
        );
      END IF;
    END IF;

    v_slot_start := v_slot_start + (v_slot_step || ' minutes')::INTERVAL;
  END LOOP;

  RETURN jsonb_build_object('slots', v_slots, 'date', p_date);
END;
$$;

REVOKE ALL ON FUNCTION public.get_public_availability(TEXT, UUID, UUID, UUID, DATE) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_public_availability(TEXT, UUID, UUID, UUID, DATE) TO anon, authenticated;
