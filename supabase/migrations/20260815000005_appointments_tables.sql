-- ============================================================
-- ReserveHub Migration 5: Appointments & Booking Engine Tables
-- appointments, appointment_services, appointment_employees,
-- appointment_notes, waiting_list, recurrence_rules
-- ============================================================

-- ─── TABLE: appointments ─────────────────────────────────────
-- Core booking record. Designed to support the full booking engine:
-- single, recurring, group, multi-service, multi-employee, capacity,
-- buffers, travel time, cancellations, rescheduling, no-shows.
CREATE TABLE IF NOT EXISTS public.appointments (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id         UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  business_id             UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  branch_id               UUID REFERENCES public.branches(id) ON DELETE SET NULL,
  customer_id             UUID REFERENCES public.customers(id) ON DELETE SET NULL,
  calendar_id             UUID REFERENCES public.calendars(id) ON DELETE SET NULL,

  -- Appointment identity
  appointment_type        public.appointment_type NOT NULL DEFAULT 'single'::public.appointment_type,
  status                  public.appointment_status NOT NULL DEFAULT 'pending'::public.appointment_status,
  title                   TEXT,
  notes                   TEXT,
  internal_notes          TEXT,

  -- Timing (timezone-aware)
  starts_at               TIMESTAMPTZ NOT NULL,
  ends_at                 TIMESTAMPTZ NOT NULL,
  duration_mins           INTEGER NOT NULL,
  buffer_before_mins      INTEGER NOT NULL DEFAULT 0,
  buffer_after_mins       INTEGER NOT NULL DEFAULT 0,
  travel_time_mins        INTEGER NOT NULL DEFAULT 0,
  timezone                TEXT NOT NULL DEFAULT 'UTC',

  -- Recurrence
  is_recurring            BOOLEAN NOT NULL DEFAULT FALSE,
  recurrence_parent_id    UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
  recurrence_frequency    public.recurrence_frequency,
  recurrence_interval     INTEGER,
  recurrence_days_of_week TEXT[],
  recurrence_end_at       TIMESTAMPTZ,
  recurrence_count        INTEGER,
  recurrence_rule         TEXT,

  -- Group booking
  is_group                BOOLEAN NOT NULL DEFAULT FALSE,
  group_capacity          INTEGER NOT NULL DEFAULT 1,
  group_booked_count      INTEGER NOT NULL DEFAULT 0,

  -- Pricing snapshot (captured at booking time)
  total_price             DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  deposit_amount          DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  currency                TEXT NOT NULL DEFAULT 'USD',

  -- Cancellation / rescheduling
  cancelled_at            TIMESTAMPTZ,
  cancelled_by            UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  cancellation_reason     TEXT,
  rescheduled_from_id     UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
  rescheduled_at          TIMESTAMPTZ,
  no_show_at              TIMESTAMPTZ,
  no_show_marked_by       UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,

  -- Confirmation
  confirmed_at            TIMESTAMPTZ,
  confirmed_by            UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  reminder_sent_at        TIMESTAMPTZ,

  -- Online booking
  booked_online           BOOLEAN NOT NULL DEFAULT FALSE,
  booking_source          TEXT,
  external_reference      TEXT,

  -- Metadata
  custom_fields           JSONB NOT NULL DEFAULT '{}'::JSONB,
  metadata                JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_by              UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at              TIMESTAMPTZ,

  -- Integrity constraints
  CONSTRAINT appointments_dates_valid CHECK (starts_at < ends_at),
  CONSTRAINT appointments_duration_positive CHECK (duration_mins > 0),
  CONSTRAINT appointments_buffer_non_negative CHECK (buffer_before_mins >= 0 AND buffer_after_mins >= 0),
  CONSTRAINT appointments_travel_non_negative CHECK (travel_time_mins >= 0),
  CONSTRAINT appointments_group_capacity_positive CHECK (group_capacity >= 1),
  CONSTRAINT appointments_group_booked_valid CHECK (group_booked_count >= 0 AND group_booked_count <= group_capacity),
  CONSTRAINT appointments_total_price_non_negative CHECK (total_price >= 0),
  CONSTRAINT appointments_deposit_non_negative CHECK (deposit_amount >= 0),
  CONSTRAINT appointments_recurrence_interval_positive CHECK (recurrence_interval IS NULL OR recurrence_interval > 0),
  CONSTRAINT appointments_recurrence_count_positive CHECK (recurrence_count IS NULL OR recurrence_count > 0)
);

