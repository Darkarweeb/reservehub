-- ============================================================
-- ReserveHub Migration 4: Scheduling Tables
-- business_hours, working_hours, employee_availability
-- ============================================================

-- ─── TABLE: business_hours ───────────────────────────────────
-- Default operating hours for a business or branch.
-- Supports branch-specific overrides.
CREATE TABLE IF NOT EXISTS public.business_hours (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  business_id     UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  branch_id       UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  day_of_week     public.day_of_week NOT NULL,
  is_open         BOOLEAN NOT NULL DEFAULT TRUE,
  open_time       TIME WITHOUT TIME ZONE,
  close_time      TIME WITHOUT TIME ZONE,
  timezone        TEXT NOT NULL DEFAULT 'UTC',
  effective_from  DATE,
  effective_until DATE,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT business_hours_time_valid CHECK (
    (is_open = FALSE) OR (open_time IS NOT NULL AND close_time IS NOT NULL AND open_time < close_time)
  ),
  CONSTRAINT business_hours_effective_dates CHECK (
    effective_from IS NULL OR effective_until IS NULL OR effective_from <= effective_until
  )
);

-- Unique: one record per (branch or business) per day per effective period
CREATE UNIQUE INDEX IF NOT EXISTS idx_business_hours_branch_day
  ON public.business_hours (branch_id, day_of_week)
  WHERE branch_id IS NOT NULL AND effective_from IS NULL AND effective_until IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_business_hours_business_day
  ON public.business_hours (business_id, day_of_week)
  WHERE branch_id IS NULL AND effective_from IS NULL AND effective_until IS NULL;

-- ─── TABLE: working_hours ────────────────────────────────────
-- Employee-specific working schedule. Overrides business_hours for that employee.
CREATE TABLE IF NOT EXISTS public.working_hours (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  employee_id     UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  branch_id       UUID REFERENCES public.branches(id) ON DELETE SET NULL,
  day_of_week     public.day_of_week NOT NULL,
  is_working      BOOLEAN NOT NULL DEFAULT TRUE,
  start_time      TIME WITHOUT TIME ZONE,
  end_time        TIME WITHOUT TIME ZONE,
  timezone        TEXT NOT NULL DEFAULT 'UTC',
  effective_from  DATE,
  effective_until DATE,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT working_hours_time_valid CHECK (
    (is_working = FALSE) OR (start_time IS NOT NULL AND end_time IS NOT NULL AND start_time < end_time)
  ),
  CONSTRAINT working_hours_effective_dates CHECK (
    effective_from IS NULL OR effective_until IS NULL OR effective_from <= effective_until
  )
);

-- Unique: one working-hours record per employee per day (when no effective dates)
CREATE UNIQUE INDEX IF NOT EXISTS idx_working_hours_employee_day
  ON public.working_hours (employee_id, day_of_week)
  WHERE effective_from IS NULL AND effective_until IS NULL;

-- ─── TABLE: employee_availability ────────────────────────────
-- Specific date-based availability overrides for employees.
-- Supports: time-off, holidays, breaks, blocked slots, special availability.
CREATE TABLE IF NOT EXISTS public.employee_availability (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  employee_id       UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  branch_id         UUID REFERENCES public.branches(id) ON DELETE SET NULL,
  availability_type public.availability_type NOT NULL DEFAULT 'unavailable'::public.availability_type,
  title             TEXT,
  description       TEXT,
  start_at          TIMESTAMPTZ NOT NULL,
  end_at            TIMESTAMPTZ NOT NULL,
  is_all_day        BOOLEAN NOT NULL DEFAULT FALSE,
  is_recurring      BOOLEAN NOT NULL DEFAULT FALSE,
  recurrence_rule   TEXT,
  recurrence_end_at TIMESTAMPTZ,
  approved_by       UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  approved_at       TIMESTAMPTZ,
  metadata          JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_by        UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at        TIMESTAMPTZ,

  CONSTRAINT employee_availability_dates_valid CHECK (start_at < end_at)
);

-- ─── TABLE: breaks ───────────────────────────────────────────
-- Scheduled breaks within a working day for an employee.
CREATE TABLE IF NOT EXISTS public.breaks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  employee_id     UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  working_hours_id UUID REFERENCES public.working_hours(id) ON DELETE CASCADE,
  name            TEXT NOT NULL DEFAULT 'Break',
  start_time      TIME WITHOUT TIME ZONE NOT NULL,
  end_time        TIME WITHOUT TIME ZONE NOT NULL,
  day_of_week     public.day_of_week,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT breaks_time_valid CHECK (start_time < end_time)
);

