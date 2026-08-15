-- ============================================================
-- ReserveHub Migration 15: Business Management Layer
-- Dashboard KPIs, Customer CRM, Schedule Exceptions, Holidays
-- ============================================================

-- ─── TABLE: schedule_exceptions ──────────────────────────────
-- Date-specific overrides for business/branch hours (holidays, closures, modified hours)
CREATE TABLE IF NOT EXISTS public.schedule_exceptions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL,
  business_id     UUID NOT NULL,
  branch_id       UUID,
  exception_date  DATE NOT NULL,
  exception_type  TEXT NOT NULL DEFAULT 'modified_hours',
  -- Types: 'closed', 'modified_hours', 'holiday'
  is_closed       BOOLEAN NOT NULL DEFAULT FALSE,
  open_time       TIME WITHOUT TIME ZONE,
  close_time      TIME WITHOUT TIME ZONE,
  reason          TEXT,
  is_recurring    BOOLEAN NOT NULL DEFAULT FALSE,
  -- If recurring, only month+day matters (year ignored)
  created_by      UUID,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT schedule_exceptions_time_valid CHECK (
    is_closed = TRUE OR (open_time IS NOT NULL AND close_time IS NOT NULL AND open_time < close_time)
  )
);

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organizations') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'schedule_exceptions_organization_id_fkey' AND table_name = 'schedule_exceptions') THEN
      ALTER TABLE public.schedule_exceptions ADD CONSTRAINT schedule_exceptions_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'businesses') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'schedule_exceptions_business_id_fkey' AND table_name = 'schedule_exceptions') THEN
      ALTER TABLE public.schedule_exceptions ADD CONSTRAINT schedule_exceptions_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'branches') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'schedule_exceptions_branch_id_fkey' AND table_name = 'schedule_exceptions') THEN
      ALTER TABLE public.schedule_exceptions ADD CONSTRAINT schedule_exceptions_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_profiles') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'schedule_exceptions_created_by_fkey' AND table_name = 'schedule_exceptions') THEN
      ALTER TABLE public.schedule_exceptions ADD CONSTRAINT schedule_exceptions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.user_profiles(id) ON DELETE SET NULL;
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_schedule_exceptions_business_date
  ON public.schedule_exceptions (business_id, exception_date);

CREATE INDEX IF NOT EXISTS idx_schedule_exceptions_branch_date
  ON public.schedule_exceptions (branch_id, exception_date)
  WHERE branch_id IS NOT NULL;

-- ─── TABLE: employee_time_off ─────────────────────────────────
-- Employee time off / leave management
CREATE TABLE IF NOT EXISTS public.employee_time_off (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL,
  employee_id     UUID NOT NULL,
  start_datetime  TIMESTAMPTZ NOT NULL,
  end_datetime    TIMESTAMPTZ NOT NULL,
  reason          TEXT,
  time_off_type   TEXT NOT NULL DEFAULT 'unavailable',
  -- Types: 'vacation', 'illness', 'personal', 'training', 'unavailable'
  status          TEXT NOT NULL DEFAULT 'approved',
  -- Statuses: 'pending', 'approved', 'rejected'
  notes           TEXT,
  created_by      UUID,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT employee_time_off_dates_valid CHECK (start_datetime < end_datetime)
);

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organizations') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'employee_time_off_organization_id_fkey' AND table_name = 'employee_time_off') THEN
      ALTER TABLE public.employee_time_off ADD CONSTRAINT employee_time_off_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'employees') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'employee_time_off_employee_id_fkey' AND table_name = 'employee_time_off') THEN
      ALTER TABLE public.employee_time_off ADD CONSTRAINT employee_time_off_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(id) ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_profiles') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'employee_time_off_created_by_fkey' AND table_name = 'employee_time_off') THEN
      ALTER TABLE public.employee_time_off ADD CONSTRAINT employee_time_off_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.user_profiles(id) ON DELETE SET NULL;
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_employee_time_off_employee
  ON public.employee_time_off (employee_id, start_datetime, end_datetime);

CREATE INDEX IF NOT EXISTS idx_employee_time_off_org
  ON public.employee_time_off (organization_id, start_datetime);

-- ─── TABLE: employee_breaks ──────────────────────────────────
-- Recurring or date-specific breaks for employees
CREATE TABLE IF NOT EXISTS public.employee_breaks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL,
  employee_id     UUID NOT NULL,
  break_name      TEXT NOT NULL DEFAULT 'Break',
  day_of_week     public.day_of_week,
  -- NULL = applies to all days
  specific_date   DATE,
  -- NULL = recurring, set = date-specific
  start_time      TIME WITHOUT TIME ZONE NOT NULL,
  end_time        TIME WITHOUT TIME ZONE NOT NULL,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_by      UUID,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT employee_breaks_time_valid CHECK (start_time < end_time)
);

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organizations') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'employee_breaks_organization_id_fkey' AND table_name = 'employee_breaks') THEN
      ALTER TABLE public.employee_breaks ADD CONSTRAINT employee_breaks_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'employees') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'employee_breaks_employee_id_fkey' AND table_name = 'employee_breaks') THEN
      ALTER TABLE public.employee_breaks ADD CONSTRAINT employee_breaks_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(id) ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_profiles') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'employee_breaks_created_by_fkey' AND table_name = 'employee_breaks') THEN
      ALTER TABLE public.employee_breaks ADD CONSTRAINT employee_breaks_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.user_profiles(id) ON DELETE SET NULL;
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_employee_breaks_employee
  ON public.employee_breaks (employee_id, is_active);

