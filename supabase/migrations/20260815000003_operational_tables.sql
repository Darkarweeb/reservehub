-- ============================================================
-- ReserveHub Migration 3: Operational Tables
-- employees, customers, services, calendars
-- ============================================================

-- ─── TABLE: employees ────────────────────────────────────────
-- An employee belongs to an organization and optionally to a specific branch.
-- An employee may also be a user_profile (linked via user_id).
CREATE TABLE IF NOT EXISTS public.employees (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id     UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  business_id         UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  branch_id           UUID REFERENCES public.branches(id) ON DELETE SET NULL,
  user_id             UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  first_name          TEXT NOT NULL,
  last_name           TEXT NOT NULL,
  display_name        TEXT,
  email               TEXT,
  phone               TEXT,
  avatar_url          TEXT,
  bio                 TEXT,
  title               TEXT,
  color               TEXT,
  status              public.employee_status NOT NULL DEFAULT 'active'::public.employee_status,
  is_bookable         BOOLEAN NOT NULL DEFAULT TRUE,
  booking_buffer_mins INTEGER NOT NULL DEFAULT 0,
  max_daily_bookings  INTEGER,
  commission_rate     DECIMAL(5, 4),
  hourly_rate         DECIMAL(10, 2),
  settings            JSONB NOT NULL DEFAULT '{}'::JSONB,
  metadata            JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_by          UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at          TIMESTAMPTZ,

  CONSTRAINT employees_commission_rate_range CHECK (commission_rate IS NULL OR (commission_rate >= 0 AND commission_rate <= 1)),
  CONSTRAINT employees_buffer_non_negative CHECK (booking_buffer_mins >= 0),
  CONSTRAINT employees_max_daily_positive CHECK (max_daily_bookings IS NULL OR max_daily_bookings > 0)
);

-- ─── TABLE: customers ────────────────────────────────────────
-- A customer belongs to an organization. May optionally be linked to a user_profile.
CREATE TABLE IF NOT EXISTS public.customers (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id     UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  user_id             UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  first_name          TEXT NOT NULL,
  last_name           TEXT NOT NULL,
  display_name        TEXT,
  email               TEXT,
  phone               TEXT,
  avatar_url          TEXT,
  date_of_birth       DATE,
  gender              TEXT,
  address_line1       TEXT,
  address_line2       TEXT,
  city                TEXT,
  state               TEXT,
  postal_code         TEXT,
  country             TEXT,
  timezone            TEXT NOT NULL DEFAULT 'UTC',
  locale              TEXT NOT NULL DEFAULT 'en',
  status              public.customer_status NOT NULL DEFAULT 'active'::public.customer_status,
  loyalty_points      INTEGER NOT NULL DEFAULT 0,
  total_visits        INTEGER NOT NULL DEFAULT 0,
  total_spent         DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  last_visit_at       TIMESTAMPTZ,
  notes               TEXT,
  tags                TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  referral_source     TEXT,
  referred_by         UUID REFERENCES public.customers(id) ON DELETE SET NULL,
  settings            JSONB NOT NULL DEFAULT '{}'::JSONB,
  metadata            JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_by          UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at          TIMESTAMPTZ,

  CONSTRAINT customers_loyalty_non_negative CHECK (loyalty_points >= 0),
  CONSTRAINT customers_total_visits_non_negative CHECK (total_visits >= 0),
  CONSTRAINT customers_total_spent_non_negative CHECK (total_spent >= 0)
);

-- ─── TABLE: services ─────────────────────────────────────────
-- Services offered by a business. Can be assigned to specific branches/employees.
CREATE TABLE IF NOT EXISTS public.services (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id     UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  business_id         UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  parent_id           UUID REFERENCES public.services(id) ON DELETE SET NULL,
  name                TEXT NOT NULL,
  slug                TEXT NOT NULL,
  description         TEXT,
  category            TEXT,
  color               TEXT,
  image_url           TEXT,
  duration_mins       INTEGER NOT NULL DEFAULT 60,
  buffer_before_mins  INTEGER NOT NULL DEFAULT 0,
  buffer_after_mins   INTEGER NOT NULL DEFAULT 0,
  price               DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  price_max           DECIMAL(10, 2),
  currency            TEXT NOT NULL DEFAULT 'USD',
  is_price_variable   BOOLEAN NOT NULL DEFAULT FALSE,
  max_capacity        INTEGER NOT NULL DEFAULT 1,
  min_capacity        INTEGER NOT NULL DEFAULT 1,
  requires_deposit    BOOLEAN NOT NULL DEFAULT FALSE,
  deposit_amount      DECIMAL(10, 2),
  deposit_percent     DECIMAL(5, 4),
  is_online_bookable  BOOLEAN NOT NULL DEFAULT TRUE,
  status              public.service_status NOT NULL DEFAULT 'active'::public.service_status,
  sort_order          INTEGER NOT NULL DEFAULT 0,
  settings            JSONB NOT NULL DEFAULT '{}'::JSONB,
  metadata            JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_by          UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at          TIMESTAMPTZ,

  CONSTRAINT services_slug_unique UNIQUE (business_id, slug),
  CONSTRAINT services_duration_positive CHECK (duration_mins > 0),
  CONSTRAINT services_buffer_non_negative CHECK (buffer_before_mins >= 0 AND buffer_after_mins >= 0),
  CONSTRAINT services_price_non_negative CHECK (price >= 0),
  CONSTRAINT services_capacity_valid CHECK (max_capacity >= min_capacity AND min_capacity >= 1),
  CONSTRAINT services_deposit_percent_range CHECK (deposit_percent IS NULL OR (deposit_percent > 0 AND deposit_percent <= 1))
);

