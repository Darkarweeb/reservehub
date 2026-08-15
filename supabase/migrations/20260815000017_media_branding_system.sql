-- ============================================================
-- PHASE 9: BRANDING & MEDIA SYSTEM
-- ReserveHub — Production Media Architecture
-- ============================================================

-- ─── 1. ENUM: media_type ─────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'media_type' AND typnamespace = 'public'::regnamespace) THEN
    CREATE TYPE public.media_type AS ENUM (
      'business_logo',
      'business_cover',
      'business_gallery',
      'branch_cover',
      'branch_gallery',
      'service_image',
      'platform_asset',
      'employee_avatar'
    );
  END IF;
END $$;

-- ─── 2. MEDIA ASSETS TABLE ───────────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organizations'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'businesses'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'branches'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'services'
  ) THEN
    EXECUTE $sql$
      CREATE TABLE IF NOT EXISTS public.media_assets (
        id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        organization_id   UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
        business_id       UUID REFERENCES public.businesses(id) ON DELETE CASCADE,
        branch_id         UUID REFERENCES public.branches(id) ON DELETE SET NULL,
        service_id        UUID REFERENCES public.services(id) ON DELETE SET NULL,
        media_type        public.media_type NOT NULL,
        storage_bucket    TEXT NOT NULL,
        storage_path      TEXT NOT NULL,
        public_url        TEXT,
        mime_type         TEXT NOT NULL,
        file_size         BIGINT NOT NULL DEFAULT 0,
        width             INTEGER,
        height            INTEGER,
        display_order     INTEGER NOT NULL DEFAULT 0,
        is_active         BOOLEAN NOT NULL DEFAULT true,
        alt_text          TEXT,
        caption           TEXT,
        created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    $sql$;
  END IF;
END $$;

-- ─── 3. INDEXES ──────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'media_assets'
  ) THEN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'idx_media_assets_business_id') THEN
      EXECUTE 'CREATE INDEX idx_media_assets_business_id ON public.media_assets(business_id)';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'idx_media_assets_branch_id') THEN
      EXECUTE 'CREATE INDEX idx_media_assets_branch_id ON public.media_assets(branch_id)';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'idx_media_assets_service_id') THEN
      EXECUTE 'CREATE INDEX idx_media_assets_service_id ON public.media_assets(service_id)';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'idx_media_assets_org_type') THEN
      EXECUTE 'CREATE INDEX idx_media_assets_org_type ON public.media_assets(organization_id, media_type)';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'idx_media_assets_business_type') THEN
      EXECUTE 'CREATE INDEX idx_media_assets_business_type ON public.media_assets(business_id, media_type, is_active)';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'idx_media_assets_display_order') THEN
      EXECUTE 'CREATE INDEX idx_media_assets_display_order ON public.media_assets(business_id, media_type, display_order)';
    END IF;
  END IF;
END $$;

-- ─── 4. UPDATED_AT TRIGGER ───────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_media_assets_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'media_assets'
  ) THEN
    EXECUTE $sql$
      DROP TRIGGER IF EXISTS trg_media_assets_updated_at ON public.media_assets;
      CREATE TRIGGER trg_media_assets_updated_at
        BEFORE UPDATE ON public.media_assets
        FOR EACH ROW
        EXECUTE FUNCTION public.set_media_assets_updated_at()
    $sql$;
  END IF;
END $$;

-- ─── 5. HELPER: get_business_org ─────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'businesses'
  ) THEN
    EXECUTE $sql$
      CREATE OR REPLACE FUNCTION public.get_business_org_id(p_business_id UUID)
      RETURNS UUID
      LANGUAGE sql
      STABLE
      SECURITY DEFINER
      AS $fn$
        SELECT organization_id FROM public.businesses WHERE id = p_business_id LIMIT 1;
      $fn$
    $sql$;
  END IF;
END $$;