-- ─── RLS: schedule_exceptions ────────────────────────────────
ALTER TABLE public.schedule_exceptions ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organization_members')
     AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'schedule_exceptions' AND policyname = 'schedule_exceptions_org_select')
  THEN
    CREATE POLICY schedule_exceptions_org_select ON public.schedule_exceptions
      FOR SELECT TO authenticated
      USING (
        organization_id IN (
          SELECT organization_id FROM public.organization_members
          WHERE user_id = auth.uid() AND status = 'active'
        )
      );
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organization_members')
     AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'schedule_exceptions' AND policyname = 'schedule_exceptions_org_insert')
  THEN
    CREATE POLICY schedule_exceptions_org_insert ON public.schedule_exceptions
      FOR INSERT TO authenticated
      WITH CHECK (
        organization_id IN (
          SELECT organization_id FROM public.organization_members
          WHERE user_id = auth.uid() AND status = 'active'
            AND role IN ('owner', 'admin', 'manager')
        )
      );
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organization_members')
     AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'schedule_exceptions' AND policyname = 'schedule_exceptions_org_update')
  THEN
    CREATE POLICY schedule_exceptions_org_update ON public.schedule_exceptions
      FOR UPDATE TO authenticated
      USING (
        organization_id IN (
          SELECT organization_id FROM public.organization_members
          WHERE user_id = auth.uid() AND status = 'active'
            AND role IN ('owner', 'admin', 'manager')
        )
      );
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organization_members')
     AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'schedule_exceptions' AND policyname = 'schedule_exceptions_org_delete')
  THEN
    CREATE POLICY schedule_exceptions_org_delete ON public.schedule_exceptions
      FOR DELETE TO authenticated
      USING (
        organization_id IN (
          SELECT organization_id FROM public.organization_members
          WHERE user_id = auth.uid() AND status = 'active'
            AND role IN ('owner', 'admin', 'manager')
        )
      );
  END IF;
END $$;

-- ─── RLS: employee_time_off ───────────────────────────────────
ALTER TABLE public.employee_time_off ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organization_members')
     AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'employee_time_off' AND policyname = 'employee_time_off_org_select')
  THEN
    CREATE POLICY employee_time_off_org_select ON public.employee_time_off
      FOR SELECT TO authenticated
      USING (
        organization_id IN (
          SELECT organization_id FROM public.organization_members
          WHERE user_id = auth.uid() AND status = 'active'
        )
      );
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organization_members')
     AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'employee_time_off' AND policyname = 'employee_time_off_org_insert')
  THEN
    CREATE POLICY employee_time_off_org_insert ON public.employee_time_off
      FOR INSERT TO authenticated
      WITH CHECK (
        organization_id IN (
          SELECT organization_id FROM public.organization_members
          WHERE user_id = auth.uid() AND status = 'active'
            AND role IN ('owner', 'admin', 'manager', 'receptionist')
        )
      );
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organization_members')
     AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'employee_time_off' AND policyname = 'employee_time_off_org_update')
  THEN
    CREATE POLICY employee_time_off_org_update ON public.employee_time_off
      FOR UPDATE TO authenticated
      USING (
        organization_id IN (
          SELECT organization_id FROM public.organization_members
          WHERE user_id = auth.uid() AND status = 'active'
            AND role IN ('owner', 'admin', 'manager', 'receptionist')
        )
      );
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organization_members')
     AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'employee_time_off' AND policyname = 'employee_time_off_org_delete')
  THEN
    CREATE POLICY employee_time_off_org_delete ON public.employee_time_off
      FOR DELETE TO authenticated
      USING (
        organization_id IN (
          SELECT organization_id FROM public.organization_members
          WHERE user_id = auth.uid() AND status = 'active'
            AND role IN ('owner', 'admin', 'manager')
        )
      );
  END IF;
END $$;

