-- ============================================================
-- ReserveHub Migration 14: Availability Engine Foundation
-- 
-- Creates:
--   1. admin_time_blocks table (administrative unavailable periods)
--   2. check_slot_available() — shared internal scheduling function
--      (single source of truth for all availability logic)
--   3. create_manual_appointment() — authenticated business RPC
--   4. create_time_block() / update_time_block() / delete_time_block() — block management RPCs
--   5. get_business_appointments() — authenticated calendar data RPC
--   6. get_calendar_month_summary() — month dot-indicator data
--
-- Architecture:
--   • check_slot_available() is the SINGLE scheduling algorithm.
--   • get_public_availability() (migration 10) and create_manual_appointment()
--     both delegate conflict detection to check_slot_available().
--   • admin_time_blocks are excluded from public availability.
--   • All authenticated RPCs derive org/business scope server-side.
--   • Anonymous users have ZERO access to admin_time_blocks.
-- ============================================================

-- ─── TABLE: admin_time_blocks ─────────────────────────────────
-- Represents administrative unavailable periods that block scheduling.
-- Examples: meetings, lunch, maintenance, private events, closures.
-- Foreign key constraints are added separately (after table creation)
-- to avoid parse-time "relation does not exist" errors when migrations
-- are applied incrementally.
CREATE TABLE IF NOT EXISTS public.admin_time_blocks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL,
  business_id     UUID NOT NULL,
  branch_id       UUID,
  employee_id     UUID,
  title           TEXT NOT NULL,
  reason          TEXT,
  block_date      DATE NOT NULL,
  start_time      TIME WITHOUT TIME ZONE NOT NULL,
  end_time        TIME WITHOUT TIME ZONE NOT NULL,
  is_all_day      BOOLEAN NOT NULL DEFAULT FALSE,
  created_by      UUID,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ,

  CONSTRAINT admin_time_blocks_time_valid CHECK (start_time < end_time)
);

-- ─── FOREIGN KEYS: admin_time_blocks ─────────────────────────
-- Added separately so each constraint is idempotent and does not
-- cause a parse-time failure if a referenced table is not yet visible.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'organizations'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'admin_time_blocks_organization_id_fkey'
      AND table_schema = 'public'
  ) THEN
    ALTER TABLE public.admin_time_blocks
      ADD CONSTRAINT admin_time_blocks_organization_id_fkey
      FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'businesses'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'admin_time_blocks_business_id_fkey'
      AND table_schema = 'public'
  ) THEN
    ALTER TABLE public.admin_time_blocks
      ADD CONSTRAINT admin_time_blocks_business_id_fkey
      FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'branches'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'admin_time_blocks_branch_id_fkey'
      AND table_schema = 'public'
  ) THEN
    ALTER TABLE public.admin_time_blocks
      ADD CONSTRAINT admin_time_blocks_branch_id_fkey
      FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'employees'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'admin_time_blocks_employee_id_fkey'
      AND table_schema = 'public'
  ) THEN
    ALTER TABLE public.admin_time_blocks
      ADD CONSTRAINT admin_time_blocks_employee_id_fkey
      FOREIGN KEY (employee_id) REFERENCES public.employees(id) ON DELETE CASCADE;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'user_profiles'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'admin_time_blocks_created_by_fkey'
      AND table_schema = 'public'
  ) THEN
    ALTER TABLE public.admin_time_blocks
      ADD CONSTRAINT admin_time_blocks_created_by_fkey
      FOREIGN KEY (created_by) REFERENCES public.user_profiles(id) ON DELETE SET NULL;
  END IF;
END;
$$;

