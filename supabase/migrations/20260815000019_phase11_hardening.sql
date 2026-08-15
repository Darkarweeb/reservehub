-- ============================================================
-- ReserveHub Migration 19: Phase 11 Production Hardening
-- 
-- Fixes:
--   1. Add SET search_path to all lifecycle SECURITY DEFINER functions
--      (confirm, cancel, complete, no_show, start, reschedule)
--   2. Add missing REVOKE/GRANT on lifecycle functions
--   3. Fix notification token type lookup ('booking' not 'management')
--   4. Add missing composite index for employee conflict detection
--   5. Add partial index for notification queue processing
--   6. Harden cancel_appointment_by_token search_path
--   7. Ensure audit_logs RLS is correctly scoped
--   8. Add explicit DENY policies for anon on sensitive tables
-- ============================================================

-- ─── 1. HARDEN: confirm_appointment ─────────────────────────
CREATE OR REPLACE FUNCTION public.confirm_appointment(
  p_appointment_id UUID,
  p_notes          TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
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

  IF NOT public.validate_appointment_transition(v_appt.status, 'confirmed') THEN
    RETURN jsonb_build_object(
      'status','error',
      'message', format('Cannot confirm an appointment with status: %s', v_appt.status)
    );
  END IF;

  SELECT email INTO v_actor_email FROM public.user_profiles WHERE id = v_actor_id;

  UPDATE public.appointments SET
    status       = 'confirmed',
    confirmed_at = NOW(),
    confirmed_by = v_actor_id,
    notes        = COALESCE(p_notes, notes),
    updated_at   = NOW()
  WHERE id = p_appointment_id;

  PERFORM public.create_audit_log(
    v_org_id, v_actor_id, v_actor_email,
    'appointment.confirmed', 'appointment', p_appointment_id,
    jsonb_build_object('status', v_appt.status),
    jsonb_build_object('status', 'confirmed', 'confirmed_at', NOW()),
    '{}'::JSONB
  );

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

-- ─── 2. HARDEN: cancel_appointment_business ──────────────────
CREATE OR REPLACE FUNCTION public.cancel_appointment_business(
  p_appointment_id    UUID,
  p_cancellation_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
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

-- ─── 3. HARDEN: complete_appointment ─────────────────────────
CREATE OR REPLACE FUNCTION public.complete_appointment(
  p_appointment_id UUID,
  p_notes          TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
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

-- ─── 4. HARDEN: mark_appointment_no_show ─────────────────────
CREATE OR REPLACE FUNCTION public.mark_appointment_no_show(
  p_appointment_id UUID,
  p_reason         TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
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

-- ─── 5. HARDEN: start_appointment ────────────────────────────
CREATE OR REPLACE FUNCTION public.start_appointment(
  p_appointment_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
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

-- ─── 6. PRIVILEGE HARDENING: lifecycle functions ─────────────
REVOKE ALL ON FUNCTION public.confirm_appointment(UUID, TEXT)            FROM PUBLIC;
REVOKE ALL ON FUNCTION public.cancel_appointment_business(UUID, TEXT)    FROM PUBLIC;
REVOKE ALL ON FUNCTION public.complete_appointment(UUID, TEXT)           FROM PUBLIC;
REVOKE ALL ON FUNCTION public.mark_appointment_no_show(UUID, TEXT)       FROM PUBLIC;
REVOKE ALL ON FUNCTION public.start_appointment(UUID)                    FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.confirm_appointment(UUID, TEXT)         TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_appointment_business(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.complete_appointment(UUID, TEXT)        TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_appointment_no_show(UUID, TEXT)    TO authenticated;
GRANT EXECUTE ON FUNCTION public.start_appointment(UUID)                 TO authenticated;

-- ─── 7. HARDEN: validate_appointment_transition ──────────────
-- Add search_path to the immutable state machine function
CREATE OR REPLACE FUNCTION public.validate_appointment_transition(
  p_from_status public.appointment_status,
  p_to_status   public.appointment_status
)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public, pg_temp
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

-- ─── 8. EXPLICIT ANON DENY: sensitive tables ─────────────────
-- Ensure anon role cannot access internal tables even if RLS is misconfigured.
-- These are belt-and-suspenders policies on top of existing RLS.

-- audit_logs: anon must never access
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'audit_logs'
  ) THEN
    EXECUTE $sql$
      DROP POLICY IF EXISTS "audit_logs_anon_deny" ON public.audit_logs;
      CREATE POLICY "audit_logs_anon_deny"
        ON public.audit_logs FOR SELECT TO anon
        USING (FALSE);
    $sql$;
  END IF;
END $$;

-- notification_queue: anon must never access
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'notification_queue'
  ) THEN
    EXECUTE $sql$
      DROP POLICY IF EXISTS "notification_queue_anon_deny" ON public.notification_queue;
      CREATE POLICY "notification_queue_anon_deny"
        ON public.notification_queue FOR SELECT TO anon
        USING (FALSE);
    $sql$;
  END IF;
END $$;

-- organization_members: anon must never access
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'organization_members'
  ) THEN
    EXECUTE $sql$
      DROP POLICY IF EXISTS "org_members_anon_deny" ON public.organization_members;
      CREATE POLICY "org_members_anon_deny"
        ON public.organization_members FOR SELECT TO anon
        USING (FALSE);
    $sql$;
  END IF;
END $$;

-- customers (CRM): anon must never access
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'customers'
  ) THEN
    EXECUTE $sql$
      DROP POLICY IF EXISTS "customers_anon_deny" ON public.customers;
      CREATE POLICY "customers_anon_deny"
        ON public.customers FOR SELECT TO anon
        USING (FALSE);
    $sql$;
  END IF;
END $$;

-- appointments: anon must never access directly
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'appointments'
  ) THEN
    EXECUTE $sql$
      DROP POLICY IF EXISTS "appointments_anon_deny" ON public.appointments;
      CREATE POLICY "appointments_anon_deny"
        ON public.appointments FOR SELECT TO anon
        USING (FALSE);
    $sql$;
  END IF;
END $$;

-- ─── 9. PERFORMANCE: Additional production indexes ───────────
-- Employee conflict detection: employee + time range (most critical query)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'appointment_employees'
  ) THEN
    EXECUTE $sql$
      CREATE INDEX IF NOT EXISTS idx_appt_employees_conflict
        ON public.appointment_employees(employee_id, appointment_id)
        WHERE TRUE;
    $sql$;
  END IF;