-- ─── RLS: employee_breaks ─────────────────────────────────────
ALTER TABLE public.employee_breaks ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organization_members')
     AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'employee_breaks' AND policyname = 'employee_breaks_org_select')
  THEN
    CREATE POLICY employee_breaks_org_select ON public.employee_breaks
      FOR SELECT TO authenticated
      USING (
        organization_id IN (
          SELECT organization_id FROM public.organization_members
          WHERE user_id = auth.uid() AND status = 'active'
        )
      );
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organization_members')
     AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'employee_breaks' AND policyname = 'employee_breaks_org_insert')
  THEN
    CREATE POLICY employee_breaks_org_insert ON public.employee_breaks
      FOR INSERT TO authenticated
      WITH CHECK (
        organization_id IN (
          SELECT organization_id FROM public.organization_members
          WHERE user_id = auth.uid() AND status = 'active'
            AND role IN ('owner', 'admin', 'manager')
        )
      );
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organization_members')
     AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'employee_breaks' AND policyname = 'employee_breaks_org_update')
  THEN
    CREATE POLICY employee_breaks_org_update ON public.employee_breaks
      FOR UPDATE TO authenticated
      USING (
        organization_id IN (
          SELECT organization_id FROM public.organization_members
          WHERE user_id = auth.uid() AND status = 'active'
            AND role IN ('owner', 'admin', 'manager')
        )
      );
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organization_members')
     AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'employee_breaks' AND policyname = 'employee_breaks_org_delete')
  THEN
    CREATE POLICY employee_breaks_org_delete ON public.employee_breaks
      FOR DELETE TO authenticated
      USING (
        organization_id IN (
          SELECT organization_id FROM public.organization_members
          WHERE user_id = auth.uid() AND status = 'active'
            AND role IN ('owner', 'admin', 'manager')
        )
      );
  END IF;
END $$;

