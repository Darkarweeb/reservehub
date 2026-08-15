-- ============================================================
-- ReserveHub Migration 2: Core Tenant Tables
-- organizations, user_profiles, organization_members,
-- businesses, branches
-- ============================================================

-- ─── TABLE: user_profiles ────────────────────────────────────
-- Public-schema mirror of auth.users. Created automatically via trigger.
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email           TEXT NOT NULL UNIQUE,
  full_name       TEXT NOT NULL DEFAULT '',
  avatar_url      TEXT,
  phone           TEXT,
  timezone        TEXT NOT NULL DEFAULT 'UTC',
  locale          TEXT NOT NULL DEFAULT 'en',
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  last_seen_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

-- ─── TABLE: organizations ────────────────────────────────────
-- Top-level tenant. Every piece of data belongs to an organization.
CREATE TABLE IF NOT EXISTS public.organizations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  slug            TEXT NOT NULL UNIQUE,
  logo_url        TEXT,
  website         TEXT,
  email           TEXT,
  phone           TEXT,
  country         TEXT NOT NULL DEFAULT 'US',
  timezone        TEXT NOT NULL DEFAULT 'UTC',
  locale          TEXT NOT NULL DEFAULT 'en',
  currency        TEXT NOT NULL DEFAULT 'USD',
  status          public.organization_status NOT NULL DEFAULT 'pending_setup'::public.organization_status,
  trial_ends_at   TIMESTAMPTZ,
  subscription_plan TEXT NOT NULL DEFAULT 'free',
  settings        JSONB NOT NULL DEFAULT '{}'::JSONB,
  metadata        JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_by      UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ,

  CONSTRAINT organizations_slug_format CHECK (slug ~ '^[a-z0-9\-]+$'),
  CONSTRAINT organizations_name_length CHECK (char_length(name) >= 2)
);

-- ─── TABLE: organization_members ─────────────────────────────
-- Links users to organizations with a role. Enforces tenant isolation.
CREATE TABLE IF NOT EXISTS public.organization_members (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  role            public.membership_role NOT NULL DEFAULT 'staff'::public.membership_role,
  status          public.membership_status NOT NULL DEFAULT 'invited'::public.membership_status,
  invited_by      UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  invited_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  accepted_at     TIMESTAMPTZ,
  permissions     JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT organization_members_unique UNIQUE (organization_id, user_id)
);

-- ─── TABLE: businesses ───────────────────────────────────────
-- A business belongs to an organization. One org can have many businesses.
CREATE TABLE IF NOT EXISTS public.businesses (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  slug            TEXT NOT NULL,
  description     TEXT,
  category        TEXT,
  logo_url        TEXT,
  cover_url       TEXT,
  email           TEXT,
  phone           TEXT,
  website         TEXT,
  address_line1   TEXT,
  address_line2   TEXT,
  city            TEXT,
  state           TEXT,
  postal_code     TEXT,
  country         TEXT NOT NULL DEFAULT 'US',
  timezone        TEXT NOT NULL DEFAULT 'UTC',
  locale          TEXT NOT NULL DEFAULT 'en',
  currency        TEXT NOT NULL DEFAULT 'USD',
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  settings        JSONB NOT NULL DEFAULT '{}'::JSONB,
  metadata        JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_by      UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ,

  CONSTRAINT businesses_slug_unique UNIQUE (organization_id, slug),
  CONSTRAINT businesses_name_length CHECK (char_length(name) >= 2)
);

-- ─── TABLE: branches ─────────────────────────────────────────
-- A branch is a physical or virtual location belonging to a business.
CREATE TABLE IF NOT EXISTS public.branches (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  business_id     UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  slug            TEXT NOT NULL,
  description     TEXT,
  email           TEXT,
  phone           TEXT,
  address_line1   TEXT,
  address_line2   TEXT,
  city            TEXT,
  state           TEXT,
  postal_code     TEXT,
  country         TEXT NOT NULL DEFAULT 'US',
  timezone        TEXT NOT NULL DEFAULT 'UTC',
  latitude        DECIMAL(10, 8),
  longitude       DECIMAL(11, 8),
  is_main_branch  BOOLEAN NOT NULL DEFAULT FALSE,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  capacity        INTEGER,
  settings        JSONB NOT NULL DEFAULT '{}'::JSONB,
  metadata        JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_by      UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ,

  CONSTRAINT branches_slug_unique UNIQUE (business_id, slug),
  CONSTRAINT branches_name_length CHECK (char_length(name) >= 2),
  CONSTRAINT branches_capacity_positive CHECK (capacity IS NULL OR capacity > 0),
  CONSTRAINT branches_latitude_range CHECK (latitude IS NULL OR (latitude >= -90 AND latitude <= 90)),
  CONSTRAINT branches_longitude_range CHECK (longitude IS NULL OR (longitude >= -180 AND longitude <= 180))
);