-- ─── TABLE: appointment_services ─────────────────────────────
-- Which services are included in an appointment (supports multi-service bookings).
CREATE TABLE IF NOT EXISTS public.appointment_services (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  appointment_id  UUID NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
  service_id      UUID NOT NULL REFERENCES public.services(id) ON DELETE RESTRICT,
  service_name    TEXT NOT NULL,
  duration_mins   INTEGER NOT NULL,
  price           DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  currency        TEXT NOT NULL DEFAULT 'USD',
  sort_order      INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT appointment_services_duration_positive CHECK (duration_mins > 0),
  CONSTRAINT appointment_services_price_non_negative CHECK (price >= 0)
);

-- ─── TABLE: appointment_employees ────────────────────────────
-- Which employees are assigned to an appointment (supports multi-employee bookings).
CREATE TABLE IF NOT EXISTS public.appointment_employees (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  appointment_id  UUID NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
  employee_id     UUID NOT NULL REFERENCES public.employees(id) ON DELETE RESTRICT,
  service_id      UUID REFERENCES public.services(id) ON DELETE SET NULL,
  is_primary      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT appointment_employees_unique UNIQUE (appointment_id, employee_id)
);

-- ─── TABLE: appointment_notes ────────────────────────────────
-- Timestamped notes/comments on an appointment (audit trail for notes).
CREATE TABLE IF NOT EXISTS public.appointment_notes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  appointment_id  UUID NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
  author_id       UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  content         TEXT NOT NULL,
  is_internal     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

-- ─── TABLE: waiting_list ─────────────────────────────────────
-- Customers waiting for a slot. Supports group appointments and capacity management.
CREATE TABLE IF NOT EXISTS public.waiting_list (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  business_id     UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  branch_id       UUID REFERENCES public.branches(id) ON DELETE SET NULL,
  customer_id     UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  service_id      UUID REFERENCES public.services(id) ON DELETE SET NULL,
  employee_id     UUID REFERENCES public.employees(id) ON DELETE SET NULL,
  appointment_id  UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
  preferred_date  DATE,
  preferred_time_start TIME WITHOUT TIME ZONE,
  preferred_time_end   TIME WITHOUT TIME ZONE,
  party_size      INTEGER NOT NULL DEFAULT 1,
  priority        INTEGER NOT NULL DEFAULT 0,
  notes           TEXT,
  notified_at     TIMESTAMPTZ,
  expires_at      TIMESTAMPTZ,
  converted_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ,

  CONSTRAINT waiting_list_party_size_positive CHECK (party_size >= 1),
  CONSTRAINT waiting_list_priority_non_negative CHECK (priority >= 0)
);

-- ─── TRIGGERS: updated_at ────────────────────────────────────
DROP TRIGGER IF EXISTS trg_appointments_updated_at ON public.appointments;
CREATE TRIGGER trg_appointments_updated_at
  BEFORE UPDATE ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_appointment_services_updated_at ON public.appointment_services;
