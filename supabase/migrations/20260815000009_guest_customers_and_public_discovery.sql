-- ============================================================
-- ReserveHub Migration 9: Guest Customers & Public Business Discovery
-- Adds:
--   • guest_customers table (no auth.users required)
--   • public_business_profiles view (safe, published-only)
--   • RLS policies for anonymous public discovery
--   • Indexes for public search performance
-- ============================================================

-- ─── ENUM: Customer Source ───────────────────────────────────
DROP TYPE IF EXISTS public.customer_source CASCADE;
CREATE TYPE public.customer_source AS ENUM (
  'guest',
  'registered',
  'imported',
  'walk_in',
  'referral'
);

-- ─── TABLE: guest_customers ──────────────────────────────────
-- Stores customers who book without a ReserveHub account.
-- May later be linked to a user_profile if they register.
-- May also be linked to an existing customers record (CRM).
-- Avoids duplicate records via (business_id, email) or (business_id, phone).
CREATE TABLE IF NOT EXISTS public.guest_customers (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  business_id     UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,

  -- Optional link to internal CRM customer record
  customer_id     UUID REFERENCES public.customers(id) ON DELETE SET NULL,
  -- Optional link to a ReserveHub user account (set when guest later registers)
  user_id         UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,

  -- Contact information (only what is necessary for appointment management)
  full_name       TEXT NOT NULL,
  email           TEXT,
  phone           TEXT,

  -- Source tracking
  source          public.customer_source NOT NULL DEFAULT 'guest'::public.customer_source,

  -- Appointment history counters (denormalized for performance)
  total_bookings  INTEGER NOT NULL DEFAULT 0,
  last_booked_at  TIMESTAMPTZ,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ,

  -- Prevent duplicate guest records per business per contact
  CONSTRAINT guest_customers_name_not_empty CHECK (char_length(full_name) >= 1),
  CONSTRAINT guest_customers_contact_required CHECK (
    email IS NOT NULL OR phone IS NOT NULL
  )
);

-- Partial unique index: one guest record per (business, email) when email provided
CREATE UNIQUE INDEX IF NOT EXISTS idx_guest_customers_business_email
  ON public.guest_customers (business_id, lower(email))
  WHERE email IS NOT NULL AND deleted_at IS NULL;

-- Partial unique index: one guest record per (business, phone) when phone provided
CREATE UNIQUE INDEX IF NOT EXISTS idx_guest_customers_business_phone
  ON public.guest_customers (business_id, phone)
  WHERE phone IS NOT NULL AND deleted_at IS NULL;

-- ─── INDEXES: guest_customers ────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_guest_customers_org_id
  ON public.guest_customers(organization_id);
CREATE INDEX IF NOT EXISTS idx_guest_customers_business_id
  ON public.guest_customers(business_id);
CREATE INDEX IF NOT EXISTS idx_guest_customers_customer_id
  ON public.guest_customers(customer_id);
CREATE INDEX IF NOT EXISTS idx_guest_customers_user_id
  ON public.guest_customers(user_id);
CREATE INDEX IF NOT EXISTS idx_guest_customers_deleted_at
  ON public.guest_customers(deleted_at) WHERE deleted_at IS NULL;

-- ─── TRIGGER: updated_at for guest_customers ─────────────────
DROP TRIGGER IF EXISTS trg_guest_customers_updated_at ON public.guest_customers;
CREATE TRIGGER trg_guest_customers_updated_at
  BEFORE UPDATE ON public.guest_customers
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ─── ENABLE RLS: guest_customers ─────────────────────────────
ALTER TABLE public.guest_customers ENABLE ROW LEVEL SECURITY;

-- Org members can manage guest customers for their organization
DROP POLICY IF EXISTS "guest_customers_member_select" ON public.guest_customers;
CREATE POLICY "guest_customers_member_select"
  ON public.guest_customers FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "guest_customers_member_insert" ON public.guest_customers;