-- ─── RPC: get_dashboard_kpis ──────────────────────────────────
-- Returns real KPI data for the business dashboard
CREATE OR REPLACE FUNCTION public.get_dashboard_kpis(
  p_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
  v_today_count INTEGER;
  v_upcoming_count INTEGER;
  v_completed_count INTEGER;
  v_cancelled_count INTEGER;
  v_customer_count INTEGER;
  v_appointment_value DECIMAL;
  v_yesterday_count INTEGER;
BEGIN
  -- Derive org from authenticated user
  SELECT organization_id INTO v_org_id
  FROM public.organization_members
  WHERE user_id = auth.uid() AND status = 'active'
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not authorized');
  END IF;

  -- Today's appointments
  SELECT COUNT(*) INTO v_today_count
  FROM public.appointments a
  WHERE a.organization_id = v_org_id
    AND DATE(a.starts_at AT TIME ZONE 'UTC') = p_date
    AND a.status NOT IN ('cancelled');

  -- Yesterday's appointments (for trend)
  SELECT COUNT(*) INTO v_yesterday_count
  FROM public.appointments a
  WHERE a.organization_id = v_org_id
    AND DATE(a.starts_at AT TIME ZONE 'UTC') = p_date - INTERVAL '1 day'
    AND a.status NOT IN ('cancelled');

  -- Upcoming (next 7 days, excluding today)
  SELECT COUNT(*) INTO v_upcoming_count
  FROM public.appointments a
  WHERE a.organization_id = v_org_id
    AND DATE(a.starts_at AT TIME ZONE 'UTC') > p_date
    AND DATE(a.starts_at AT TIME ZONE 'UTC') <= p_date + INTERVAL '7 days'
    AND a.status NOT IN ('cancelled');

  -- Completed today
  SELECT COUNT(*) INTO v_completed_count
  FROM public.appointments a
  WHERE a.organization_id = v_org_id
    AND DATE(a.starts_at AT TIME ZONE 'UTC') = p_date
    AND a.status = 'completed';

  -- Cancelled today
  SELECT COUNT(*) INTO v_cancelled_count
  FROM public.appointments a
  WHERE a.organization_id = v_org_id
    AND DATE(a.starts_at AT TIME ZONE 'UTC') = p_date
    AND a.status = 'cancelled';

  -- Total active customers
  SELECT COUNT(*) INTO v_customer_count
  FROM public.customers c
  WHERE c.organization_id = v_org_id
    AND c.deleted_at IS NULL
    AND c.status = 'active';

  -- Appointment value today (informational: sum of service prices)
  SELECT COALESCE(SUM(a.total_price), 0) INTO v_appointment_value
  FROM public.appointments a
  WHERE a.organization_id = v_org_id
    AND DATE(a.starts_at AT TIME ZONE 'UTC') = p_date
    AND a.status NOT IN ('cancelled');

  RETURN jsonb_build_object(
    'status', 'success',
    'today_count', v_today_count,
    'yesterday_count', v_yesterday_count,
    'upcoming_count', v_upcoming_count,
    'completed_count', v_completed_count,
    'cancelled_count', v_cancelled_count,
    'customer_count', v_customer_count,
    'appointment_value', v_appointment_value,
    'date', p_date
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_dashboard_kpis(DATE) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_dashboard_kpis(DATE) TO authenticated;

-- ─── RPC: get_customers_list ──────────────────────────────────
-- Returns paginated customer list for the business CRM
CREATE OR REPLACE FUNCTION public.get_customers_list(
  p_search TEXT DEFAULT NULL,
  p_status TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
  v_customers JSONB;
  v_total INTEGER;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.organization_members
  WHERE user_id = auth.uid() AND status = 'active'
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not authorized');
  END IF;

  SELECT COUNT(*) INTO v_total
  FROM public.customers c
  WHERE c.organization_id = v_org_id
    AND c.deleted_at IS NULL
    AND (p_status IS NULL OR c.status::TEXT = p_status)
    AND (
      p_search IS NULL
      OR c.first_name ILIKE '%' || p_search || '%'
      OR c.last_name ILIKE '%' || p_search || '%'
      OR c.email ILIKE '%' || p_search || '%'
      OR c.phone ILIKE '%' || p_search || '%'
      OR CONCAT(c.first_name, ' ', c.last_name) ILIKE '%' || p_search || '%'
    );

  SELECT jsonb_agg(
    jsonb_build_object(
      'id', c.id,
      'first_name', c.first_name,
      'last_name', c.last_name,
      'display_name', COALESCE(c.display_name, c.first_name || ' ' || c.last_name),
      'email', c.email,
      'phone', c.phone,
      'avatar_url', c.avatar_url,
      'status', c.status,
      'total_visits', c.total_visits,
      'total_spent', c.total_spent,
      'loyalty_points', c.loyalty_points,
      'last_visit_at', c.last_visit_at,
      'tags', c.tags,
      'created_at', c.created_at
    )
    ORDER BY c.last_visit_at DESC NULLS LAST, c.created_at DESC
  ) INTO v_customers
  FROM public.customers c
  WHERE c.organization_id = v_org_id
    AND c.deleted_at IS NULL
    AND (p_status IS NULL OR c.status::TEXT = p_status)
    AND (
      p_search IS NULL
      OR c.first_name ILIKE '%' || p_search || '%'
      OR c.last_name ILIKE '%' || p_search || '%'
      OR c.email ILIKE '%' || p_search || '%'
      OR c.phone ILIKE '%' || p_search || '%'
      OR CONCAT(c.first_name, ' ', c.last_name) ILIKE '%' || p_search || '%'
    )
  LIMIT p_limit OFFSET p_offset;

  RETURN jsonb_build_object(
    'status', 'success',
    'customers', COALESCE(v_customers, '[]'::JSONB),
    'total', v_total,
    'limit', p_limit,
    'offset', p_offset
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_customers_list(TEXT, TEXT, INTEGER, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_customers_list(TEXT, TEXT, INTEGER, INTEGER) TO authenticated;

-- ─── RPC: get_customer_details ────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_customer_details(
  p_customer_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
  v_customer JSONB;
  v_appointments JSONB;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.organization_members
  WHERE user_id = auth.uid() AND status = 'active'
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not authorized');
  END IF;

  SELECT jsonb_build_object(
    'id', c.id,
    'first_name', c.first_name,
    'last_name', c.last_name,
    'display_name', COALESCE(c.display_name, c.first_name || ' ' || c.last_name),
    'email', c.email,
    'phone', c.phone,
    'avatar_url', c.avatar_url,
    'status', c.status,
    'total_visits', c.total_visits,
    'total_spent', c.total_spent,
    'loyalty_points', c.loyalty_points,
    'last_visit_at', c.last_visit_at,
    'tags', c.tags,
    'notes', c.notes,
    'created_at', c.created_at
  ) INTO v_customer
  FROM public.customers c
  WHERE c.id = p_customer_id
    AND c.organization_id = v_org_id
    AND c.deleted_at IS NULL;

  IF v_customer IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Customer not found');
  END IF;

  -- Appointment history
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', a.id,
      'starts_at', a.starts_at,
      'ends_at', a.ends_at,
      'status', a.status,
      'total_price', a.total_price,
      'notes', a.notes
    )
    ORDER BY a.starts_at DESC
  ) INTO v_appointments
  FROM public.appointments a
  WHERE a.customer_id = p_customer_id
    AND a.organization_id = v_org_id
  LIMIT 20;

  RETURN jsonb_build_object(
    'status', 'success',
    'customer', v_customer,
    'appointments', COALESCE(v_appointments, '[]'::JSONB)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_customer_details(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_customer_details(UUID) TO authenticated;

-- ─── RPC: get_business_hours ──────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_business_hours_for_management(
  p_business_id UUID,
  p_branch_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
  v_hours JSONB;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.organization_members
  WHERE user_id = auth.uid() AND status = 'active'
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not authorized');
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'id', bh.id,
      'day_of_week', bh.day_of_week,
      'is_open', bh.is_open,
      'open_time', bh.open_time,
      'close_time', bh.close_time,
      'timezone', bh.timezone
    )
    ORDER BY CASE bh.day_of_week
      WHEN 'monday' THEN 1 WHEN 'tuesday' THEN 2 WHEN 'wednesday' THEN 3
      WHEN 'thursday' THEN 4 WHEN 'friday' THEN 5 WHEN 'saturday' THEN 6
      WHEN 'sunday' THEN 7 END
  ) INTO v_hours
  FROM public.business_hours bh
  WHERE bh.business_id = p_business_id
    AND bh.organization_id = v_org_id
    AND (p_branch_id IS NULL AND bh.branch_id IS NULL
         OR bh.branch_id = p_branch_id)
    AND bh.effective_from IS NULL
    AND bh.effective_until IS NULL;

  RETURN jsonb_build_object(
    'status', 'success',
    'hours', COALESCE(v_hours, '[]'::JSONB)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_business_hours_for_management(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_hours_for_management(UUID, UUID) TO authenticated;

-- ─── RPC: upsert_business_hours ───────────────────────────────
CREATE OR REPLACE FUNCTION public.upsert_business_hours(
  p_business_id UUID,
  p_hours JSONB,
  p_branch_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
  v_hour JSONB;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.organization_members
  WHERE user_id = auth.uid() AND status = 'active'
    AND role IN ('owner', 'admin', 'manager')
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not authorized');
  END IF;

  FOR v_hour IN SELECT * FROM jsonb_array_elements(p_hours)
  LOOP
    INSERT INTO public.business_hours (
      organization_id, business_id, branch_id, day_of_week,
      is_open, open_time, close_time, timezone
    )
    VALUES (
      v_org_id,
      p_business_id,
      p_branch_id,
      (v_hour->>'day_of_week')::public.day_of_week,
      (v_hour->>'is_open')::BOOLEAN,
      CASE WHEN (v_hour->>'is_open')::BOOLEAN THEN (v_hour->>'open_time')::TIME ELSE NULL END,
      CASE WHEN (v_hour->>'is_open')::BOOLEAN THEN (v_hour->>'close_time')::TIME ELSE NULL END,
      COALESCE(v_hour->>'timezone', 'UTC')
    )
    ON CONFLICT ON CONSTRAINT business_hours_time_valid DO NOTHING;

    -- Update if exists
    UPDATE public.business_hours
    SET
      is_open = (v_hour->>'is_open')::BOOLEAN,
      open_time = CASE WHEN (v_hour->>'is_open')::BOOLEAN THEN (v_hour->>'open_time')::TIME ELSE NULL END,
      close_time = CASE WHEN (v_hour->>'is_open')::BOOLEAN THEN (v_hour->>'close_time')::TIME ELSE NULL END,
      timezone = COALESCE(v_hour->>'timezone', 'UTC'),
      updated_at = NOW()
    WHERE business_id = p_business_id
      AND organization_id = v_org_id
      AND day_of_week = (v_hour->>'day_of_week')::public.day_of_week
      AND (p_branch_id IS NULL AND branch_id IS NULL OR branch_id = p_branch_id)
      AND effective_from IS NULL
      AND effective_until IS NULL;
  END LOOP;

  RETURN jsonb_build_object('status', 'success');
END;
$$;

REVOKE ALL ON FUNCTION public.upsert_business_hours(UUID, JSONB, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.upsert_business_hours(UUID, JSONB, UUID) TO authenticated;

-- ─── RPC: get_employee_working_hours ─────────────────────────
CREATE OR REPLACE FUNCTION public.get_employee_working_hours(
  p_employee_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
  v_hours JSONB;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.organization_members
  WHERE user_id = auth.uid() AND status = 'active'
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not authorized');
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'id', wh.id,
      'day_of_week', wh.day_of_week,
      'is_working', wh.is_working,
      'start_time', wh.start_time,
      'end_time', wh.end_time,
      'timezone', wh.timezone
    )
    ORDER BY CASE wh.day_of_week
      WHEN 'monday' THEN 1 WHEN 'tuesday' THEN 2 WHEN 'wednesday' THEN 3
      WHEN 'thursday' THEN 4 WHEN 'friday' THEN 5 WHEN 'saturday' THEN 6
      WHEN 'sunday' THEN 7 END
  ) INTO v_hours
  FROM public.working_hours wh
  WHERE wh.employee_id = p_employee_id
    AND wh.organization_id = v_org_id
    AND wh.effective_from IS NULL
    AND wh.effective_until IS NULL;

  RETURN jsonb_build_object(
    'status', 'success',
    'hours', COALESCE(v_hours, '[]'::JSONB)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_employee_working_hours(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_employee_working_hours(UUID) TO authenticated;

-- ─── RPC: upsert_employee_working_hours ──────────────────────
CREATE OR REPLACE FUNCTION public.upsert_employee_working_hours(
  p_employee_id UUID,
  p_hours JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
  v_hour JSONB;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.organization_members
  WHERE user_id = auth.uid() AND status = 'active'
    AND role IN ('owner', 'admin', 'manager')
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not authorized');
  END IF;

  FOR v_hour IN SELECT * FROM jsonb_array_elements(p_hours)
  LOOP
    INSERT INTO public.working_hours (
      organization_id, employee_id, day_of_week,
      is_working, start_time, end_time, timezone
    )
    VALUES (
      v_org_id,
      p_employee_id,
      (v_hour->>'day_of_week')::public.day_of_week,
      (v_hour->>'is_working')::BOOLEAN,
      CASE WHEN (v_hour->>'is_working')::BOOLEAN THEN (v_hour->>'start_time')::TIME ELSE NULL END,
      CASE WHEN (v_hour->>'is_working')::BOOLEAN THEN (v_hour->>'end_time')::TIME ELSE NULL END,
      COALESCE(v_hour->>'timezone', 'UTC')
    )
    ON CONFLICT DO NOTHING;

    UPDATE public.working_hours
    SET
      is_working = (v_hour->>'is_working')::BOOLEAN,
      start_time = CASE WHEN (v_hour->>'is_working')::BOOLEAN THEN (v_hour->>'start_time')::TIME ELSE NULL END,
      end_time = CASE WHEN (v_hour->>'is_working')::BOOLEAN THEN (v_hour->>'end_time')::TIME ELSE NULL END,
      timezone = COALESCE(v_hour->>'timezone', 'UTC'),
      updated_at = NOW()
    WHERE employee_id = p_employee_id
      AND organization_id = v_org_id
      AND day_of_week = (v_hour->>'day_of_week')::public.day_of_week
      AND effective_from IS NULL
      AND effective_until IS NULL;
  END LOOP;

  RETURN jsonb_build_object('status', 'success');
END;
$$;

REVOKE ALL ON FUNCTION public.upsert_employee_working_hours(UUID, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.upsert_employee_working_hours(UUID, JSONB) TO authenticated;

-- ─── RPC: get_booking_settings ────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_booking_settings_for_management(
  p_business_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
  v_settings JSONB;
  v_policy JSONB;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.organization_members
  WHERE user_id = auth.uid() AND status = 'active'
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not authorized');
  END IF;

  SELECT jsonb_build_object(
    'id', bs.id,
    'online_booking_enabled', bs.online_booking_enabled,
    'guest_booking_enabled', bs.guest_booking_enabled,
    'auto_confirm', bs.auto_confirm,
    'min_booking_notice_hours', bs.min_booking_notice_hours,
    'max_booking_horizon_days', bs.max_booking_horizon_days,
    'slot_duration_minutes', bs.slot_duration_minutes,
    'allow_rescheduling', bs.allow_rescheduling,
    'reschedule_notice_hours', bs.reschedule_notice_hours,
    'max_reschedules', bs.max_reschedules
  ) INTO v_settings
  FROM public.booking_settings bs
  WHERE bs.business_id = p_business_id
    AND bs.organization_id = v_org_id
  LIMIT 1;

  SELECT jsonb_build_object(
    'id', cp.id,
    'cancellation_allowed', cp.cancellation_allowed,
    'cancellation_notice_hours', cp.cancellation_notice_hours,
    'cancellation_fee', cp.cancellation_fee,
    'no_show_fee', cp.no_show_fee,
    'policy_text', cp.policy_text
  ) INTO v_policy
  FROM public.cancellation_policies cp
  WHERE cp.business_id = p_business_id
    AND cp.organization_id = v_org_id
  LIMIT 1;

  RETURN jsonb_build_object(
    'status', 'success',
    'settings', v_settings,
    'cancellation_policy', v_policy
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_booking_settings_for_management(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_booking_settings_for_management(UUID) TO authenticated;

-- ─── RPC: upsert_booking_settings ────────────────────────────
CREATE OR REPLACE FUNCTION public.upsert_booking_settings(
  p_business_id UUID,
  p_online_booking_enabled BOOLEAN DEFAULT TRUE,
  p_guest_booking_enabled BOOLEAN DEFAULT TRUE,
  p_auto_confirm BOOLEAN DEFAULT FALSE,
  p_min_booking_notice_hours INTEGER DEFAULT 1,
  p_max_booking_horizon_days INTEGER DEFAULT 60,
  p_slot_duration_minutes INTEGER DEFAULT 30,
  p_allow_rescheduling BOOLEAN DEFAULT TRUE,
  p_reschedule_notice_hours INTEGER DEFAULT 24,
  p_max_reschedules INTEGER DEFAULT 2,
  p_cancellation_allowed BOOLEAN DEFAULT TRUE,
  p_cancellation_notice_hours INTEGER DEFAULT 24,
  p_cancellation_fee DECIMAL DEFAULT 0,
  p_no_show_fee DECIMAL DEFAULT 0,
  p_policy_text TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.organization_members
  WHERE user_id = auth.uid() AND status = 'active'
    AND role IN ('owner', 'admin', 'manager')
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not authorized');
  END IF;

  INSERT INTO public.booking_settings (
    organization_id, business_id, online_booking_enabled, guest_booking_enabled,
    auto_confirm, min_booking_notice_hours, max_booking_horizon_days,
    slot_duration_minutes, allow_rescheduling, reschedule_notice_hours, max_reschedules
  )
  VALUES (
    v_org_id, p_business_id, p_online_booking_enabled, p_guest_booking_enabled,
    p_auto_confirm, p_min_booking_notice_hours, p_max_booking_horizon_days,
    p_slot_duration_minutes, p_allow_rescheduling, p_reschedule_notice_hours, p_max_reschedules
  )
  ON CONFLICT (business_id) DO UPDATE SET
    online_booking_enabled = EXCLUDED.online_booking_enabled,
    guest_booking_enabled = EXCLUDED.guest_booking_enabled,
    auto_confirm = EXCLUDED.auto_confirm,
    min_booking_notice_hours = EXCLUDED.min_booking_notice_hours,
    max_booking_horizon_days = EXCLUDED.max_booking_horizon_days,
    slot_duration_minutes = EXCLUDED.slot_duration_minutes,
    allow_rescheduling = EXCLUDED.allow_rescheduling,
    reschedule_notice_hours = EXCLUDED.reschedule_notice_hours,
    max_reschedules = EXCLUDED.max_reschedules,
    updated_at = NOW();

  INSERT INTO public.cancellation_policies (
    organization_id, business_id, cancellation_allowed,
    cancellation_notice_hours, cancellation_fee, no_show_fee, policy_text
  )
  VALUES (
    v_org_id, p_business_id, p_cancellation_allowed,
    p_cancellation_notice_hours, p_cancellation_fee, p_no_show_fee, p_policy_text
  )
  ON CONFLICT (business_id) DO UPDATE SET
    cancellation_allowed = EXCLUDED.cancellation_allowed,
    cancellation_notice_hours = EXCLUDED.cancellation_notice_hours,
    cancellation_fee = EXCLUDED.cancellation_fee,
    no_show_fee = EXCLUDED.no_show_fee,
    policy_text = EXCLUDED.policy_text,
    updated_at = NOW();

  RETURN jsonb_build_object('status', 'success');
END;
$$;

REVOKE ALL ON FUNCTION public.upsert_booking_settings(UUID, BOOLEAN, BOOLEAN, BOOLEAN, INTEGER, INTEGER, INTEGER, BOOLEAN, INTEGER, INTEGER, BOOLEAN, INTEGER, DECIMAL, DECIMAL, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.upsert_booking_settings(UUID, BOOLEAN, BOOLEAN, BOOLEAN, INTEGER, INTEGER, INTEGER, BOOLEAN, INTEGER, INTEGER, BOOLEAN, INTEGER, DECIMAL, DECIMAL, TEXT) TO authenticated;

-- ─── RPC: manage_schedule_exception ──────────────────────────
CREATE OR REPLACE FUNCTION public.manage_schedule_exception(
  p_action TEXT,
  p_business_id UUID,
  p_exception_date DATE,
  p_is_closed BOOLEAN DEFAULT FALSE,
  p_open_time TIME DEFAULT NULL,
  p_close_time TIME DEFAULT NULL,
  p_reason TEXT DEFAULT NULL,
  p_exception_type TEXT DEFAULT 'modified_hours',
  p_branch_id UUID DEFAULT NULL,
  p_exception_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
  v_id UUID;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.organization_members
  WHERE user_id = auth.uid() AND status = 'active'
    AND role IN ('owner', 'admin', 'manager')
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not authorized');
  END IF;

  IF p_action = 'create' THEN
    INSERT INTO public.schedule_exceptions (
      organization_id, business_id, branch_id, exception_date,
      exception_type, is_closed, open_time, close_time, reason, created_by
    )
    VALUES (
      v_org_id, p_business_id, p_branch_id, p_exception_date,
      p_exception_type, p_is_closed, p_open_time, p_close_time, p_reason, auth.uid()
    )
    RETURNING id INTO v_id;

    RETURN jsonb_build_object('status', 'success', 'id', v_id);

  ELSIF p_action = 'update' THEN
    UPDATE public.schedule_exceptions
    SET
      is_closed = p_is_closed,
      open_time = p_open_time,
      close_time = p_close_time,
      reason = p_reason,
      exception_type = p_exception_type,
      updated_at = NOW()
    WHERE id = p_exception_id
      AND organization_id = v_org_id;

    RETURN jsonb_build_object('status', 'success');

  ELSIF p_action = 'delete' THEN
    DELETE FROM public.schedule_exceptions
    WHERE id = p_exception_id
      AND organization_id = v_org_id;

    RETURN jsonb_build_object('status', 'success');
  END IF;

  RETURN jsonb_build_object('status', 'error', 'message', 'Invalid action');
END;
$$;

REVOKE ALL ON FUNCTION public.manage_schedule_exception(TEXT, UUID, DATE, BOOLEAN, TIME, TIME, TEXT, TEXT, UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.manage_schedule_exception(TEXT, UUID, DATE, BOOLEAN, TIME, TIME, TEXT, TEXT, UUID, UUID) TO authenticated;

-- ─── RPC: manage_employee_time_off ───────────────────────────
CREATE OR REPLACE FUNCTION public.manage_employee_time_off(
  p_action TEXT,
  p_employee_id UUID DEFAULT NULL,
  p_start_datetime TIMESTAMPTZ DEFAULT NULL,
  p_end_datetime TIMESTAMPTZ DEFAULT NULL,
  p_reason TEXT DEFAULT NULL,
  p_time_off_type TEXT DEFAULT 'unavailable',
  p_time_off_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
  v_id UUID;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.organization_members
  WHERE user_id = auth.uid() AND status = 'active'
    AND role IN ('owner', 'admin', 'manager', 'receptionist')
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not authorized');
  END IF;

  IF p_action = 'create' THEN
    INSERT INTO public.employee_time_off (
      organization_id, employee_id, start_datetime, end_datetime,
      reason, time_off_type, status, created_by
    )
    VALUES (
      v_org_id, p_employee_id, p_start_datetime, p_end_datetime,
      p_reason, p_time_off_type, 'approved', auth.uid()
    )
    RETURNING id INTO v_id;

    RETURN jsonb_build_object('status', 'success', 'id', v_id);

  ELSIF p_action = 'delete' THEN
    DELETE FROM public.employee_time_off
    WHERE id = p_time_off_id
      AND organization_id = v_org_id;

    RETURN jsonb_build_object('status', 'success');
  END IF;

  RETURN jsonb_build_object('status', 'error', 'message', 'Invalid action');
END;
$$;

REVOKE ALL ON FUNCTION public.manage_employee_time_off(TEXT, UUID, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, TEXT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.manage_employee_time_off(TEXT, UUID, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, TEXT, UUID) TO authenticated;

-- ─── RPC: manage_employee_break ──────────────────────────────
CREATE OR REPLACE FUNCTION public.manage_employee_break(
  p_action TEXT,
  p_employee_id UUID DEFAULT NULL,
  p_break_name TEXT DEFAULT 'Break',
  p_day_of_week public.day_of_week DEFAULT NULL,
  p_start_time TIME DEFAULT NULL,
  p_end_time TIME DEFAULT NULL,
  p_break_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
  v_id UUID;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.organization_members
  WHERE user_id = auth.uid() AND status = 'active'
    AND role IN ('owner', 'admin', 'manager')
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not authorized');
  END IF;

  IF p_action = 'create' THEN
    INSERT INTO public.employee_breaks (
      organization_id, employee_id, break_name, day_of_week,
      start_time, end_time, created_by
    )
    VALUES (
      v_org_id, p_employee_id, p_break_name, p_day_of_week,
      p_start_time, p_end_time, auth.uid()
    )
    RETURNING id INTO v_id;

    RETURN jsonb_build_object('status', 'success', 'id', v_id);

  ELSIF p_action = 'delete' THEN
    DELETE FROM public.employee_breaks
    WHERE id = p_break_id
      AND organization_id = v_org_id;

    RETURN jsonb_build_object('status', 'success');
  END IF;

  RETURN jsonb_build_object('status', 'error', 'message', 'Invalid action');
END;
$$;

REVOKE ALL ON FUNCTION public.manage_employee_break(TEXT, UUID, TEXT, public.day_of_week, TIME, TIME, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.manage_employee_break(TEXT, UUID, TEXT, public.day_of_week, TIME, TIME, UUID) TO authenticated;

-- ─── RPC: get_branches_for_management ────────────────────────
CREATE OR REPLACE FUNCTION public.get_branches_for_management(
  p_business_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
  v_branches JSONB;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.organization_members
  WHERE user_id = auth.uid() AND status = 'active'
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not authorized');
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'id', b.id,
      'name', b.name,
      'address', b.address,
      'city', b.city,
      'country', b.country,
      'phone', b.phone,
      'email', b.email,
      'timezone', b.timezone,
      'is_active', b.is_active,
      'created_at', b.created_at
    )
    ORDER BY b.created_at
  ) INTO v_branches
  FROM public.branches b
  WHERE b.business_id = p_business_id
    AND b.organization_id = v_org_id;

  RETURN jsonb_build_object(
    'status', 'success',
    'branches', COALESCE(v_branches, '[]'::JSONB)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_branches_for_management(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_branches_for_management(UUID) TO authenticated;

-- ─── RPC: get_services_for_management ────────────────────────
CREATE OR REPLACE FUNCTION public.get_services_for_management(
  p_business_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
  v_services JSONB;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.organization_members
  WHERE user_id = auth.uid() AND status = 'active'
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not authorized');
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'id', s.id,
      'name', s.name,
      'description', s.description,
      'duration_minutes', s.duration_minutes,
      'price', s.price,
      'buffer_before_minutes', s.buffer_before_minutes,
      'buffer_after_minutes', s.buffer_after_minutes,
      'is_active', s.is_active,
      'color_hex', s.color_hex,
      'category', s.category
    )
    ORDER BY s.name
  ) INTO v_services
  FROM public.services s
  WHERE s.organization_id = v_org_id;

  RETURN jsonb_build_object(
    'status', 'success',
    'services', COALESCE(v_services, '[]'::JSONB)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_services_for_management(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_services_for_management(UUID) TO authenticated;

-- ─── RPC: get_employees_for_management ───────────────────────
CREATE OR REPLACE FUNCTION public.get_employees_for_management(
  p_business_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
  v_employees JSONB;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.organization_members
  WHERE user_id = auth.uid() AND status = 'active'
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not authorized');
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'id', e.id,
      'first_name', e.first_name,
      'last_name', e.last_name,
      'display_name', COALESCE(e.display_name, e.first_name || ' ' || e.last_name),
      'email', e.email,
      'phone', e.phone,
      'avatar_url', e.avatar_url,
      'title', e.title,
      'status', e.status,
      'is_bookable', e.is_bookable,
      'color', e.color,
      'created_at', e.created_at
    )
    ORDER BY e.first_name, e.last_name
  ) INTO v_employees
  FROM public.employees e
  WHERE e.business_id = p_business_id
    AND e.organization_id = v_org_id
    AND e.deleted_at IS NULL;

  RETURN jsonb_build_object(
    'status', 'success',
    'employees', COALESCE(v_employees, '[]'::JSONB)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_employees_for_management(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_employees_for_management(UUID) TO authenticated;