-- ─── TRIGGER: updated_at ─────────────────────────────────────
DROP TRIGGER IF EXISTS trg_admin_time_blocks_updated_at ON public.admin_time_blocks;
CREATE TRIGGER trg_admin_time_blocks_updated_at
  BEFORE UPDATE ON public.admin_time_blocks
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ─── INDEXES ─────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_admin_blocks_org_id ON public.admin_time_blocks(organization_id);
CREATE INDEX IF NOT EXISTS idx_admin_blocks_business_id ON public.admin_time_blocks(business_id);
CREATE INDEX IF NOT EXISTS idx_admin_blocks_branch_id ON public.admin_time_blocks(branch_id);
CREATE INDEX IF NOT EXISTS idx_admin_blocks_employee_id ON public.admin_time_blocks(employee_id);
CREATE INDEX IF NOT EXISTS idx_admin_blocks_date ON public.admin_time_blocks(business_id, block_date);
CREATE INDEX IF NOT EXISTS idx_admin_blocks_deleted_at ON public.admin_time_blocks(deleted_at) WHERE deleted_at IS NULL;

-- ─── ENABLE RLS ──────────────────────────────────────────────
ALTER TABLE public.admin_time_blocks ENABLE ROW LEVEL SECURITY;

-- ─── RLS: admin_time_blocks ──────────────────────────────────
-- Only authenticated org members may read; only admins may write.
-- Anonymous users have ZERO access.
DROP POLICY IF EXISTS "admin_blocks_member_select" ON public.admin_time_blocks;
CREATE POLICY "admin_blocks_member_select"
  ON public.admin_time_blocks FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "admin_blocks_admin_insert" ON public.admin_time_blocks;
CREATE POLICY "admin_blocks_admin_insert"
  ON public.admin_time_blocks FOR INSERT TO authenticated
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "admin_blocks_admin_update" ON public.admin_time_blocks;
CREATE POLICY "admin_blocks_admin_update"
  ON public.admin_time_blocks FOR UPDATE TO authenticated
  USING (public.is_org_admin(organization_id))
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "admin_blocks_admin_delete" ON public.admin_time_blocks;
CREATE POLICY "admin_blocks_admin_delete"
  ON public.admin_time_blocks FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- ============================================================
-- SHARED INTERNAL SCHEDULING FUNCTION
-- check_slot_available() is the SINGLE SOURCE OF TRUTH.
-- Called by both get_public_availability() and create_manual_appointment().
-- Returns TRUE if the slot is bookable, FALSE otherwise.
-- ============================================================