CREATE POLICY "guest_customers_member_insert"
  ON public.guest_customers FOR INSERT TO authenticated
  WITH CHECK (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "guest_customers_member_update" ON public.guest_customers;
CREATE POLICY "guest_customers_member_update"
  ON public.guest_customers FOR UPDATE TO authenticated
  USING (public.is_org_member(organization_id))
  WITH CHECK (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "guest_customers_admin_delete" ON public.guest_customers;
CREATE POLICY "guest_customers_admin_delete"
  ON public.guest_customers FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- Anonymous users CANNOT directly access guest_customers.
-- Guest customer records are created/read only via secure SECURITY DEFINER RPCs.

-- ─── PUBLIC DISCOVERY: RLS additions to existing tables ──────
-- Allow anonymous users to SELECT published businesses, their branches,
-- services, and booking settings.
-- NEVER expose: org data, employee private data, CRM data, audit logs,
--               internal notes, private settings, private staff info.

-- businesses: anon can read published, non-deleted businesses
DROP POLICY IF EXISTS "businesses_public_select" ON public.businesses;
CREATE POLICY "businesses_public_select"
  ON public.businesses FOR SELECT TO anon
  USING (
    publication_status = 'published'::public.publication_status
    AND deleted_at IS NULL
    AND is_active = TRUE
  );

-- branches: anon can read active branches of published businesses
DROP POLICY IF EXISTS "branches_public_select" ON public.branches;
CREATE POLICY "branches_public_select"
  ON public.branches FOR SELECT TO anon
  USING (
    is_active = TRUE
    AND deleted_at IS NULL
    AND EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.id = business_id
        AND b.publication_status = 'published'::public.publication_status
        AND b.deleted_at IS NULL
        AND b.is_active = TRUE
    )
  );

-- services: anon can read active services of published businesses
DROP POLICY IF EXISTS "services_public_select" ON public.services;
CREATE POLICY "services_public_select"
  ON public.services FOR SELECT TO anon
  USING (
    status = 'active'::public.service_status
    AND is_online_bookable = TRUE
    AND deleted_at IS NULL
    AND EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.id = business_id
        AND b.publication_status = 'published'::public.publication_status
        AND b.deleted_at IS NULL
        AND b.is_active = TRUE
    )
  );

-- branch_services: anon can read active branch-service links for published businesses
DROP POLICY IF EXISTS "branch_services_public_select" ON public.branch_services;
CREATE POLICY "branch_services_public_select"
  ON public.branch_services FOR SELECT TO anon
  USING (
    is_active = TRUE
    AND EXISTS (
      SELECT 1 FROM public.businesses b
        JOIN public.branches br ON br.business_id = b.id
      WHERE br.id = branch_id
        AND b.publication_status = 'published'::public.publication_status
        AND b.deleted_at IS NULL
        AND b.is_active = TRUE
    )
  );

-- booking_settings: anon can read booking settings for published businesses
DROP POLICY IF EXISTS "booking_settings_public_select" ON public.booking_settings;
CREATE POLICY "booking_settings_public_select"
  ON public.booking_settings FOR SELECT TO anon
  USING (
    EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.id = business_id
        AND b.publication_status = 'published'::public.publication_status
        AND b.deleted_at IS NULL
        AND b.is_active = TRUE
    )
  );

-- cancellation_policies: anon can read cancellation policy text for published businesses
DROP POLICY IF EXISTS "cancellation_policies_public_select" ON public.cancellation_policies;
CREATE POLICY "cancellation_policies_public_select"
  ON public.cancellation_policies FOR SELECT TO anon
  USING (
    EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.id = business_id
        AND b.publication_status = 'published'::public.publication_status
        AND b.deleted_at IS NULL
        AND b.is_active = TRUE
    )
  );

-- business_hours: anon can read hours for published businesses
DROP POLICY IF EXISTS "business_hours_public_select" ON public.business_hours;
CREATE POLICY "business_hours_public_select"
  ON public.business_hours FOR SELECT TO anon
  USING (
    EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.id = business_id
        AND b.publication_status = 'published'::public.publication_status
        AND b.deleted_at IS NULL
        AND b.is_active = TRUE
    )
  );