-- ─── TRIGGER: updated_at for user_profiles ───────────────────
DROP TRIGGER IF EXISTS trg_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER trg_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ─── TRIGGER: updated_at for organizations ───────────────────
DROP TRIGGER IF EXISTS trg_organizations_updated_at ON public.organizations;
CREATE TRIGGER trg_organizations_updated_at
  BEFORE UPDATE ON public.organizations
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ─── TRIGGER: updated_at for organization_members ────────────
DROP TRIGGER IF EXISTS trg_organization_members_updated_at ON public.organization_members;
CREATE TRIGGER trg_organization_members_updated_at
  BEFORE UPDATE ON public.organization_members
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ─── FUNCTION: is_org_member (real implementation) ───────────
-- Returns TRUE if the current user is an active member of the given organization.
-- Replaces the stub defined in migration 1.
CREATE OR REPLACE FUNCTION public.is_org_member(org_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.organization_members om
    WHERE om.organization_id = org_id
      AND om.user_id = auth.uid()
      AND om.status = 'active'::public.membership_status
  );
$$;

-- ─── FUNCTION: get_user_org_ids (real implementation) ────────
-- Returns all organization IDs the current user is an active member of.
-- Replaces the stub defined in migration 1.
CREATE OR REPLACE FUNCTION public.get_user_org_ids()
RETURNS UUID[]
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT ARRAY_AGG(om.organization_id)
  FROM public.organization_members om
  WHERE om.user_id = auth.uid()
    AND om.status = 'active'::public.membership_status;
$$;

-- ─── FUNCTION: is_org_admin (real implementation) ────────────
-- Returns TRUE if the current user is an owner or admin of the given organization.
-- Replaces the stub defined in migration 1.
CREATE OR REPLACE FUNCTION public.is_org_admin(org_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.organization_members om
    WHERE om.organization_id = org_id
      AND om.user_id = auth.uid()
      AND om.status = 'active'::public.membership_status
      AND om.role IN ('owner'::public.membership_role, 'admin'::public.membership_role)
  );
$$;