-- ─── TRIGGERS: updated_at ────────────────────────────────────
DROP TRIGGER IF EXISTS trg_business_hours_updated_at ON public.business_hours;
CREATE TRIGGER trg_business_hours_updated_at
  BEFORE UPDATE ON public.business_hours
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_working_hours_updated_at ON public.working_hours;
CREATE TRIGGER trg_working_hours_updated_at
  BEFORE UPDATE ON public.working_hours
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_employee_availability_updated_at ON public.employee_availability;
CREATE TRIGGER trg_employee_availability_updated_at
  BEFORE UPDATE ON public.employee_availability
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_breaks_updated_at ON public.breaks;
CREATE TRIGGER trg_breaks_updated_at
  BEFORE UPDATE ON public.breaks
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ─── INDEXES: business_hours ─────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_business_hours_org_id ON public.business_hours(organization_id);
CREATE INDEX IF NOT EXISTS idx_business_hours_business_id ON public.business_hours(business_id);
CREATE INDEX IF NOT EXISTS idx_business_hours_branch_id ON public.business_hours(branch_id);
CREATE INDEX IF NOT EXISTS idx_business_hours_day ON public.business_hours(business_id, day_of_week);

-- ─── INDEXES: working_hours ──────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_working_hours_org_id ON public.working_hours(organization_id);
CREATE INDEX IF NOT EXISTS idx_working_hours_employee_id ON public.working_hours(employee_id);
CREATE INDEX IF NOT EXISTS idx_working_hours_branch_id ON public.working_hours(branch_id);
CREATE INDEX IF NOT EXISTS idx_working_hours_day ON public.working_hours(employee_id, day_of_week);

-- ─── INDEXES: employee_availability ─────────────────────────
CREATE INDEX IF NOT EXISTS idx_employee_avail_org_id ON public.employee_availability(organization_id);
CREATE INDEX IF NOT EXISTS idx_employee_avail_employee_id ON public.employee_availability(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_avail_date_range ON public.employee_availability(employee_id, start_at, end_at);
CREATE INDEX IF NOT EXISTS idx_employee_avail_type ON public.employee_availability(employee_id, availability_type);
CREATE INDEX IF NOT EXISTS idx_employee_avail_deleted_at ON public.employee_availability(deleted_at) WHERE deleted_at IS NULL;

-- ─── INDEXES: breaks ─────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_breaks_employee_id ON public.breaks(employee_id);
CREATE INDEX IF NOT EXISTS idx_breaks_working_hours_id ON public.breaks(working_hours_id);

-- ─── ENABLE RLS ──────────────────────────────────────────────
ALTER TABLE public.business_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.working_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.breaks ENABLE ROW LEVEL SECURITY;

-- ─── RLS: business_hours ─────────────────────────────────────
DROP POLICY IF EXISTS "business_hours_member_select" ON public.business_hours;
CREATE POLICY "business_hours_member_select"
  ON public.business_hours FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "business_hours_admin_insert" ON public.business_hours;
CREATE POLICY "business_hours_admin_insert"
  ON public.business_hours FOR INSERT TO authenticated
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "business_hours_admin_update" ON public.business_hours;
CREATE POLICY "business_hours_admin_update"
  ON public.business_hours FOR UPDATE TO authenticated
  USING (public.is_org_admin(organization_id))
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "business_hours_admin_delete" ON public.business_hours;
CREATE POLICY "business_hours_admin_delete"
  ON public.business_hours FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- ─── RLS: working_hours ──────────────────────────────────────
DROP POLICY IF EXISTS "working_hours_member_select" ON public.working_hours;
CREATE POLICY "working_hours_member_select"
  ON public.working_hours FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "working_hours_admin_insert" ON public.working_hours;
CREATE POLICY "working_hours_admin_insert"
  ON public.working_hours FOR INSERT TO authenticated
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "working_hours_admin_update" ON public.working_hours;
CREATE POLICY "working_hours_admin_update"
  ON public.working_hours FOR UPDATE TO authenticated
  USING (public.is_org_admin(organization_id))
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "working_hours_admin_delete" ON public.working_hours;
CREATE POLICY "working_hours_admin_delete"
  ON public.working_hours FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- ─── RLS: employee_availability ──────────────────────────────
DROP POLICY IF EXISTS "employee_avail_member_select" ON public.employee_availability;
CREATE POLICY "employee_avail_member_select"
  ON public.employee_availability FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "employee_avail_member_insert" ON public.employee_availability;
CREATE POLICY "employee_avail_member_insert"
  ON public.employee_availability FOR INSERT TO authenticated
  WITH CHECK (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "employee_avail_member_update" ON public.employee_availability;
CREATE POLICY "employee_avail_member_update"
  ON public.employee_availability FOR UPDATE TO authenticated
  USING (public.is_org_member(organization_id))
  WITH CHECK (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "employee_avail_admin_delete" ON public.employee_availability;
CREATE POLICY "employee_avail_admin_delete"
  ON public.employee_availability FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- ─── RLS: breaks ─────────────────────────────────────────────
DROP POLICY IF EXISTS "breaks_member_select" ON public.breaks;
CREATE POLICY "breaks_member_select"
  ON public.breaks FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "breaks_admin_insert" ON public.breaks;
CREATE POLICY "breaks_admin_insert"
  ON public.breaks FOR INSERT TO authenticated
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "breaks_admin_update" ON public.breaks;
CREATE POLICY "breaks_admin_update"
  ON public.breaks FOR UPDATE TO authenticated
  USING (public.is_org_admin(organization_id))
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "breaks_admin_delete" ON public.breaks;
CREATE POLICY "breaks_admin_delete"
  ON public.breaks FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));