CREATE TRIGGER trg_appointment_services_updated_at
  BEFORE UPDATE ON public.appointment_services
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_appointment_employees_updated_at ON public.appointment_employees;
CREATE TRIGGER trg_appointment_employees_updated_at
  BEFORE UPDATE ON public.appointment_employees
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_appointment_notes_updated_at ON public.appointment_notes;
CREATE TRIGGER trg_appointment_notes_updated_at
  BEFORE UPDATE ON public.appointment_notes
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_waiting_list_updated_at ON public.waiting_list;
CREATE TRIGGER trg_waiting_list_updated_at
  BEFORE UPDATE ON public.waiting_list
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ─── INDEXES: appointments ───────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_appointments_org_id ON public.appointments(organization_id);
CREATE INDEX IF NOT EXISTS idx_appointments_business_id ON public.appointments(business_id);
CREATE INDEX IF NOT EXISTS idx_appointments_branch_id ON public.appointments(branch_id);
CREATE INDEX IF NOT EXISTS idx_appointments_customer_id ON public.appointments(customer_id);
CREATE INDEX IF NOT EXISTS idx_appointments_calendar_id ON public.appointments(calendar_id);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON public.appointments(organization_id, status);
CREATE INDEX IF NOT EXISTS idx_appointments_starts_at ON public.appointments(organization_id, starts_at);
CREATE INDEX IF NOT EXISTS idx_appointments_date_range ON public.appointments(branch_id, starts_at, ends_at);
CREATE INDEX IF NOT EXISTS idx_appointments_recurrence_parent ON public.appointments(recurrence_parent_id) WHERE recurrence_parent_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_appointments_deleted_at ON public.appointments(deleted_at) WHERE deleted_at IS NULL;
-- Partial index for active appointments (most common query)
CREATE INDEX IF NOT EXISTS idx_appointments_active ON public.appointments(organization_id, starts_at)
  WHERE deleted_at IS NULL AND status NOT IN ('cancelled', 'no_show');

-- ─── INDEXES: appointment_services ───────────────────────────
CREATE INDEX IF NOT EXISTS idx_appt_services_appointment_id ON public.appointment_services(appointment_id);
CREATE INDEX IF NOT EXISTS idx_appt_services_service_id ON public.appointment_services(service_id);
CREATE INDEX IF NOT EXISTS idx_appt_services_org_id ON public.appointment_services(organization_id);

-- ─── INDEXES: appointment_employees ──────────────────────────
CREATE INDEX IF NOT EXISTS idx_appt_employees_appointment_id ON public.appointment_employees(appointment_id);
CREATE INDEX IF NOT EXISTS idx_appt_employees_employee_id ON public.appointment_employees(employee_id);
CREATE INDEX IF NOT EXISTS idx_appt_employees_org_id ON public.appointment_employees(organization_id);

-- ─── INDEXES: appointment_notes ──────────────────────────────
CREATE INDEX IF NOT EXISTS idx_appt_notes_appointment_id ON public.appointment_notes(appointment_id);
CREATE INDEX IF NOT EXISTS idx_appt_notes_deleted_at ON public.appointment_notes(deleted_at) WHERE deleted_at IS NULL;

-- ─── INDEXES: waiting_list ───────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_waiting_list_org_id ON public.waiting_list(organization_id);
CREATE INDEX IF NOT EXISTS idx_waiting_list_customer_id ON public.waiting_list(customer_id);
CREATE INDEX IF NOT EXISTS idx_waiting_list_branch_id ON public.waiting_list(branch_id);
CREATE INDEX IF NOT EXISTS idx_waiting_list_service_id ON public.waiting_list(service_id);
CREATE INDEX IF NOT EXISTS idx_waiting_list_employee_id ON public.waiting_list(employee_id);
CREATE INDEX IF NOT EXISTS idx_waiting_list_preferred_date ON public.waiting_list(organization_id, preferred_date);
CREATE INDEX IF NOT EXISTS idx_waiting_list_deleted_at ON public.waiting_list(deleted_at) WHERE deleted_at IS NULL;

-- ─── ENABLE RLS ──────────────────────────────────────────────
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointment_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointment_employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointment_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.waiting_list ENABLE ROW LEVEL SECURITY;

-- ─── RLS: appointments ───────────────────────────────────────
DROP POLICY IF EXISTS "appointments_member_select" ON public.appointments;
CREATE POLICY "appointments_member_select"
  ON public.appointments FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "appointments_member_insert" ON public.appointments;