CREATE OR REPLACE FUNCTION public.check_slot_available(
  p_business_id   UUID,
  p_branch_id     UUID,
  p_employee_id   UUID,
  p_service_id    UUID,
  p_starts_at     TIMESTAMPTZ,
  p_ends_at       TIMESTAMPTZ,
  p_buffer_before INTEGER DEFAULT 0,
  p_buffer_after  INTEGER DEFAULT 0,
  p_exclude_id    UUID    DEFAULT NULL  -- exclude an existing appointment (for rescheduling)
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_day_of_week TEXT;
  v_start_time  TIME;
  v_end_time    TIME;
  v_branch_tz   TEXT;
BEGIN
  -- Resolve branch timezone
  SELECT timezone INTO v_branch_tz
  FROM public.branches
  WHERE id = p_branch_id AND deleted_at IS NULL
  LIMIT 1;

  IF v_branch_tz IS NULL THEN
    v_branch_tz := 'UTC';
  END IF;

  v_day_of_week := trim(lower(to_char(p_starts_at AT TIME ZONE v_branch_tz, 'Day')));
  v_start_time  := (p_starts_at AT TIME ZONE v_branch_tz)::TIME;
  v_end_time    := (p_ends_at   AT TIME ZONE v_branch_tz)::TIME;

  -- ── 1. Business hours check ──────────────────────────────
  IF NOT EXISTS (
    SELECT 1 FROM public.business_hours bh
    WHERE bh.business_id = p_business_id
      AND bh.day_of_week = v_day_of_week::public.day_of_week
      AND bh.is_open     = TRUE
      AND v_start_time   >= bh.open_time
      AND v_end_time     <= bh.close_time
      AND (bh.branch_id = p_branch_id OR bh.branch_id IS NULL)
    ORDER BY bh.branch_id NULLS LAST
    LIMIT 1
  ) THEN
    RETURN FALSE;
  END IF;

  -- ── 2. Employee working hours check ─────────────────────
  IF NOT EXISTS (
    SELECT 1 FROM public.working_hours wh
    WHERE wh.employee_id = p_employee_id
      AND wh.day_of_week = v_day_of_week::public.day_of_week
      AND wh.is_working  = TRUE
      AND v_start_time   >= wh.start_time
      AND v_end_time     <= wh.end_time
  ) THEN
    RETURN FALSE;
  END IF;

  -- ── 3. Employee availability / time-off / holidays ──────
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
      AND ea.start_at < p_ends_at
      AND ea.end_at   > p_starts_at
  ) THEN
    RETURN FALSE;
  END IF;

  -- ── 4. Employee breaks ───────────────────────────────────
  IF EXISTS (
    SELECT 1 FROM public.breaks b
    WHERE b.employee_id = p_employee_id
      AND b.is_active   = TRUE
      AND (b.day_of_week IS NULL OR b.day_of_week = v_day_of_week::public.day_of_week)
      AND b.start_time  < v_end_time
      AND b.end_time    > v_start_time
  ) THEN
    RETURN FALSE;
  END IF;

  -- ── 5. Existing appointment conflicts (with buffers) ────
  IF EXISTS (
    SELECT 1
    FROM public.appointments a
      JOIN public.appointment_employees ae ON ae.appointment_id = a.id
    WHERE ae.employee_id = p_employee_id
      AND a.deleted_at   IS NULL
      AND (p_exclude_id IS NULL OR a.id <> p_exclude_id)
      AND a.status NOT IN (
        'cancelled'::public.appointment_status,
        'no_show'::public.appointment_status
      )
      AND (a.starts_at - (a.buffer_before_mins || ' minutes')::INTERVAL)
          < (p_ends_at + (p_buffer_after || ' minutes')::INTERVAL)
      AND (a.ends_at   + (a.buffer_after_mins  || ' minutes')::INTERVAL)
          > (p_starts_at - (p_buffer_before || ' minutes')::INTERVAL)
  ) THEN
    RETURN FALSE;
  END IF;

  -- ── 6. Administrative time blocks ───────────────────────
  IF EXISTS (
    SELECT 1 FROM public.admin_time_blocks atb
    WHERE atb.business_id = p_business_id
      AND atb.deleted_at  IS NULL
      AND (atb.branch_id IS NULL OR atb.branch_id = p_branch_id)
      AND (atb.employee_id IS NULL OR atb.employee_id = p_employee_id)
      AND atb.block_date  = (p_starts_at AT TIME ZONE v_branch_tz)::DATE
      AND atb.start_time  < v_end_time
      AND atb.end_time    > v_start_time
  ) THEN
    RETURN FALSE;
  END IF;

  -- ── 7. Employee cannot perform service ──────────────────
  IF p_service_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.employee_services es
      WHERE es.employee_id = p_employee_id
        AND es.service_id  = p_service_id
        AND es.is_active   = TRUE
    ) THEN
      RETURN FALSE;
    END IF;
  END IF;

  RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.check_slot_available(UUID, UUID, UUID, UUID, TIMESTAMPTZ, TIMESTAMPTZ, INTEGER, INTEGER, UUID) FROM PUBLIC;
-- Internal use only — not exposed to anon or authenticated directly