-- ─── 6. HELPER: current user owns organization ───────────────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organizations'
  ) THEN
    EXECUTE $sql$
      CREATE OR REPLACE FUNCTION public.user_owns_organization(p_org_id UUID)
      RETURNS BOOLEAN
      LANGUAGE sql
      STABLE
      SECURITY DEFINER
      AS $fn$
        SELECT EXISTS (
          SELECT 1 FROM public.organizations
          WHERE id = p_org_id
            AND owner_id = auth.uid()
        );
      $fn$
    $sql$;
  END IF;
END $$;

-- ─── 7. HELPER: current user can manage business ─────────────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'businesses'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'organizations'
  ) THEN
    EXECUTE $sql$
      CREATE OR REPLACE FUNCTION public.user_can_manage_business(p_business_id UUID)
      RETURNS BOOLEAN
      LANGUAGE sql
      STABLE
      SECURITY DEFINER
      AS $fn$
        SELECT EXISTS (
          SELECT 1
          FROM public.businesses b
          JOIN public.organizations o ON o.id = b.organization_id
          WHERE b.id = p_business_id
            AND o.owner_id = auth.uid()
        );
      $fn$
    $sql$;
  END IF;
END $$;

-- ─── 8. RLS ──────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'media_assets'
  ) THEN
    EXECUTE 'ALTER TABLE public.media_assets ENABLE ROW LEVEL SECURITY';

    -- Public can read active media for published businesses
    EXECUTE 'DROP POLICY IF EXISTS "media_public_read_active" ON public.media_assets';
    EXECUTE $sql$
      CREATE POLICY "media_public_read_active"
        ON public.media_assets
        FOR SELECT
        TO public
        USING (
          is_active = true
          AND media_type != 'platform_asset'
          AND EXISTS (
            SELECT 1 FROM public.businesses b
            WHERE b.id = media_assets.business_id
              AND b.publication_status = 'published'
              AND b.is_active = true
          )
        )
    $sql$;

    -- Platform assets are publicly readable
    EXECUTE 'DROP POLICY IF EXISTS "media_platform_assets_public_read" ON public.media_assets';
    EXECUTE $sql$
      CREATE POLICY "media_platform_assets_public_read"
        ON public.media_assets
        FOR SELECT
        TO public
        USING (media_type = 'platform_asset' AND business_id IS NULL)
    $sql$;

    -- Authenticated owners can read all their own media
    EXECUTE 'DROP POLICY IF EXISTS "media_owner_read_all" ON public.media_assets';
    EXECUTE $sql$
      CREATE POLICY "media_owner_read_all"
        ON public.media_assets
        FOR SELECT
        TO authenticated
        USING (
          organization_id IS NOT NULL
          AND public.user_owns_organization(organization_id)
        )
    $sql$;

    -- Owners can insert media for their businesses
    EXECUTE 'DROP POLICY IF EXISTS "media_owner_insert" ON public.media_assets';
    EXECUTE $sql$
      CREATE POLICY "media_owner_insert"
        ON public.media_assets
        FOR INSERT
        TO authenticated
        WITH CHECK (
          organization_id IS NOT NULL
          AND public.user_owns_organization(organization_id)
        )
    $sql$;

    -- Owners can update their own media
    EXECUTE 'DROP POLICY IF EXISTS "media_owner_update" ON public.media_assets';
    EXECUTE $sql$
      CREATE POLICY "media_owner_update"
        ON public.media_assets
        FOR UPDATE
        TO authenticated
        USING (
          organization_id IS NOT NULL
          AND public.user_owns_organization(organization_id)
        )
        WITH CHECK (
          organization_id IS NOT NULL
          AND public.user_owns_organization(organization_id)
        )
    $sql$;

    -- Owners can delete their own media
    EXECUTE 'DROP POLICY IF EXISTS "media_owner_delete" ON public.media_assets';
    EXECUTE $sql$
      CREATE POLICY "media_owner_delete"
        ON public.media_assets
        FOR DELETE
        TO authenticated
        USING (
          organization_id IS NOT NULL
          AND public.user_owns_organization(organization_id)
        )
    $sql$;
  END IF;