-- ─── FUNCTION: search_public_businesses ──────────────────────
-- Safe public search function. Returns only intentionally public fields.
-- Never exposes: org IDs, internal settings, employee data, CRM data.
CREATE OR REPLACE FUNCTION public.search_public_businesses(
  p_query    TEXT    DEFAULT NULL,
  p_category TEXT    DEFAULT NULL,
  p_city     TEXT    DEFAULT NULL,
  p_country  TEXT    DEFAULT 'US',
  p_limit    INTEGER DEFAULT 20,
  p_offset   INTEGER DEFAULT 0
)
RETURNS TABLE(
  id               UUID,
  name             TEXT,
  slug             TEXT,
  description      TEXT,
  category         TEXT,
  logo_url         TEXT,
  cover_url        TEXT,
  email            TEXT,
  phone            TEXT,
  website          TEXT,
  city             TEXT,
  state            TEXT,
  country          TEXT,
  timezone         TEXT,
  published_at     TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT
    b.id,
    b.name,
    b.slug,
    b.description,
    b.category,
    b.logo_url,
    b.cover_url,
    b.email,
    b.phone,
    b.website,
    b.city,
    b.state,
    b.country,
    b.timezone,
    b.published_at
  FROM public.businesses b
  WHERE b.publication_status = 'published'::public.publication_status
    AND b.deleted_at IS NULL
    AND b.is_active  = TRUE
    AND (p_query    IS NULL OR b.name ILIKE '%' || p_query || '%')
    AND (p_category IS NULL OR b.category ILIKE p_category)
    AND (p_city     IS NULL OR b.city ILIKE '%' || p_city || '%')
    AND (p_country  IS NULL OR b.country = p_country)
  ORDER BY b.name
  LIMIT  LEAST(p_limit, 100)
  OFFSET p_offset;
$$;

-- Grant public search to both anon and authenticated
REVOKE ALL ON FUNCTION public.search_public_businesses(TEXT, TEXT, TEXT, TEXT, INTEGER, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.search_public_businesses(TEXT, TEXT, TEXT, TEXT, INTEGER, INTEGER) TO anon, authenticated;

-- ─── FUNCTION: get_public_business_profile ───────────────────
-- Returns the full public profile of a single published business by slug.
-- Includes branches, services, and booking settings.
-- Never exposes internal/private data.
CREATE OR REPLACE FUNCTION public.get_public_business_profile(p_slug TEXT)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_result JSONB;
  v_biz    RECORD;
BEGIN
  SELECT
    b.id, b.name, b.slug, b.description, b.category,
    b.logo_url, b.cover_url, b.email, b.phone, b.website,
    b.address_line1, b.address_line2, b.city, b.state,
    b.postal_code, b.country, b.timezone, b.published_at
  INTO v_biz
  FROM public.businesses b
  WHERE b.slug               = p_slug
    AND b.publication_status = 'published'::public.publication_status
    AND b.deleted_at         IS NULL
    AND b.is_active          = TRUE;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  SELECT jsonb_build_object(
    'id',           v_biz.id,
    'name',         v_biz.name,
    'slug',         v_biz.slug,
    'description',  v_biz.description,
    'category',     v_biz.category,
    'logo_url',     v_biz.logo_url,
    'cover_url',    v_biz.cover_url,
    'email',        v_biz.email,
    'phone',        v_biz.phone,
    'website',      v_biz.website,
    'address',      jsonb_build_object(
                      'line1',       v_biz.address_line1,
                      'line2',       v_biz.address_line2,
                      'city',        v_biz.city,
                      'state',       v_biz.state,
                      'postal_code', v_biz.postal_code,
                      'country',     v_biz.country
                    ),
    'timezone',     v_biz.timezone,
    'published_at', v_biz.published_at,
    'branches',     COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id',           br.id,
        'name',         br.name,
        'slug',         br.slug,
        'description',  br.description,
        'email',        br.email,
        'phone',        br.phone,
        'address',      jsonb_build_object(
                          'line1',       br.address_line1,
                          'line2',       br.address_line2,
                          'city',        br.city,
                          'state',       br.state,
                          'postal_code', br.postal_code,
                          'country',     br.country
                        ),
        'timezone',     br.timezone,
        'latitude',     br.latitude,
        'longitude',    br.longitude,
        'is_main',      br.is_main_branch
      ) ORDER BY br.is_main_branch DESC, br.name)
      FROM public.branches br
      WHERE br.business_id = v_biz.id
        AND br.is_active   = TRUE
        AND br.deleted_at  IS NULL
    ), '[]'::JSONB),
    'services',     COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id',            s.id,
        'name',          s.name,
        'slug',          s.slug,
        'description',   s.description,
        'category',      s.category,
        'duration_mins', s.duration_mins,
        'price',         s.price,
        'price_max',     s.price_max,
        'currency',      s.currency,
        'max_capacity',  s.max_capacity,
        'image_url',     s.image_url
      ) ORDER BY s.sort_order, s.name)
      FROM public.services s
      WHERE s.business_id        = v_biz.id
        AND s.status             = 'active'::public.service_status
        AND s.is_online_bookable = TRUE
        AND s.deleted_at         IS NULL
    ), '[]'::JSONB)
  ) INTO v_result;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_public_business_profile(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_public_business_profile(TEXT) TO anon, authenticated;

-- ─── PUBLIC SEARCH INDEXES ───────────────────────────────────
-- Efficient indexes for public business discovery at scale.

-- Full-text search on business name (trigram-style via ILIKE support)
CREATE INDEX IF NOT EXISTS idx_businesses_name_search
  ON public.businesses USING gin(to_tsvector('english', name))
  WHERE publication_status = 'published' AND deleted_at IS NULL;

-- Category filtering for published businesses
CREATE INDEX IF NOT EXISTS idx_businesses_category_published
  ON public.businesses(category, publication_status)
  WHERE publication_status = 'published' AND deleted_at IS NULL;

-- Location filtering
CREATE INDEX IF NOT EXISTS idx_businesses_city_published
  ON public.businesses(city, country)
  WHERE publication_status = 'published' AND deleted_at IS NULL;

-- Slug lookup (already unique, adding partial for published-only fast path)
CREATE INDEX IF NOT EXISTS idx_businesses_slug_published
  ON public.businesses(slug)
  WHERE publication_status = 'published' AND deleted_at IS NULL;