-- ============================================================
-- AUTHENTICATED RPC: create_manual_appointment
-- Business users create appointments manually (phone, walk-in, etc.)
-- Uses the SAME check_slot_available() as public booking.
-- Derives org/business scope from authenticated user's membership.
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_manual_appointment(
  p_branch_id     UUID,
  p_service_id    UUID,
  p_employee_id   UUID,
  p_starts_at     TIMESTAMPTZ,
  p_customer_name TEXT,
  p_customer_id   UUID    DEFAULT NULL,
  p_notes         TEXT    DEFAULT NULL,
  p_internal_notes TEXT   DEFAULT NULL,
  p_booking_source TEXT   DEFAULT 'manual'
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id       UUID;
  v_org_id        UUID;
  v_business_id   UUID;
  v_branch        RECORD;
  v_service       RECORD;
  v_employee      RECORD;
  v_duration_mins INTEGER;
  v_buffer_before INTEGER;
  v_buffer_after  INTEGER;
  v_ends_at       TIMESTAMPTZ;
  v_appointment_id UUID;
  v_lock_key      BIGINT;
BEGIN
  -- ── 1. Identify caller ────────────────────────────────────
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Authentication required.');
  END IF;

  -- ── 2. Derive org from authenticated user (never trust client) ──
  SELECT om.organization_id INTO v_org_id
  FROM public.organization_members om
  WHERE om.user_id    = v_user_id
    AND om.is_active  = TRUE
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'User is not a member of any organization.');
  END IF;

  -- ── 3. Validate branch belongs to this org ───────────────
  SELECT b.id, b.business_id, b.organization_id, b.timezone, b.is_active, b.deleted_at
  INTO v_branch
  FROM public.branches b
  WHERE b.id              = p_branch_id
    AND b.organization_id = v_org_id
    AND b.is_active       = TRUE
    AND b.deleted_at      IS NULL
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Branch not found or not accessible.');
  END IF;

  v_business_id := v_branch.business_id;

  -- ── 4. Validate service belongs to this business ─────────
  SELECT s.id, s.duration_mins, s.buffer_before_mins, s.buffer_after_mins,
         s.status, s.price, s.currency, s.max_capacity, s.deleted_at
  INTO v_service
  FROM public.services s
  WHERE s.id          = p_service_id
    AND s.business_id = v_business_id
    AND s.status      = 'active'::public.service_status
    AND s.deleted_at  IS NULL
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Service not found or inactive.');
  END IF;

  -- ── 5. Validate employee belongs to this business ────────
  SELECT e.id, e.status, e.is_bookable, e.deleted_at
  INTO v_employee
  FROM public.employees e
  WHERE e.id          = p_employee_id
    AND e.business_id = v_business_id
    AND e.status      = 'active'::public.employee_status
    AND e.is_bookable = TRUE
    AND e.deleted_at  IS NULL
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Employee not found or inactive.');
  END IF;

  -- ── 6. Validate employee can perform the service ─────────
  IF NOT EXISTS (
    SELECT 1 FROM public.employee_services es
    WHERE es.employee_id = p_employee_id
      AND es.service_id  = p_service_id
      AND es.is_active   = TRUE
  ) THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Employee cannot perform this service.');
  END IF;

  -- ── 7. Compute timing ────────────────────────────────────
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

  -- ── 8. Acquire advisory lock (race condition protection) ─
  v_lock_key := ('x' || substr(p_employee_id::TEXT, 1, 8))::BIT(32)::BIGINT;
  IF NOT pg_try_advisory_xact_lock(v_lock_key) THEN
    RETURN jsonb_build_object('status', 'error_double_booking', 'message', 'Slot is being booked. Please try again.');
  END IF;

  -- ── 9. Check availability via shared engine ───────────────
  IF NOT public.check_slot_available(
    v_business_id,
    p_branch_id,
    p_employee_id,
    p_service_id,
    p_starts_at,
    v_ends_at,
    v_buffer_before,
    v_buffer_after,
    NULL
  ) THEN
    RETURN jsonb_build_object('status', 'error_slot_unavailable', 'message', 'The selected time slot is not available.');
  END IF;

  -- ── 10. Create appointment (atomic) ──────────────────────
  INSERT INTO public.appointments (
    organization_id,
    business_id,
    branch_id,
    customer_id,
    appointment_type,
    status,
    title,
    notes,
    internal_notes,
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
    created_by,
    metadata
  ) VALUES (
    v_org_id,
    v_business_id,
    p_branch_id,
    p_customer_id,
    'single'::public.appointment_type,
    'confirmed'::public.appointment_status,
    (SELECT name FROM public.services WHERE id = p_service_id) || ' - ' || p_customer_name,
    p_notes,
    p_internal_notes,
    p_starts_at,
    v_ends_at,
    v_duration_mins,
    v_buffer_before,
    v_buffer_after,
    v_branch.timezone,
    COALESCE(
      (SELECT price_override FROM public.employee_services
       WHERE employee_id = p_employee_id AND service_id = p_service_id LIMIT 1),
      v_service.price
    ),
    v_service.currency,
    FALSE,
    p_booking_source,
    v_user_id,
    jsonb_build_object('manual_booking', TRUE, 'created_by_user', v_user_id)
  )
  RETURNING id INTO v_appointment_id;

  -- ── 11. Link appointment ↔ service ────────────────────────
  INSERT INTO public.appointment_services (
    organization_id, appointment_id, service_id, service_name,
    duration_mins, price, currency
  )
  SELECT
    v_org_id,
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

  -- ── 12. Link appointment ↔ employee ───────────────────────
  INSERT INTO public.appointment_employees (
    organization_id, appointment_id, employee_id, service_id, is_primary
  ) VALUES (
    v_org_id, v_appointment_id, p_employee_id, p_service_id, TRUE
  );

  RETURN jsonb_build_object(
    'status',         'success',
    'appointment_id', v_appointment_id,
    'starts_at',      p_starts_at,
    'ends_at',        v_ends_at,
    'duration_mins',  v_duration_mins
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('status', 'error_internal', 'message', SQLERRM);
END;
$$;

REVOKE ALL ON FUNCTION public.create_manual_appointment(UUID, UUID, UUID, TIMESTAMPTZ, TEXT, UUID, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_manual_appointment(UUID, UUID, UUID, TIMESTAMPTZ, TEXT, UUID, TEXT, TEXT, TEXT) TO authenticated;

-- ============================================================
-- AUTHENTICATED RPC: create_time_block
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_time_block(
  p_branch_id   UUID,
  p_title       TEXT,
  p_block_date  DATE,
  p_start_time  TIME WITHOUT TIME ZONE,
  p_end_time    TIME WITHOUT TIME ZONE,
  p_employee_id UUID    DEFAULT NULL,
  p_reason      TEXT    DEFAULT NULL,
  p_is_all_day  BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id     UUID;
  v_org_id      UUID;
  v_business_id UUID;
  v_block_id    UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Authentication required.');
  END IF;

  -- Derive org from authenticated user
  SELECT om.organization_id INTO v_org_id
  FROM public.organization_members om
  WHERE om.user_id   = v_user_id
    AND om.is_active = TRUE
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'User is not a member of any organization.');
  END IF;

  -- Validate branch belongs to this org
  SELECT b.business_id INTO v_business_id
  FROM public.branches b
  WHERE b.id              = p_branch_id
    AND b.organization_id = v_org_id
    AND b.is_active       = TRUE
    AND b.deleted_at      IS NULL
  LIMIT 1;

  IF v_business_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Branch not found or not accessible.');
  END IF;

  -- Validate employee belongs to this business (if provided)
  IF p_employee_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.employees e
      WHERE e.id          = p_employee_id
        AND e.business_id = v_business_id
        AND e.deleted_at  IS NULL
    ) THEN
      RETURN jsonb_build_object('status', 'error', 'message', 'Employee not found.');
    END IF;
  END IF;

  INSERT INTO public.admin_time_blocks (
    organization_id, business_id, branch_id, employee_id,
    title, reason, block_date, start_time, end_time, is_all_day, created_by
  ) VALUES (
    v_org_id, v_business_id, p_branch_id, p_employee_id,
    p_title, p_reason, p_block_date, p_start_time, p_end_time, p_is_all_day, v_user_id
  )
  RETURNING id INTO v_block_id;

  RETURN jsonb_build_object('status', 'success', 'block_id', v_block_id);

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('status', 'error_internal', 'message', SQLERRM);
END;
$$;

REVOKE ALL ON FUNCTION public.create_time_block(UUID, TEXT, DATE, TIME WITHOUT TIME ZONE, TIME WITHOUT TIME ZONE, UUID, TEXT, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_time_block(UUID, TEXT, DATE, TIME WITHOUT TIME ZONE, TIME WITHOUT TIME ZONE, UUID, TEXT, BOOLEAN) TO authenticated;

-- ============================================================
-- AUTHENTICATED RPC: update_time_block
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_time_block(
  p_block_id    UUID,
  p_title       TEXT    DEFAULT NULL,
  p_block_date  DATE    DEFAULT NULL,
  p_start_time  TIME WITHOUT TIME ZONE DEFAULT NULL,
  p_end_time    TIME WITHOUT TIME ZONE DEFAULT NULL,
  p_reason      TEXT    DEFAULT NULL,
  p_is_all_day  BOOLEAN DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID;
  v_org_id  UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Authentication required.');
  END IF;

  SELECT om.organization_id INTO v_org_id
  FROM public.organization_members om
  WHERE om.user_id   = v_user_id
    AND om.is_active = TRUE
  LIMIT 1;

  -- Verify block belongs to this org and is not deleted
  IF NOT EXISTS (
    SELECT 1 FROM public.admin_time_blocks atb
    WHERE atb.id              = p_block_id
      AND atb.organization_id = v_org_id
      AND atb.deleted_at      IS NULL
  ) THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Time block not found.');
  END IF;

  UPDATE public.admin_time_blocks
  SET
    title      = COALESCE(p_title,      title),
    block_date = COALESCE(p_block_date, block_date),
    start_time = COALESCE(p_start_time, start_time),
    end_time   = COALESCE(p_end_time,   end_time),
    reason     = COALESCE(p_reason,     reason),
    is_all_day = COALESCE(p_is_all_day, is_all_day),
    updated_at = NOW()
  WHERE id = p_block_id;

  RETURN jsonb_build_object('status', 'success');

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('status', 'error_internal', 'message', SQLERRM);
END;
$$;

REVOKE ALL ON FUNCTION public.update_time_block(UUID, TEXT, DATE, TIME WITHOUT TIME ZONE, TIME WITHOUT TIME ZONE, TEXT, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_time_block(UUID, TEXT, DATE, TIME WITHOUT TIME ZONE, TIME WITHOUT TIME ZONE, TEXT, BOOLEAN) TO authenticated;

-- ============================================================
-- AUTHENTICATED RPC: delete_time_block
-- Soft-deletes a future time block. Past blocks cannot be removed.
-- ============================================================

CREATE OR REPLACE FUNCTION public.delete_time_block(
  p_block_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id  UUID;
  v_org_id   UUID;
  v_block    RECORD;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Authentication required.');
  END IF;

  SELECT om.organization_id INTO v_org_id
  FROM public.organization_members om
  WHERE om.user_id   = v_user_id
    AND om.is_active = TRUE
  LIMIT 1;

  SELECT id, block_date, organization_id, deleted_at
  INTO v_block
  FROM public.admin_time_blocks
  WHERE id = p_block_id
  LIMIT 1;

  IF NOT FOUND OR v_block.deleted_at IS NOT NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Time block not found.');
  END IF;

  IF v_block.organization_id <> v_org_id THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not authorized.');
  END IF;

  -- Only allow deleting future blocks
  IF v_block.block_date < CURRENT_DATE THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Cannot delete past time blocks.');
  END IF;

  UPDATE public.admin_time_blocks
  SET deleted_at = NOW(), updated_at = NOW()
  WHERE id = p_block_id;

  RETURN jsonb_build_object('status', 'success');

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('status', 'error_internal', 'message', SQLERRM);
END;
$$;

REVOKE ALL ON FUNCTION public.delete_time_block(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_time_block(UUID) TO authenticated;

-- ============================================================
-- AUTHENTICATED RPC: get_business_appointments
-- Returns appointments for the calendar dashboard.
-- Derives org scope from authenticated user.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_business_appointments(
  p_date_from DATE,
  p_date_to   DATE,
  p_branch_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID;
  v_org_id  UUID;
  v_result  JSONB;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Authentication required.');
  END IF;

  SELECT om.organization_id INTO v_org_id
  FROM public.organization_members om
  WHERE om.user_id   = v_user_id
    AND om.is_active = TRUE
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not a member of any organization.');
  END IF;

  SELECT jsonb_build_object(
    'status',       'success',
    'appointments', COALESCE(jsonb_agg(
      jsonb_build_object(
        'id',              a.id,
        'title',           a.title,
        'status',          a.status,
        'starts_at',       a.starts_at,
        'ends_at',         a.ends_at,
        'duration_mins',   a.duration_mins,
        'total_price',     a.total_price,
        'currency',        a.currency,
        'notes',           a.notes,
        'internal_notes',  a.internal_notes,
        'booking_source',  a.booking_source,
        'booked_online',   a.booked_online,
        'branch_id',       a.branch_id,
        'customer_id',     a.customer_id,
        'created_at',      a.created_at,
        'service_name',    (
          SELECT aps.service_name FROM public.appointment_services aps
          WHERE aps.appointment_id = a.id LIMIT 1
        ),
        'employee_id',     (
          SELECT ae.employee_id FROM public.appointment_employees ae
          WHERE ae.appointment_id = a.id AND ae.is_primary = TRUE LIMIT 1
        ),
        'employee_name',   (
          SELECT up.full_name FROM public.appointment_employees ae
          JOIN public.employees e ON e.id = ae.employee_id
          JOIN public.user_profiles up ON up.id = e.user_id
          WHERE ae.appointment_id = a.id AND ae.is_primary = TRUE LIMIT 1
        ),
        'customer_name',   (
          SELECT c.full_name FROM public.customers c
          WHERE c.id = a.customer_id LIMIT 1
        )
      )
      ORDER BY a.starts_at ASC
    ), '[]'::JSONB),
    'time_blocks',  COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'id',          atb.id,
          'title',       atb.title,
          'reason',      atb.reason,
          'block_date',  atb.block_date,
          'start_time',  atb.start_time,
          'end_time',    atb.end_time,
          'is_all_day',  atb.is_all_day,
          'employee_id', atb.employee_id,
          'branch_id',   atb.branch_id
        )
        ORDER BY atb.block_date ASC, atb.start_time ASC
      )
      FROM public.admin_time_blocks atb
      WHERE atb.organization_id = v_org_id
        AND atb.deleted_at      IS NULL
        AND atb.block_date      BETWEEN p_date_from AND p_date_to
        AND (p_branch_id IS NULL OR atb.branch_id = p_branch_id OR atb.branch_id IS NULL)
    ), '[]'::JSONB)
  )
  INTO v_result
  FROM public.appointments a
  WHERE a.organization_id = v_org_id
    AND a.deleted_at      IS NULL
    AND a.starts_at::DATE BETWEEN p_date_from AND p_date_to
    AND (p_branch_id IS NULL OR a.branch_id = p_branch_id);

  RETURN v_result;

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('status', 'error_internal', 'message', SQLERRM);
END;
$$;

REVOKE ALL ON FUNCTION public.get_business_appointments(DATE, DATE, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_appointments(DATE, DATE, UUID) TO authenticated;

-- ============================================================
-- AUTHENTICATED RPC: get_calendar_month_summary
-- Returns per-day appointment counts for the calendar grid dots.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_calendar_month_summary(
  p_year  INTEGER,
  p_month INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID;
  v_org_id  UUID;
  v_result  JSONB;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Authentication required.');
  END IF;

  SELECT om.organization_id INTO v_org_id
  FROM public.organization_members om
  WHERE om.user_id   = v_user_id
    AND om.is_active = TRUE
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not a member of any organization.');
  END IF;

  SELECT jsonb_build_object(
    'status', 'success',
    'days',   COALESCE(jsonb_agg(
      jsonb_build_object(
        'date',              day_data.appt_date,
        'appointment_count', day_data.cnt,
        'has_block',         day_data.has_block
      )
      ORDER BY day_data.appt_date
    ), '[]'::JSONB)
  )
  INTO v_result
  FROM (
    SELECT
      a.starts_at::DATE AS appt_date,
      COUNT(*)          AS cnt,
      EXISTS (
        SELECT 1 FROM public.admin_time_blocks atb
        WHERE atb.organization_id = v_org_id
          AND atb.deleted_at      IS NULL
          AND atb.block_date      = a.starts_at::DATE
      ) AS has_block
    FROM public.appointments a
    WHERE a.organization_id = v_org_id
      AND a.deleted_at      IS NULL
      AND EXTRACT(YEAR  FROM a.starts_at) = p_year
      AND EXTRACT(MONTH FROM a.starts_at) = p_month
      AND a.status NOT IN ('cancelled'::public.appointment_status, 'no_show'::public.appointment_status)
    GROUP BY a.starts_at::DATE
  ) day_data;

  RETURN v_result;

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('status', 'error_internal', 'message', SQLERRM);
END;
$$;

REVOKE ALL ON FUNCTION public.get_calendar_month_summary(INTEGER, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_calendar_month_summary(INTEGER, INTEGER) TO authenticated;

-- ============================================================
-- REFACTOR: get_public_availability to use check_slot_available
-- Replaces the inline conflict logic with the shared function.
-- This ensures public and manual booking use the SAME algorithm.
-- ============================================================

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
  v_duration_mins INTEGER;
  v_buffer_before INTEGER;
  v_buffer_after  INTEGER;
  v_day_of_week   TEXT;
  v_biz_hours     RECORD;
  v_work_hours    RECORD;
  v_slot_start    TIME;
  v_slot_end      TIME;
  v_slot_step     INTEGER := 15;
  v_slots         JSONB   := '[]'::JSONB;
  v_slot_ts       TIMESTAMPTZ;
  v_slot_end_ts   TIMESTAMPTZ;
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

  -- Validate employee can perform service
  IF NOT EXISTS (
    SELECT 1 FROM public.employee_services es
    WHERE es.employee_id = p_employee_id
      AND es.service_id  = p_service_id
      AND es.is_active   = TRUE
  ) THEN
    RETURN jsonb_build_object('slots', '[]'::JSONB, 'date', p_date, 'error', 'Employee cannot perform this service.');
  END IF;

  -- Resolve service duration
  SELECT COALESCE(es.duration_override_mins, s.duration_mins),
         s.buffer_before_mins,
         s.buffer_after_mins
  INTO v_duration_mins, v_buffer_before, v_buffer_after
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

  -- Get business/branch hours
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

  -- Iterate slots — delegate conflict detection to check_slot_available()
  WHILE v_slot_start + (v_duration_mins || ' minutes')::INTERVAL <= v_slot_end LOOP
    v_slot_ts     := (p_date::TEXT || ' ' || v_slot_start::TEXT)::TIMESTAMPTZ
                     AT TIME ZONE v_branch.timezone;
    v_slot_end_ts := v_slot_ts + (v_duration_mins || ' minutes')::INTERVAL;

    IF v_slot_ts > NOW() THEN
      IF public.check_slot_available(
        v_business.id,
        p_branch_id,
        p_employee_id,
        p_service_id,
        v_slot_ts,
        v_slot_end_ts,
        v_buffer_before,
        v_buffer_after,
        NULL
      ) THEN
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