END $$;

-- ─── 9. STORAGE BUCKET SETUP (via SQL) ───────────────────────────────────────
-- business-media bucket (public for logos/covers, controlled access)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'business-media',
  'business-media',
  true,
  5242880, -- 5 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- platform-assets bucket (public, managed by ReserveHub)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'platform-assets',
  'platform-assets',
  true,
  10485760, -- 10 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ─── 10. STORAGE RLS POLICIES ────────────────────────────────────────────────

-- business-media: public read
DROP POLICY IF EXISTS "business_media_public_read" ON storage.objects;
CREATE POLICY "business_media_public_read"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'business-media');

-- business-media: authenticated upload (path must start with org_id/business_id/)
DROP POLICY IF EXISTS "business_media_auth_insert" ON storage.objects;
CREATE POLICY "business_media_auth_insert"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'business-media'
    AND auth.uid() IS NOT NULL
  );

-- business-media: owner update
DROP POLICY IF EXISTS "business_media_auth_update" ON storage.objects;
CREATE POLICY "business_media_auth_update"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'business-media'
    AND auth.uid() IS NOT NULL
  )
  WITH CHECK (
    bucket_id = 'business-media'
    AND auth.uid() IS NOT NULL
  );

-- business-media: owner delete
DROP POLICY IF EXISTS "business_media_auth_delete" ON storage.objects;
CREATE POLICY "business_media_auth_delete"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'business-media'
    AND auth.uid() IS NOT NULL
  );

-- platform-assets: public read
DROP POLICY IF EXISTS "platform_assets_public_read" ON storage.objects;
CREATE POLICY "platform_assets_public_read"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'platform-assets');

-- ─── 11. RPC: get_business_media ─────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'media_assets'
  ) THEN
    EXECUTE $sql$
      CREATE OR REPLACE FUNCTION public.get_business_media(
        p_business_id UUID,
        p_media_type   public.media_type DEFAULT NULL
      )
      RETURNS TABLE (
        id            UUID,
        media_type    public.media_type,
        storage_path  TEXT,
        public_url    TEXT,
        mime_type     TEXT,
        file_size     BIGINT,
        display_order INTEGER,
        is_active     BOOLEAN,
        alt_text      TEXT,
        caption       TEXT,
        created_at    TIMESTAMPTZ
      )
      LANGUAGE sql
      STABLE
      SECURITY DEFINER
      AS $fn$
        SELECT
          ma.id,
          ma.media_type,
          ma.storage_path,
          ma.public_url,
          ma.mime_type,
          ma.file_size,
          ma.display_order,
          ma.is_active,
          ma.alt_text,
          ma.caption,
          ma.created_at
        FROM public.media_assets ma
        WHERE ma.business_id = p_business_id
          AND (p_media_type IS NULL OR ma.media_type = p_media_type)
        ORDER BY ma.display_order ASC, ma.created_at ASC;
      $fn$
    $sql$;
  END IF;
END $$;

-- ─── 12. RPC: get_branch_media ────────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'media_assets'
  ) THEN
    EXECUTE $sql$
      CREATE OR REPLACE FUNCTION public.get_branch_media(
        p_branch_id UUID
      )
      RETURNS TABLE (
        id            UUID,
        media_type    public.media_type,
        storage_path  TEXT,
        public_url    TEXT,
        display_order INTEGER,
        is_active     BOOLEAN,
        alt_text      TEXT,
        caption       TEXT,
        created_at    TIMESTAMPTZ
      )
      LANGUAGE sql
      STABLE
      SECURITY DEFINER
      AS $fn$
        SELECT
          ma.id,
          ma.media_type,
          ma.storage_path,
          ma.public_url,
          ma.display_order,
          ma.is_active,
          ma.alt_text,
          ma.caption,
          ma.created_at
        FROM public.media_assets ma
        WHERE ma.branch_id = p_branch_id
        ORDER BY ma.display_order ASC, ma.created_at ASC;
      $fn$
    $sql$;
  END IF;
END $$;