-- ─── TRIGGER: updated_at for businesses ──────────────────────
DROP TRIGGER IF EXISTS trg_businesses_updated_at ON public.businesses;
CREATE TRIGGER trg_businesses_updated_at
  BEFORE UPDATE ON public.businesses
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ─── TRIGGER: updated_at for branches ────────────────────────
DROP TRIGGER IF EXISTS trg_branches_updated_at ON public.branches;
CREATE TRIGGER trg_branches_updated_at
  BEFORE UPDATE ON public.branches
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ─── TRIGGER: auto-create user_profiles on auth signup ───────
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─── INDEXES: user_profiles ──────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_active ON public.user_profiles(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_user_profiles_deleted_at ON public.user_profiles(deleted_at) WHERE deleted_at IS NULL;

-- ─── INDEXES: organizations ──────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_organizations_slug ON public.organizations(slug);
CREATE INDEX IF NOT EXISTS idx_organizations_status ON public.organizations(status);
CREATE INDEX IF NOT EXISTS idx_organizations_created_by ON public.organizations(created_by);
CREATE INDEX IF NOT EXISTS idx_organizations_deleted_at ON public.organizations(deleted_at) WHERE deleted_at IS NULL;

-- ─── INDEXES: organization_members ───────────────────────────
CREATE INDEX IF NOT EXISTS idx_org_members_org_id ON public.organization_members(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_members_user_id ON public.organization_members(user_id);
CREATE INDEX IF NOT EXISTS idx_org_members_status ON public.organization_members(organization_id, status);
CREATE INDEX IF NOT EXISTS idx_org_members_role ON public.organization_members(organization_id, role);

-- ─── INDEXES: businesses ─────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_businesses_org_id ON public.businesses(organization_id);
CREATE INDEX IF NOT EXISTS idx_businesses_slug ON public.businesses(organization_id, slug);
CREATE INDEX IF NOT EXISTS idx_businesses_is_active ON public.businesses(organization_id, is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_businesses_deleted_at ON public.businesses(deleted_at) WHERE deleted_at IS NULL;

-- ─── INDEXES: branches ───────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_branches_org_id ON public.branches(organization_id);
CREATE INDEX IF NOT EXISTS idx_branches_business_id ON public.branches(business_id);
CREATE INDEX IF NOT EXISTS idx_branches_is_active ON public.branches(business_id, is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_branches_deleted_at ON public.branches(deleted_at) WHERE deleted_at IS NULL;

-- ─── ENABLE RLS ──────────────────────────────────────────────
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;

-- ─── RLS: user_profiles ──────────────────────────────────────
DROP POLICY IF EXISTS "user_profiles_own_access" ON public.user_profiles;
CREATE POLICY "user_profiles_own_access"
  ON public.user_profiles
  FOR ALL
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- ─── RLS: organizations ──────────────────────────────────────
-- SELECT: any active member can read their organization
DROP POLICY IF EXISTS "organizations_member_select" ON public.organizations;
CREATE POLICY "organizations_member_select"
  ON public.organizations
  FOR SELECT
  TO authenticated
  USING (public.is_org_member(id));

-- INSERT: authenticated users can create organizations
DROP POLICY IF EXISTS "organizations_create" ON public.organizations;
CREATE POLICY "organizations_create"
  ON public.organizations
  FOR INSERT
  TO authenticated
  WITH CHECK (created_by = auth.uid());

-- UPDATE: only org admins/owners can update
DROP POLICY IF EXISTS "organizations_admin_update" ON public.organizations;
CREATE POLICY "organizations_admin_update"
  ON public.organizations
  FOR UPDATE
  TO authenticated
  USING (public.is_org_admin(id))
  WITH CHECK (public.is_org_admin(id));

-- DELETE: only org owners can soft-delete (set deleted_at)
DROP POLICY IF EXISTS "organizations_owner_delete" ON public.organizations;
CREATE POLICY "organizations_owner_delete"
  ON public.organizations
  FOR DELETE
  TO authenticated
  USING (public.is_org_admin(id));

-- ─── RLS: organization_members ───────────────────────────────
-- SELECT: members can see other members of their organizations
DROP POLICY IF EXISTS "org_members_select" ON public.organization_members;
CREATE POLICY "org_members_select"
  ON public.organization_members
  FOR SELECT
  TO authenticated
  USING (public.is_org_member(organization_id));

-- INSERT: org admins can invite new members
DROP POLICY IF EXISTS "org_members_insert" ON public.organization_members;
CREATE POLICY "org_members_insert"
  ON public.organization_members
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_org_admin(organization_id));

-- UPDATE: org admins can update membership; users can update their own record
DROP POLICY IF EXISTS "org_members_update" ON public.organization_members;
CREATE POLICY "org_members_update"
  ON public.organization_members
  FOR UPDATE
  TO authenticated
  USING (public.is_org_admin(organization_id) OR user_id = auth.uid())
  WITH CHECK (public.is_org_admin(organization_id) OR user_id = auth.uid());

-- DELETE: org admins can remove members
DROP POLICY IF EXISTS "org_members_delete" ON public.organization_members;
CREATE POLICY "org_members_delete"
  ON public.organization_members
  FOR DELETE
  TO authenticated
  USING (public.is_org_admin(organization_id));

-- ─── RLS: businesses ─────────────────────────────────────────
DROP POLICY IF EXISTS "businesses_member_select" ON public.businesses;
CREATE POLICY "businesses_member_select"
  ON public.businesses
  FOR SELECT
  TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "businesses_admin_insert" ON public.businesses;
CREATE POLICY "businesses_admin_insert"
  ON public.businesses
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "businesses_admin_update" ON public.businesses;
CREATE POLICY "businesses_admin_update"
  ON public.businesses
  FOR UPDATE
  TO authenticated
  USING (public.is_org_admin(organization_id))
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "businesses_admin_delete" ON public.businesses;
CREATE POLICY "businesses_admin_delete"
  ON public.businesses
  FOR DELETE
  TO authenticated
  USING (public.is_org_admin(organization_id));

-- ─── RLS: branches ───────────────────────────────────────────
DROP POLICY IF EXISTS "branches_member_select" ON public.branches;
CREATE POLICY "branches_member_select"
  ON public.branches
  FOR SELECT
  TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "branches_admin_insert" ON public.branches;
CREATE POLICY "branches_admin_insert"
  ON public.branches
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "branches_admin_update" ON public.branches;
CREATE POLICY "branches_admin_update"
  ON public.branches
  FOR UPDATE
  TO authenticated
  USING (public.is_org_admin(organization_id))
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "branches_admin_delete" ON public.branches;
CREATE POLICY "branches_admin_delete"
  ON public.branches
  FOR DELETE
  TO authenticated
  USING (public.is_org_admin(organization_id));
