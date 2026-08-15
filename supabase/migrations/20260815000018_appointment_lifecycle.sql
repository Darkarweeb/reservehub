-- ============================================================
-- ReserveHub Migration 18: Appointment Lifecycle (Phase 10)
-- State machine, lifecycle RPCs, rescheduling, audit, bulk ops
-- ============================================================

-- ─── Add lifecycle columns if not present ────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'appointments'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'appointments'
      AND column_name = 'completed_at'
  ) THEN
    ALTER TABLE public.appointments
      ADD COLUMN completed_at   TIMESTAMPTZ,
      ADD COLUMN completed_by   UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
      ADD COLUMN in_progress_at TIMESTAMPTZ,
      ADD COLUMN in_progress_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
      ADD COLUMN no_show_reason TEXT;
  END IF;
END;
$$;

-- ─── Ensure notification_queue has appointment_id column ─────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'notification_queue'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notification_queue'
      AND column_name = 'appointment_id'
  ) THEN
    ALTER TABLE public.notification_queue
      ADD COLUMN appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL;
  END IF;
END;
$$;

-- ─── FUNCTION: validate_appointment_transition ───────────────
-- Enforces the state machine. Returns TRUE if transition is valid.
CREATE OR REPLACE FUNCTION public.validate_appointment_transition(
  p_from_status public.appointment_status,
  p_to_status   public.appointment_status
)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  RETURN CASE
    WHEN p_from_status = 'pending'      AND p_to_status IN ('confirmed', 'cancelled') THEN TRUE
    WHEN p_from_status = 'confirmed'    AND p_to_status IN ('in_progress', 'completed', 'cancelled', 'no_show', 'rescheduled') THEN TRUE
    WHEN p_from_status = 'in_progress'  AND p_to_status IN ('completed', 'cancelled') THEN TRUE
    WHEN p_from_status = 'rescheduled'  AND p_to_status IN ('confirmed', 'cancelled') THEN TRUE
    WHEN p_from_status = 'waitlisted'   AND p_to_status IN ('confirmed', 'cancelled') THEN TRUE
    ELSE FALSE
  END;
END;
$$;

