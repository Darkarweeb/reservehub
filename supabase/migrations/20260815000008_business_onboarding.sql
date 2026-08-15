-- ============================================================
-- ReserveHub Migration 8: Business Onboarding Schema
-- Adds:
--   • publication_status ENUM
--   • businesses.publication_status + published_at + published_by
--   • booking_settings table (per-business/branch)
--   • cancellation_policies table
--   • business_categories reference table
-- ============================================================

-- ─── ENUM: Publication Status ────────────────────────────────
DROP TYPE IF EXISTS public.publication_status CASCADE;
CREATE TYPE public.publication_status AS ENUM (
  'draft',
  'published',
  'unpublished',
  'suspended'
);

-- ─── ENUM: Booking Lead Time Unit ────────────────────────────
DROP TYPE IF EXISTS public.time_unit CASCADE;
CREATE TYPE public.time_unit AS ENUM (
  'minutes',
  'hours',
  'days',
  'weeks'
);

-- ─── ALTER: businesses — add publication columns ──────────────
-- A business must have an explicit publication state.
-- It is NOT publicly discoverable until intentionally published.
ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS publication_status public.publication_status
    NOT NULL DEFAULT 'draft'::public.publication_status,
  ADD COLUMN IF NOT EXISTS published_at   TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS published_by   UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS unpublished_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS unpublished_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL;

-- ─── TABLE: booking_settings ─────────────────────────────────
-- Per-business (and optionally per-branch) booking configuration.
CREATE TABLE IF NOT EXISTS public.booking_settings (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id             UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  business_id                 UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  branch_id                   UUID REFERENCES public.branches(id) ON DELETE CASCADE,

  -- Online booking toggle
  online_booking_enabled      BOOLEAN NOT NULL DEFAULT TRUE,

  -- Lead time: how far in advance a customer can book
  min_advance_booking_value   INTEGER NOT NULL DEFAULT 0,
  min_advance_booking_unit    public.time_unit NOT NULL DEFAULT 'minutes'::public.time_unit,
  max_advance_booking_value   INTEGER NOT NULL DEFAULT 3,
  max_advance_booking_unit    public.time_unit NOT NULL DEFAULT 'months'::public.time_unit,

  -- Slot configuration
  slot_duration_mins          INTEGER NOT NULL DEFAULT 15,
  slot_buffer_mins            INTEGER NOT NULL DEFAULT 0,

  -- Confirmation mode
  auto_confirm                BOOLEAN NOT NULL DEFAULT TRUE,
  requires_approval           BOOLEAN NOT NULL DEFAULT FALSE,

  -- Capacity
  max_concurrent_bookings     INTEGER,

  -- Customer-facing settings
  show_employee_selection     BOOLEAN NOT NULL DEFAULT TRUE,
  show_price                  BOOLEAN NOT NULL DEFAULT TRUE,
  allow_guest_booking         BOOLEAN NOT NULL DEFAULT TRUE,

  -- Reminder settings (foundation — delivery handled by notification system)
  send_confirmation           BOOLEAN NOT NULL DEFAULT TRUE,
  send_reminder               BOOLEAN NOT NULL DEFAULT TRUE,
  reminder_hours_before       INTEGER NOT NULL DEFAULT 24,

  -- Custom fields schema (JSONB array of field definitions)
  custom_fields_schema        JSONB NOT NULL DEFAULT '[]'::JSONB,

  created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT booking_settings_unique_business UNIQUE (business_id, branch_id),
  CONSTRAINT booking_settings_slot_positive CHECK (slot_duration_mins > 0),
  CONSTRAINT booking_settings_buffer_non_negative CHECK (slot_buffer_mins >= 0),
  CONSTRAINT booking_settings_reminder_positive CHECK (reminder_hours_before > 0),
  CONSTRAINT booking_settings_max_concurrent_positive
    CHECK (max_concurrent_bookings IS NULL OR max_concurrent_bookings > 0)
);

-- ─── TABLE: cancellation_policies ────────────────────────────
-- Business-configurable cancellation rules.
-- No financial penalties or refunds at this stage.
CREATE TABLE IF NOT EXISTS public.cancellation_policies (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id             UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  business_id                 UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  branch_id                   UUID REFERENCES public.branches(id) ON DELETE CASCADE,

  -- Toggle
  cancellation_enabled        BOOLEAN NOT NULL DEFAULT TRUE,

  -- Minimum notice before appointment start
  min_notice_value            INTEGER NOT NULL DEFAULT 24,
  min_notice_unit             public.time_unit NOT NULL DEFAULT 'hours'::public.time_unit,

  -- Window during which cancellation is allowed (NULL = no window restriction)
  cancellation_window_value   INTEGER,
  cancellation_window_unit    public.time_unit,

  -- Customer-facing policy text
  policy_text                 TEXT,

  -- Rescheduling
  rescheduling_enabled        BOOLEAN NOT NULL DEFAULT TRUE,
  min_reschedule_notice_value INTEGER NOT NULL DEFAULT 24,
  min_reschedule_notice_unit  public.time_unit NOT NULL DEFAULT 'hours'::public.time_unit,

  created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT cancellation_policies_unique_business UNIQUE (business_id, branch_id),
  CONSTRAINT cancellation_policies_min_notice_positive CHECK (min_notice_value >= 0),
  CONSTRAINT cancellation_policies_reschedule_notice_positive
    CHECK (min_reschedule_notice_value >= 0)
);

-- ─── TABLE: business_categories ──────────────────────────────
-- Reference table for business categories (used for discovery/filtering).
CREATE TABLE IF NOT EXISTS public.business_categories (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL UNIQUE,
  slug        TEXT NOT NULL UNIQUE,
  description TEXT,
  icon        TEXT,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT business_categories_slug_format CHECK (slug ~ '^[a-z0-9\-]+$')
);