CREATE POLICY "appointments_member_insert"
  ON public.appointments FOR INSERT TO authenticated
  WITH CHECK (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "appointments_member_update" ON public.appointments;
CREATE POLICY "appointments_member_update"
  ON public.appointments FOR UPDATE TO authenticated
  USING (public.is_org_member(organization_id))
  WITH CHECK (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "appointments_admin_delete" ON public.appointments;
CREATE POLICY "appointments_admin_delete"
  ON public.appointments FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- ─── RLS: appointment_services ───────────────────────────────
DROP POLICY IF EXISTS "appt_services_member_select" ON public.appointment_services;
CREATE POLICY "appt_services_member_select"
  ON public.appointment_services FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "appt_services_member_insert" ON public.appointment_services;
CREATE POLICY "appt_services_member_insert"
  ON public.appointment_services FOR INSERT TO authenticated
  WITH CHECK (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "appt_services_member_update" ON public.appointment_services;
CREATE POLICY "appt_services_member_update"
  ON public.appointment_services FOR UPDATE TO authenticated
  USING (public.is_org_member(organization_id))
  WITH CHECK (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "appt_services_admin_delete" ON public.appointment_services;
CREATE POLICY "appt_services_admin_delete"
  ON public.appointment_services FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- ─── RLS: appointment_employees ──────────────────────────────
DROP POLICY IF EXISTS "appt_employees_member_select" ON public.appointment_employees;
CREATE POLICY "appt_employees_member_select"
  ON public.appointment_employees FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "appt_employees_member_insert" ON public.appointment_employees;
CREATE POLICY "appt_employees_member_insert"
  ON public.appointment_employees FOR INSERT TO authenticated
  WITH CHECK (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "appt_employees_member_update" ON public.appointment_employees;
CREATE POLICY "appt_employees_member_update"
  ON public.appointment_employees FOR UPDATE TO authenticated
  USING (public.is_org_member(organization_id))
  WITH CHECK (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "appt_employees_admin_delete" ON public.appointment_employees;
CREATE POLICY "appt_employees_admin_delete"
  ON public.appointment_employees FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- ─── RLS: appointment_notes ──────────────────────────────────
DROP POLICY IF EXISTS "appt_notes_member_select" ON public.appointment_notes;
CREATE POLICY "appt_notes_member_select"
  ON public.appointment_notes FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "appt_notes_member_insert" ON public.appointment_notes;
CREATE POLICY "appt_notes_member_insert"
  ON public.appointment_notes FOR INSERT TO authenticated
  WITH CHECK (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "appt_notes_author_update" ON public.appointment_notes;
CREATE POLICY "appt_notes_author_update"
  ON public.appointment_notes FOR UPDATE TO authenticated
  USING (public.is_org_member(organization_id) AND author_id = auth.uid())
  WITH CHECK (public.is_org_member(organization_id) AND author_id = auth.uid());

DROP POLICY IF EXISTS "appt_notes_admin_delete" ON public.appointment_notes;
CREATE POLICY "appt_notes_admin_delete"
  ON public.appointment_notes FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- ─── RLS: waiting_list ───────────────────────────────────────
DROP POLICY IF EXISTS "waiting_list_member_select" ON public.waiting_list;
CREATE POLICY "waiting_list_member_select"
  ON public.waiting_list FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "waiting_list_member_insert" ON public.waiting_list;
CREATE POLICY "waiting_list_member_insert"
  ON public.waiting_list FOR INSERT TO authenticated
  WITH CHECK (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "waiting_list_member_update" ON public.waiting_list;
CREATE POLICY "waiting_list_member_update"
  ON public.waiting_list FOR UPDATE TO authenticated
  USING (public.is_org_member(organization_id))
  WITH CHECK (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "waiting_list_admin_delete" ON public.waiting_list;
CREATE POLICY "waiting_list_admin_delete"
  ON public.waiting_list FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));