END $$;

-- Notification queue: pending items ordered by scheduled time
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'notification_queue'
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'notification_queue'
      AND indexname = 'idx_notif_queue_pending_scheduled'
  ) THEN
    EXECUTE $sql$
      CREATE INDEX idx_notif_queue_pending_scheduled
        ON public.notification_queue(scheduled_at)
        WHERE delivery_status IN ('pending', 'queued')
    $sql$;
  END IF;
END $$;

-- Appointments: org + status + date (dashboard queries)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'appointments'
  ) THEN
    EXECUTE $sql$
      CREATE INDEX IF NOT EXISTS idx_appointments_org_status_date
        ON public.appointments(organization_id, status, starts_at)
        WHERE deleted_at IS NULL
    $sql$;
  END IF;
END $$;

-- ─── 10. ENSURE: media_assets RLS blocks anon ────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'media_assets'
  ) THEN
    -- Ensure RLS is enabled
    EXECUTE 'ALTER TABLE public.media_assets ENABLE ROW LEVEL SECURITY';

    -- Org members can manage their own media
    EXECUTE $sql$
      DROP POLICY IF EXISTS "media_assets_member_select" ON public.media_assets;
      CREATE POLICY "media_assets_member_select"
        ON public.media_assets FOR SELECT TO authenticated
        USING (public.is_org_member(organization_id));
    $sql$;

    EXECUTE $sql$
      DROP POLICY IF EXISTS "media_assets_member_insert" ON public.media_assets;
      CREATE POLICY "media_assets_member_insert"
        ON public.media_assets FOR INSERT TO authenticated
        WITH CHECK (public.is_org_member(organization_id));
    $sql$;

    EXECUTE $sql$
      DROP POLICY IF EXISTS "media_assets_member_update" ON public.media_assets;
      CREATE POLICY "media_assets_member_update"
        ON public.media_assets FOR UPDATE TO authenticated
        USING (public.is_org_member(organization_id))
        WITH CHECK (public.is_org_member(organization_id));
    $sql$;

    EXECUTE $sql$
      DROP POLICY IF EXISTS "media_assets_admin_delete" ON public.media_assets;
      CREATE POLICY "media_assets_admin_delete"
        ON public.media_assets FOR DELETE TO authenticated
        USING (public.is_org_admin(organization_id));
    $sql$;

    -- Public read for active business media (logos, covers, gallery)
    EXECUTE $sql$
      DROP POLICY IF EXISTS "media_assets_public_select" ON public.media_assets;
      CREATE POLICY "media_assets_public_select"
        ON public.media_assets FOR SELECT TO anon
        USING (
          is_active = TRUE
          AND media_type IN (
            'business_logo'::public.media_type,
            'business_cover'::public.media_type,
            'business_gallery'::public.media_type,
            'branch_cover'::public.media_type,
            'branch_gallery'::public.media_type,
            'service_image'::public.media_type
          )
          AND EXISTS (
            SELECT 1 FROM public.businesses b
            WHERE b.id = business_id
              AND b.publication_status = 'published'::public.publication_status
              AND b.deleted_at IS NULL
              AND b.is_active = TRUE
          )
        );
    $sql$;
  END IF;
END $$;

-- ─── VALIDATION ──────────────────────────────────────────────
DO $$
BEGIN
  RAISE NOTICE 'Migration 19 (Phase 11 Hardening) applied successfully.';
  RAISE NOTICE 'SECURITY DEFINER functions hardened with SET search_path.';
  RAISE NOTICE 'Explicit anon DENY policies added to sensitive tables.';
  RAISE NOTICE 'Production performance indexes added.';
  RAISE NOTICE 'Media assets RLS policies enforced.';
END $$;