-- ─── TABLE: employee_services ────────────────────────────────
-- Junction: which employees can perform which services
CREATE TABLE IF NOT EXISTS public.employee_services (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  employee_id     UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  service_id      UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
  price_override  DECIMAL(10, 2),
  duration_override_mins INTEGER,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT employee_services_unique UNIQUE (employee_id, service_id)
);

-- ─── TABLE: branch_services ──────────────────────────────────
-- Junction: which services are available at which branches
CREATE TABLE IF NOT EXISTS public.branch_services (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  branch_id       UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  service_id      UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT branch_services_unique UNIQUE (branch_id, service_id)
);

-- ─── TABLE: calendars ────────────────────────────────────────
-- A calendar aggregates availability for a business, branch, employee, or resource.
CREATE TABLE IF NOT EXISTS public.calendars (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  business_id     UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  branch_id       UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  employee_id     UUID REFERENCES public.employees(id) ON DELETE CASCADE,
  calendar_type   public.calendar_type NOT NULL DEFAULT 'employee'::public.calendar_type,
  name            TEXT NOT NULL,
  description     TEXT,
  color           TEXT,
  timezone        TEXT NOT NULL DEFAULT 'UTC',
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  settings        JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_by      UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

-- ─── TRIGGERS: updated_at ────────────────────────────────────
DROP TRIGGER IF EXISTS trg_employees_updated_at ON public.employees;
CREATE TRIGGER trg_employees_updated_at
  BEFORE UPDATE ON public.employees
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_customers_updated_at ON public.customers;
CREATE TRIGGER trg_customers_updated_at
  BEFORE UPDATE ON public.customers
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_services_updated_at ON public.services;
CREATE TRIGGER trg_services_updated_at
  BEFORE UPDATE ON public.services
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_employee_services_updated_at ON public.employee_services;
CREATE TRIGGER trg_employee_services_updated_at
  BEFORE UPDATE ON public.employee_services
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_branch_services_updated_at ON public.branch_services;
CREATE TRIGGER trg_branch_services_updated_at
  BEFORE UPDATE ON public.branch_services
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_calendars_updated_at ON public.calendars;
CREATE TRIGGER trg_calendars_updated_at
  BEFORE UPDATE ON public.calendars
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ─── INDEXES: employees ──────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_employees_org_id ON public.employees(organization_id);
CREATE INDEX IF NOT EXISTS idx_employees_business_id ON public.employees(business_id);
CREATE INDEX IF NOT EXISTS idx_employees_branch_id ON public.employees(branch_id);
CREATE INDEX IF NOT EXISTS idx_employees_user_id ON public.employees(user_id);
CREATE INDEX IF NOT EXISTS idx_employees_status ON public.employees(organization_id, status);
CREATE INDEX IF NOT EXISTS idx_employees_is_bookable ON public.employees(organization_id, is_bookable) WHERE is_bookable = TRUE;
CREATE INDEX IF NOT EXISTS idx_employees_deleted_at ON public.employees(deleted_at) WHERE deleted_at IS NULL;

-- ─── INDEXES: customers ──────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_customers_org_id ON public.customers(organization_id);
CREATE INDEX IF NOT EXISTS idx_customers_user_id ON public.customers(user_id);
CREATE INDEX IF NOT EXISTS idx_customers_email ON public.customers(organization_id, email);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON public.customers(organization_id, phone);
CREATE INDEX IF NOT EXISTS idx_customers_status ON public.customers(organization_id, status);
CREATE INDEX IF NOT EXISTS idx_customers_deleted_at ON public.customers(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_customers_tags ON public.customers USING GIN(tags);

-- ─── INDEXES: services ───────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_services_org_id ON public.services(organization_id);
CREATE INDEX IF NOT EXISTS idx_services_business_id ON public.services(business_id);
CREATE INDEX IF NOT EXISTS idx_services_status ON public.services(business_id, status);
CREATE INDEX IF NOT EXISTS idx_services_category ON public.services(business_id, category);
CREATE INDEX IF NOT EXISTS idx_services_deleted_at ON public.services(deleted_at) WHERE deleted_at IS NULL;

-- ─── INDEXES: employee_services ──────────────────────────────
CREATE INDEX IF NOT EXISTS idx_employee_services_employee_id ON public.employee_services(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_services_service_id ON public.employee_services(service_id);
CREATE INDEX IF NOT EXISTS idx_employee_services_org_id ON public.employee_services(organization_id);

-- ─── INDEXES: branch_services ────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_branch_services_branch_id ON public.branch_services(branch_id);
CREATE INDEX IF NOT EXISTS idx_branch_services_service_id ON public.branch_services(service_id);
CREATE INDEX IF NOT EXISTS idx_branch_services_org_id ON public.branch_services(organization_id);

-- ─── INDEXES: calendars ──────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_calendars_org_id ON public.calendars(organization_id);
CREATE INDEX IF NOT EXISTS idx_calendars_business_id ON public.calendars(business_id);
CREATE INDEX IF NOT EXISTS idx_calendars_branch_id ON public.calendars(branch_id);
CREATE INDEX IF NOT EXISTS idx_calendars_employee_id ON public.calendars(employee_id);
CREATE INDEX IF NOT EXISTS idx_calendars_deleted_at ON public.calendars(deleted_at) WHERE deleted_at IS NULL;

-- ─── ENABLE RLS ──────────────────────────────────────────────
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branch_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendars ENABLE ROW LEVEL SECURITY;

-- ─── RLS: employees ──────────────────────────────────────────
DROP POLICY IF EXISTS "employees_member_select" ON public.employees;
CREATE POLICY "employees_member_select"
  ON public.employees FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "employees_admin_insert" ON public.employees;
CREATE POLICY "employees_admin_insert"
  ON public.employees FOR INSERT TO authenticated
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "employees_admin_update" ON public.employees;
CREATE POLICY "employees_admin_update"
  ON public.employees FOR UPDATE TO authenticated
  USING (public.is_org_admin(organization_id))
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "employees_admin_delete" ON public.employees;
CREATE POLICY "employees_admin_delete"
  ON public.employees FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- ─── RLS: customers ──────────────────────────────────────────
DROP POLICY IF EXISTS "customers_member_select" ON public.customers;
CREATE POLICY "customers_member_select"
  ON public.customers FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "customers_member_insert" ON public.customers;
CREATE POLICY "customers_member_insert"
  ON public.customers FOR INSERT TO authenticated
  WITH CHECK (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "customers_member_update" ON public.customers;
CREATE POLICY "customers_member_update"
  ON public.customers FOR UPDATE TO authenticated
  USING (public.is_org_member(organization_id))
  WITH CHECK (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "customers_admin_delete" ON public.customers;
CREATE POLICY "customers_admin_delete"
  ON public.customers FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- ─── RLS: services ───────────────────────────────────────────
DROP POLICY IF EXISTS "services_member_select" ON public.services;
CREATE POLICY "services_member_select"
  ON public.services FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "services_admin_insert" ON public.services;
CREATE POLICY "services_admin_insert"
  ON public.services FOR INSERT TO authenticated
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "services_admin_update" ON public.services;
CREATE POLICY "services_admin_update"
  ON public.services FOR UPDATE TO authenticated
  USING (public.is_org_admin(organization_id))
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "services_admin_delete" ON public.services;
CREATE POLICY "services_admin_delete"
  ON public.services FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- ─── RLS: employee_services ──────────────────────────────────
DROP POLICY IF EXISTS "employee_services_member_select" ON public.employee_services;
CREATE POLICY "employee_services_member_select"
  ON public.employee_services FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "employee_services_admin_write" ON public.employee_services;
CREATE POLICY "employee_services_admin_write"
  ON public.employee_services FOR INSERT TO authenticated
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "employee_services_admin_update" ON public.employee_services;
CREATE POLICY "employee_services_admin_update"
  ON public.employee_services FOR UPDATE TO authenticated
  USING (public.is_org_admin(organization_id))
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "employee_services_admin_delete" ON public.employee_services;
CREATE POLICY "employee_services_admin_delete"
  ON public.employee_services FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- ─── RLS: branch_services ────────────────────────────────────
DROP POLICY IF EXISTS "branch_services_member_select" ON public.branch_services;
CREATE POLICY "branch_services_member_select"
  ON public.branch_services FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "branch_services_admin_insert" ON public.branch_services;
CREATE POLICY "branch_services_admin_insert"
  ON public.branch_services FOR INSERT TO authenticated
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "branch_services_admin_update" ON public.branch_services;
CREATE POLICY "branch_services_admin_update"
  ON public.branch_services FOR UPDATE TO authenticated
  USING (public.is_org_admin(organization_id))
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "branch_services_admin_delete" ON public.branch_services;
CREATE POLICY "branch_services_admin_delete"
  ON public.branch_services FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- ─── RLS: calendars ──────────────────────────────────────────
DROP POLICY IF EXISTS "calendars_member_select" ON public.calendars;
CREATE POLICY "calendars_member_select"
  ON public.calendars FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "calendars_admin_insert" ON public.calendars;
CREATE POLICY "calendars_admin_insert"
  ON public.calendars FOR INSERT TO authenticated
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "calendars_admin_update" ON public.calendars;
CREATE POLICY "calendars_admin_update"
  ON public.calendars FOR UPDATE TO authenticated
  USING (public.is_org_admin(organization_id))
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "calendars_admin_delete" ON public.calendars;
CREATE POLICY "calendars_admin_delete"
  ON public.calendars FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));