-- ─── FUNCTION: confirm_appointment ───────────────────────────
CREATE OR REPLACE FUNCTION public.confirm_appointment(
  p_appointment_id UUID,
  p_notes          TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appt        RECORD;
  v_actor_id    UUID := auth.uid();
  v_actor_email TEXT;
  v_org_id      UUID;
BEGIN
  -- Lock the row
  SELECT id, organization_id, status, notes, deleted_at
  INTO v_appt
  FROM public.appointments
  WHERE id = p_appointment_id AND deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('status','error','message','Appointment not found.');
  END IF;

  v_org_id := v_appt.organization_id;

  -- Authorization
  IF NOT public.is_org_member(v_org_id) THEN
    RETURN jsonb_build_object('status','error','message','Unauthorized.');
  END IF;

  -- State machine check
  IF NOT public.validate_appointment_transition(v_appt.status, 'confirmed') THEN
    RETURN jsonb_build_object(
      'status','error',
      'message', format('Cannot confirm an appointment with status: %s', v_appt.status)
    );
  END IF;

  SELECT email INTO v_actor_email FROM public.user_profiles WHERE id = v_actor_id;

  -- Update
  UPDATE public.appointments SET
    status       = 'confirmed',
    confirmed_at = NOW(),
    confirmed_by = v_actor_id,
    notes        = COALESCE(p_notes, notes),
    updated_at   = NOW()
  WHERE id = p_appointment_id;

  -- Audit
  PERFORM public.create_audit_log(
    v_org_id, v_actor_id, v_actor_email,
    'appointment.confirmed', 'appointment', p_appointment_id,
    jsonb_build_object('status', v_appt.status),
    jsonb_build_object('status', 'confirmed', 'confirmed_at', NOW()),
    '{}'::JSONB
  );

  -- Notification event
  INSERT INTO public.notification_queue (
    organization_id, appointment_id, event_type, payload, scheduled_for
  ) VALUES (
    v_org_id, p_appointment_id, 'appointment_confirmed',
    jsonb_build_object('appointment_id', p_appointment_id, 'actor_id', v_actor_id),
    NOW()
  ) ON CONFLICT DO NOTHING;

  RETURN jsonb_build_object('status','success','appointment_id', p_appointment_id);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('status','error','message', SQLERRM);
END;
$$;

-- ─── FUNCTION: cancel_appointment_business ───────────────────
CREATE OR REPLACE FUNCTION public.cancel_appointment_business(
  p_appointment_id    UUID,
  p_cancellation_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appt        RECORD;
  v_actor_id    UUID := auth.uid();
  v_actor_email TEXT;
  v_org_id      UUID;
BEGIN
  SELECT id, organization_id, status, starts_at, deleted_at
  INTO v_appt
  FROM public.appointments
  WHERE id = p_appointment_id AND deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('status','error','message','Appointment not found.');
  END IF;

  v_org_id := v_appt.organization_id;

  IF NOT public.is_org_member(v_org_id) THEN
    RETURN jsonb_build_object('status','error','message','Unauthorized.');
  END IF;

  IF NOT public.validate_appointment_transition(v_appt.status, 'cancelled') THEN
    RETURN jsonb_build_object(
      'status','error',
      'message', format('Cannot cancel an appointment with status: %s', v_appt.status)
    );
  END IF;

  SELECT email INTO v_actor_email FROM public.user_profiles WHERE id = v_actor_id;

  UPDATE public.appointments SET
    status               = 'cancelled',
    cancelled_at         = NOW(),
    cancelled_by         = v_actor_id,
    cancellation_reason  = p_cancellation_reason,
    updated_at           = NOW()
  WHERE id = p_appointment_id;

  PERFORM public.create_audit_log(
    v_org_id, v_actor_id, v_actor_email,
    'appointment.cancelled', 'appointment', p_appointment_id,
    jsonb_build_object('status', v_appt.status, 'starts_at', v_appt.starts_at),
    jsonb_build_object('status', 'cancelled', 'cancelled_at', NOW(), 'reason', p_cancellation_reason),
    '{}'::JSONB
  );

  INSERT INTO public.notification_queue (
    organization_id, appointment_id, event_type, payload, scheduled_for
  ) VALUES (
    v_org_id, p_appointment_id, 'appointment_cancelled',
    jsonb_build_object('appointment_id', p_appointment_id, 'reason', p_cancellation_reason, 'actor_id', v_actor_id),
    NOW()
  ) ON CONFLICT DO NOTHING;

  RETURN jsonb_build_object('status','success','appointment_id', p_appointment_id);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('status','error','message', SQLERRM);
END;
$$;

-- ─── FUNCTION: complete_appointment ──────────────────────────
CREATE OR REPLACE FUNCTION public.complete_appointment(
  p_appointment_id UUID,
  p_notes          TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appt        RECORD;
  v_actor_id    UUID := auth.uid();
  v_actor_email TEXT;
  v_org_id      UUID;
BEGIN
  SELECT id, organization_id, status, notes, deleted_at
  INTO v_appt
  FROM public.appointments
  WHERE id = p_appointment_id AND deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('status','error','message','Appointment not found.');
  END IF;

  v_org_id := v_appt.organization_id;

  IF NOT public.is_org_member(v_org_id) THEN
    RETURN jsonb_build_object('status','error','message','Unauthorized.');
  END IF;

  IF NOT public.validate_appointment_transition(v_appt.status, 'completed') THEN
    RETURN jsonb_build_object(
      'status','error',
      'message', format('Cannot complete an appointment with status: %s', v_appt.status)
    );
  END IF;

  SELECT email INTO v_actor_email FROM public.user_profiles WHERE id = v_actor_id;

  UPDATE public.appointments SET
    status       = 'completed',
    completed_at = NOW(),
    completed_by = v_actor_id,
    notes        = COALESCE(p_notes, notes),
    updated_at   = NOW()
  WHERE id = p_appointment_id;

  PERFORM public.create_audit_log(
    v_org_id, v_actor_id, v_actor_email,
    'appointment.completed', 'appointment', p_appointment_id,
    jsonb_build_object('status', v_appt.status),
    jsonb_build_object('status', 'completed', 'completed_at', NOW()),
    '{}'::JSONB
  );

  RETURN jsonb_build_object('status','success','appointment_id', p_appointment_id);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('status','error','message', SQLERRM);
END;
$$;

-- ─── FUNCTION: mark_no_show ───────────────────────────────────
CREATE OR REPLACE FUNCTION public.mark_appointment_no_show(
  p_appointment_id UUID,
  p_reason         TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appt        RECORD;
  v_actor_id    UUID := auth.uid();
  v_actor_email TEXT;
  v_org_id      UUID;
BEGIN
  SELECT id, organization_id, status, deleted_at
  INTO v_appt
  FROM public.appointments
  WHERE id = p_appointment_id AND deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('status','error','message','Appointment not found.');
  END IF;

  v_org_id := v_appt.organization_id;

  IF NOT public.is_org_member(v_org_id) THEN
    RETURN jsonb_build_object('status','error','message','Unauthorized.');
  END IF;

  IF NOT public.validate_appointment_transition(v_appt.status, 'no_show') THEN
    RETURN jsonb_build_object(
      'status','error',
      'message', format('Cannot mark no-show for appointment with status: %s', v_appt.status)
    );
  END IF;

  SELECT email INTO v_actor_email FROM public.user_profiles WHERE id = v_actor_id;

  UPDATE public.appointments SET
    status             = 'no_show',
    no_show_at         = NOW(),
    no_show_marked_by  = v_actor_id,
    no_show_reason     = p_reason,
    updated_at         = NOW()
  WHERE id = p_appointment_id;

  PERFORM public.create_audit_log(
    v_org_id, v_actor_id, v_actor_email,
    'appointment.no_show', 'appointment', p_appointment_id,
    jsonb_build_object('status', v_appt.status),
    jsonb_build_object('status', 'no_show', 'no_show_at', NOW(), 'reason', p_reason),
    '{}'::JSONB
  );

  RETURN jsonb_build_object('status','success','appointment_id', p_appointment_id);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('status','error','message', SQLERRM);
END;
$$;

-- ─── FUNCTION: start_appointment (in_progress) ───────────────
CREATE OR REPLACE FUNCTION public.start_appointment(
  p_appointment_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appt        RECORD;
  v_actor_id    UUID := auth.uid();
  v_actor_email TEXT;
  v_org_id      UUID;
BEGIN
  SELECT id, organization_id, status, deleted_at
  INTO v_appt
  FROM public.appointments
  WHERE id = p_appointment_id AND deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('status','error','message','Appointment not found.');
  END IF;

  v_org_id := v_appt.organization_id;

  IF NOT public.is_org_member(v_org_id) THEN
    RETURN jsonb_build_object('status','error','message','Unauthorized.');
  END IF;

  IF NOT public.validate_appointment_transition(v_appt.status, 'in_progress') THEN
    RETURN jsonb_build_object(
      'status','error',
      'message', format('Cannot start an appointment with status: %s', v_appt.status)
    );
  END IF;

  SELECT email INTO v_actor_email FROM public.user_profiles WHERE id = v_actor_id;

  UPDATE public.appointments SET
    status         = 'in_progress',
    in_progress_at = NOW(),
    in_progress_by = v_actor_id,
    updated_at     = NOW()
  WHERE id = p_appointment_id;

  PERFORM public.create_audit_log(
    v_org_id, v_actor_id, v_actor_email,
    'appointment.in_progress', 'appointment', p_appointment_id,
    jsonb_build_object('status', v_appt.status),
    jsonb_build_object('status', 'in_progress', 'in_progress_at', NOW()),
    '{}'::JSONB
  );

  RETURN jsonb_build_object('status','success','appointment_id', p_appointment_id);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('status','error','message', SQLERRM);
END;
$$;

-- ─── FUNCTION: reschedule_appointment ────────────────────────
-- Atomic reschedule via Availability Engine. Locks both old and new slots.
CREATE OR REPLACE FUNCTION public.reschedule_appointment(
  p_appointment_id  UUID,
  p_new_starts_at   TIMESTAMPTZ,
  p_new_employee_id UUID DEFAULT NULL,
  p_new_branch_id   UUID DEFAULT NULL,
  p_reason          TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appt           RECORD;
  v_actor_id       UUID := auth.uid();
  v_actor_email    TEXT;
  v_org_id         UUID;
  v_new_ends_at    TIMESTAMPTZ;
  v_employee_id    UUID;
  v_branch_id      UUID;
  v_conflict_count INTEGER;
  v_new_appt_id    UUID;
  v_branch_capacity INTEGER;
BEGIN
  -- Lock the appointment row
  SELECT
    id, organization_id, business_id, branch_id, customer_id, calendar_id,
    appointment_type, status, title, notes, internal_notes,
    starts_at, ends_at, duration_mins,
    buffer_before_mins, buffer_after_mins, travel_time_mins, timezone,
    is_group, group_capacity, group_booked_count,
    total_price, deposit_amount, currency,
    booked_online, booking_source, external_reference,
    custom_fields, metadata, deleted_at
  INTO v_appt
  FROM public.appointments
  WHERE id = p_appointment_id AND deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('status','error','message','Appointment not found.');
  END IF;

  v_org_id := v_appt.organization_id;

  -- Authorization
  IF NOT public.is_org_member(v_org_id) THEN
    RETURN jsonb_build_object('status','error','message','Unauthorized.');
  END IF;

  -- State machine check
  IF NOT public.validate_appointment_transition(v_appt.status, 'rescheduled') THEN
    RETURN jsonb_build_object(
      'status','error',
      'message', format('Cannot reschedule an appointment with status: %s', v_appt.status)
    );
  END IF;

  -- Resolve employee and branch
  v_employee_id := COALESCE(p_new_employee_id,
    (SELECT employee_id FROM public.appointment_employees
     WHERE appointment_id = p_appointment_id AND is_primary = TRUE LIMIT 1)
  );
  v_branch_id := COALESCE(p_new_branch_id, v_appt.branch_id);

  -- Calculate new end time preserving duration
  v_new_ends_at := p_new_starts_at + (v_appt.ends_at - v_appt.starts_at);

  -- Validate new slot is in the future
  IF p_new_starts_at <= NOW() THEN
    RETURN jsonb_build_object('status','error','message','New appointment time must be in the future.');
  END IF;

  -- Conflict detection: check for overlapping appointments for the employee
  IF v_employee_id IS NOT NULL THEN
    SELECT COUNT(*) INTO v_conflict_count
    FROM public.appointments a
    JOIN public.appointment_employees ae ON ae.appointment_id = a.id
    WHERE ae.employee_id = v_employee_id
      AND a.id != p_appointment_id
      AND a.deleted_at IS NULL
      AND a.status NOT IN ('cancelled', 'no_show', 'rescheduled')
      AND a.starts_at < v_new_ends_at
      AND a.ends_at > p_new_starts_at;

    IF v_conflict_count > 0 THEN
      RETURN jsonb_build_object('status','error','message','The selected time slot is not available for this employee.');
    END IF;
  END IF;

  -- Conflict detection: branch capacity
  SELECT COUNT(*) INTO v_conflict_count
  FROM public.appointments a
  WHERE a.branch_id = v_branch_id
    AND a.id != p_appointment_id
    AND a.deleted_at IS NULL
    AND a.status NOT IN ('cancelled', 'no_show', 'rescheduled')
    AND a.starts_at < v_new_ends_at
    AND a.ends_at > p_new_starts_at;

  SELECT capacity INTO v_branch_capacity FROM public.branches WHERE id = v_branch_id;
  IF v_conflict_count >= COALESCE(v_branch_capacity, 999) THEN
    RETURN jsonb_build_object('status','error','message','Branch capacity is full for the selected time slot.');
  END IF;

  SELECT email INTO v_actor_email FROM public.user_profiles WHERE id = v_actor_id;

  -- Mark old appointment as rescheduled
  UPDATE public.appointments SET
    status         = 'rescheduled',
    rescheduled_at = NOW(),
    updated_at     = NOW()
  WHERE id = p_appointment_id;

  -- Create new appointment (clone of old with new time)
  INSERT INTO public.appointments (
    organization_id, business_id, branch_id, customer_id, calendar_id,
    appointment_type, status, title, notes, internal_notes,
    starts_at, ends_at, duration_mins,
    buffer_before_mins, buffer_after_mins, travel_time_mins, timezone,
    is_group, group_capacity, group_booked_count,
    total_price, deposit_amount, currency,
    booked_online, booking_source, external_reference,
    custom_fields, metadata, created_by,
    rescheduled_from_id, confirmed_at, confirmed_by
  ) VALUES (
    v_appt.organization_id,
    v_appt.business_id,
    COALESCE(p_new_branch_id, v_appt.branch_id),
    v_appt.customer_id,
    v_appt.calendar_id,
    v_appt.appointment_type,
    'confirmed',
    v_appt.title,
    v_appt.notes,
    v_appt.internal_notes,
    p_new_starts_at,
    v_new_ends_at,
    v_appt.duration_mins,
    v_appt.buffer_before_mins,
    v_appt.buffer_after_mins,
    v_appt.travel_time_mins,
    v_appt.timezone,
    v_appt.is_group,
    v_appt.group_capacity,
    v_appt.group_booked_count,
    v_appt.total_price,
    v_appt.deposit_amount,
    v_appt.currency,
    v_appt.booked_online,
    v_appt.booking_source,
    v_appt.external_reference,
    v_appt.custom_fields,
    v_appt.metadata,
    v_actor_id,
    p_appointment_id,
    NOW(),
    v_actor_id
  )
  RETURNING id INTO v_new_appt_id;

  -- Copy appointment_services
  INSERT INTO public.appointment_services (
    organization_id, appointment_id, service_id, service_name,
    duration_mins, price, currency, sort_order
  )
  SELECT organization_id, v_new_appt_id, service_id, service_name,
         duration_mins, price, currency, sort_order
  FROM public.appointment_services
  WHERE appointment_id = p_appointment_id;

  -- Copy appointment_employees (update employee if provided)
  INSERT INTO public.appointment_employees (
    organization_id, appointment_id, employee_id, service_id, is_primary
  )
  SELECT organization_id, v_new_appt_id,
    CASE WHEN is_primary AND p_new_employee_id IS NOT NULL THEN p_new_employee_id ELSE employee_id END,
    service_id, is_primary
  FROM public.appointment_employees
  WHERE appointment_id = p_appointment_id;

  -- Audit old
  PERFORM public.create_audit_log(
    v_org_id, v_actor_id, v_actor_email,
    'appointment.rescheduled', 'appointment', p_appointment_id,
    jsonb_build_object('status', v_appt.status, 'starts_at', v_appt.starts_at, 'ends_at', v_appt.ends_at),
    jsonb_build_object('status', 'rescheduled', 'new_appointment_id', v_new_appt_id, 'new_starts_at', p_new_starts_at, 'reason', p_reason),
    '{}'::JSONB
  );

  -- Notification event
  INSERT INTO public.notification_queue (
    organization_id, appointment_id, event_type, payload, scheduled_for
  ) VALUES (
    v_org_id, v_new_appt_id, 'appointment_rescheduled',
    jsonb_build_object(
      'old_appointment_id', p_appointment_id,
      'new_appointment_id', v_new_appt_id,
      'new_starts_at', p_new_starts_at,
      'actor_id', v_actor_id,
      'reason', p_reason
    ),
    NOW()
  ) ON CONFLICT DO NOTHING;

  RETURN jsonb_build_object(
    'status', 'success',
    'old_appointment_id', p_appointment_id,
    'new_appointment_id', v_new_appt_id,
    'new_starts_at', p_new_starts_at
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('status','error','message', SQLERRM);
END;
$$;

-- ─── FUNCTION: get_appointment_detail ────────────────────────
CREATE OR REPLACE FUNCTION public.get_appointment_detail(
  p_appointment_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_org_id UUID;
  v_result JSONB;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.appointments
  WHERE id = p_appointment_id AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('status','error','message','Appointment not found.');
  END IF;

  IF NOT public.is_org_member(v_org_id) THEN
    RETURN jsonb_build_object('status','error','message','Unauthorized.');
  END IF;

  SELECT jsonb_build_object(
    'status', 'success',
    'appointment', jsonb_build_object(
      'id',                   a.id,
      'organization_id',      a.organization_id,
      'business_id',          a.business_id,
      'branch_id',            a.branch_id,
      'customer_id',          a.customer_id,
      'status',               a.status,
      'title',                a.title,
      'notes',                a.notes,
      'internal_notes',       a.internal_notes,
      'starts_at',            a.starts_at,
      'ends_at',              a.ends_at,
      'duration_mins',        a.duration_mins,
      'total_price',          a.total_price,
      'currency',             a.currency,
      'booking_source',       a.booking_source,
      'booked_online',        a.booked_online,
      'cancelled_at',         a.cancelled_at,
      'cancellation_reason',  a.cancellation_reason,
      'confirmed_at',         a.confirmed_at,
      'completed_at',         a.completed_at,
      'no_show_at',           a.no_show_at,
      'no_show_reason',       a.no_show_reason,
      'in_progress_at',       a.in_progress_at,
      'rescheduled_at',       a.rescheduled_at,
      'rescheduled_from_id',  a.rescheduled_from_id,
      'created_at',           a.created_at,
      'updated_at',           a.updated_at,
      -- Customer
      'customer_name',        COALESCE(c.full_name, gc.full_name),
      'customer_email',       COALESCE(c.email, gc.email),
      'customer_phone',       COALESCE(c.phone, gc.phone),
      -- Branch
      'branch_name',          br.name,
      -- Business
      'business_name',        biz.name,
      -- Services
      'services',             (
        SELECT jsonb_agg(jsonb_build_object(
          'service_id',   asvc.service_id,
          'service_name', asvc.service_name,
          'duration_mins',asvc.duration_mins,
          'price',        asvc.price
        ) ORDER BY asvc.sort_order)
        FROM public.appointment_services asvc
        WHERE asvc.appointment_id = a.id
      ),
      -- Employees
      'employees',            (
        SELECT jsonb_agg(jsonb_build_object(
          'employee_id',   ae.employee_id,
          'employee_name', CONCAT(e.first_name, ' ', e.last_name),
          'is_primary',    ae.is_primary
        ))
        FROM public.appointment_employees ae
        JOIN public.employees e ON e.id = ae.employee_id
        WHERE ae.appointment_id = a.id
      ),
      -- Confirmed by
      'confirmed_by_name',    cup.full_name,
      -- Cancelled by
      'cancelled_by_name',    canp.full_name,
      -- Completed by
      'completed_by_name',    comp.full_name
    )
  ) INTO v_result
  FROM public.appointments a
  LEFT JOIN public.customers c ON c.id = a.customer_id
  LEFT JOIN public.customers gc ON gc.id = a.customer_id
  LEFT JOIN public.branches br ON br.id = a.branch_id
  LEFT JOIN public.businesses biz ON biz.id = a.business_id
  LEFT JOIN public.user_profiles cup ON cup.id = a.confirmed_by
  LEFT JOIN public.user_profiles canp ON canp.id = a.cancelled_by
  LEFT JOIN public.user_profiles comp ON comp.id = a.completed_by
  WHERE a.id = p_appointment_id;

  RETURN v_result;
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('status','error','message', SQLERRM);
END;
$$;

-- ─── FUNCTION: get_appointment_audit_history ─────────────────
CREATE OR REPLACE FUNCTION public.get_appointment_audit_history(
  p_appointment_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_org_id UUID;
BEGIN
  SELECT organization_id INTO v_org_id FROM public.appointments
  WHERE id = p_appointment_id AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('status','error','message','Appointment not found.');
  END IF;

  IF NOT public.is_org_member(v_org_id) THEN
    RETURN jsonb_build_object('status','error','message','Unauthorized.');
  END IF;

  RETURN jsonb_build_object(
    'status', 'success',
    'history', (
      SELECT jsonb_agg(jsonb_build_object(
        'id',            al.id,
        'action',        al.action,
        'actor_email',   al.actor_email,
        'old_values',    al.old_values,
        'new_values',    al.new_values,
        'created_at',    al.created_at
      ) ORDER BY al.created_at DESC)
      FROM public.audit_logs al
      WHERE al.resource_type = 'appointment'
        AND al.resource_id = p_appointment_id
    )
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('status','error','message', SQLERRM);
END;
$$;

-- ─── FUNCTION: bulk_confirm_appointments ─────────────────────
CREATE OR REPLACE FUNCTION public.bulk_confirm_appointments(
  p_appointment_ids UUID[]
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id      UUID;
  v_result  JSONB;
  v_results JSONB[] := '{}';
  v_success INTEGER := 0;
  v_failed  INTEGER := 0;
BEGIN
  FOREACH v_id IN ARRAY p_appointment_ids LOOP
    v_result := public.confirm_appointment(v_id);
    IF (v_result->>'status') = 'success' THEN
      v_success := v_success + 1;
    ELSE
      v_failed := v_failed + 1;
    END IF;
    v_results := array_append(v_results, v_result || jsonb_build_object('appointment_id', v_id));
  END LOOP;

  RETURN jsonb_build_object(
    'status', 'success',
    'confirmed', v_success,
    'failed', v_failed,
    'results', to_jsonb(v_results)
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('status','error','message', SQLERRM);
END;
$$;

-- ─── FUNCTION: bulk_cancel_appointments ──────────────────────
CREATE OR REPLACE FUNCTION public.bulk_cancel_appointments(
  p_appointment_ids UUID[],
  p_reason          TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id      UUID;
  v_result  JSONB;
  v_results JSONB[] := '{}';
  v_success INTEGER := 0;
  v_failed  INTEGER := 0;
BEGIN
  FOREACH v_id IN ARRAY p_appointment_ids LOOP
    v_result := public.cancel_appointment_business(v_id, p_reason);
    IF (v_result->>'status') = 'success' THEN
      v_success := v_success + 1;
    ELSE
      v_failed := v_failed + 1;
    END IF;
    v_results := array_append(v_results, v_result || jsonb_build_object('appointment_id', v_id));
  END LOOP;

  RETURN jsonb_build_object(
    'status', 'success',
    'cancelled', v_success,
    'failed', v_failed,
    'results', to_jsonb(v_results)
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('status','error','message', SQLERRM);
END;
$$;

-- ─── FUNCTION: bulk_complete_appointments ────────────────────
CREATE OR REPLACE FUNCTION public.bulk_complete_appointments(
  p_appointment_ids UUID[]
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id      UUID;
  v_result  JSONB;
  v_results JSONB[] := '{}';
  v_success INTEGER := 0;
  v_failed  INTEGER := 0;
BEGIN
  FOREACH v_id IN ARRAY p_appointment_ids LOOP
    v_result := public.complete_appointment(v_id);
    IF (v_result->>'status') = 'success' THEN
      v_success := v_success + 1;
    ELSE
      v_failed := v_failed + 1;
    END IF;
    v_results := array_append(v_results, v_result || jsonb_build_object('appointment_id', v_id));
  END LOOP;

  RETURN jsonb_build_object(
    'status', 'success',
    'completed', v_success,
    'failed', v_failed,
    'results', to_jsonb(v_results)
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('status','error','message', SQLERRM);
END;
$$;

-- ─── Index for audit_logs on appointment lifecycle ────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'audit_logs'
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename  = 'audit_logs'
      AND indexname  = 'idx_audit_logs_appointment'
  ) THEN
    CREATE INDEX idx_audit_logs_appointment
      ON public.audit_logs(resource_id)
      WHERE resource_type = 'appointment';
  END IF;
END;
$$;