-- ─── TRIGGERS: updated_at ────────────────────────────────────
DROP TRIGGER IF EXISTS trg_booking_settings_updated_at ON public.booking_settings;
CREATE TRIGGER trg_booking_settings_updated_at
  BEFORE UPDATE ON public.booking_settings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_cancellation_policies_updated_at ON public.cancellation_policies;
CREATE TRIGGER trg_cancellation_policies_updated_at
  BEFORE UPDATE ON public.cancellation_policies
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_business_categories_updated_at ON public.business_categories;
CREATE TRIGGER trg_business_categories_updated_at
  BEFORE UPDATE ON public.business_categories
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ─── INDEXES ─────────────────────────────────────────────────
-- businesses publication
CREATE INDEX IF NOT EXISTS idx_businesses_publication_status
  ON public.businesses(publication_status);
CREATE INDEX IF NOT EXISTS idx_businesses_published
  ON public.businesses(publication_status, deleted_at)
  WHERE publication_status = 'published' AND deleted_at IS NULL;

-- booking_settings
CREATE INDEX IF NOT EXISTS idx_booking_settings_business_id
  ON public.booking_settings(business_id);
CREATE INDEX IF NOT EXISTS idx_booking_settings_branch_id
  ON public.booking_settings(branch_id);
CREATE INDEX IF NOT EXISTS idx_booking_settings_org_id
  ON public.booking_settings(organization_id);

-- cancellation_policies
CREATE INDEX IF NOT EXISTS idx_cancellation_policies_business_id
  ON public.cancellation_policies(business_id);
CREATE INDEX IF NOT EXISTS idx_cancellation_policies_branch_id
  ON public.cancellation_policies(branch_id);
CREATE INDEX IF NOT EXISTS idx_cancellation_policies_org_id
  ON public.cancellation_policies(organization_id);

-- business_categories
CREATE INDEX IF NOT EXISTS idx_business_categories_slug
  ON public.business_categories(slug);
CREATE INDEX IF NOT EXISTS idx_business_categories_active
  ON public.business_categories(is_active, sort_order)
  WHERE is_active = TRUE;

-- ─── ENABLE RLS ──────────────────────────────────────────────
ALTER TABLE public.booking_settings      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cancellation_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_categories   ENABLE ROW LEVEL SECURITY;

-- ─── RLS: booking_settings ───────────────────────────────────
DROP POLICY IF EXISTS "booking_settings_member_select" ON public.booking_settings;
CREATE POLICY "booking_settings_member_select"
  ON public.booking_settings FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "booking_settings_admin_insert" ON public.booking_settings;
CREATE POLICY "booking_settings_admin_insert"
  ON public.booking_settings FOR INSERT TO authenticated
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "booking_settings_admin_update" ON public.booking_settings;
CREATE POLICY "booking_settings_admin_update"
  ON public.booking_settings FOR UPDATE TO authenticated
  USING (public.is_org_admin(organization_id))
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "booking_settings_admin_delete" ON public.booking_settings;
CREATE POLICY "booking_settings_admin_delete"
  ON public.booking_settings FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- Anonymous users can read booking settings for published businesses (via RPC only)
-- Direct anon SELECT is intentionally blocked; public access is via secure RPC.

-- ─── RLS: cancellation_policies ──────────────────────────────
DROP POLICY IF EXISTS "cancellation_policies_member_select" ON public.cancellation_policies;
CREATE POLICY "cancellation_policies_member_select"
  ON public.cancellation_policies FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "cancellation_policies_admin_insert" ON public.cancellation_policies;
CREATE POLICY "cancellation_policies_admin_insert"
  ON public.cancellation_policies FOR INSERT TO authenticated
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "cancellation_policies_admin_update" ON public.cancellation_policies;
CREATE POLICY "cancellation_policies_admin_update"
  ON public.cancellation_policies FOR UPDATE TO authenticated
  USING (public.is_org_admin(organization_id))
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "cancellation_policies_admin_delete" ON public.cancellation_policies;
CREATE POLICY "cancellation_policies_admin_delete"
  ON public.cancellation_policies FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- ─── RLS: business_categories ────────────────────────────────
-- Public read — categories are a reference table, not tenant data.
DROP POLICY IF EXISTS "business_categories_public_select" ON public.business_categories;
CREATE POLICY "business_categories_public_select"
  ON public.business_categories FOR SELECT TO anon, authenticated
  USING (is_active = TRUE);

-- Only service_role / superuser can manage categories (no app-layer write).
-- No INSERT/UPDATE/DELETE policies for authenticated users intentionally.

-- ─── SEED: business categories ───────────────────────────────
INSERT INTO public.business_categories (name, slug, sort_order) VALUES
  ('Hair Salon',        'hair-salon',        1),
  ('Barbershop',        'barbershop',        2),
  ('Nail Salon',        'nail-salon',        3),
  ('Spa & Wellness',    'spa-wellness',      4),
  ('Beauty Studio',     'beauty-studio',     5),
  ('Massage Therapy',   'massage-therapy',   6),
  ('Fitness & Gym',     'fitness-gym',       7),
  ('Personal Training', 'personal-training', 8),
  ('Yoga & Pilates',    'yoga-pilates',      9),
  ('Medical & Dental',  'medical-dental',    10),
  ('Veterinary',        'veterinary',        11),
  ('Tutoring',          'tutoring',          12),
  ('Photography',       'photography',       13),
  ('Consulting',        'consulting',        14),
  ('Other',             'other',             99)
ON CONFLICT (slug) DO NOTHING;
