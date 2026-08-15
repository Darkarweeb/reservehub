-- ============================================================
-- ReserveHub Migration 7: Security Hardening
-- Hardens all SECURITY DEFINER functions with:
--   • Explicit SET search_path = public, pg_temp
--   • Named parameters (p_org_id, p_user_id)
--   • Least-privilege REVOKE/GRANT
--   • No new DROP … CASCADE
-- ============================================================

-- ─── HARDEN: update_updated_at_column ────────────────────────
-- Trigger helper — no auth context needed, but lock search_path.
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- ─── HARDEN: is_org_member ───────────────────────────────────
-- Returns TRUE if the current authenticated user is an active
-- member of the given organization.
-- Parameter renamed to p_org_id for clarity.
-- Written in plpgsql to avoid parse-time table validation.
DROP FUNCTION IF EXISTS public.is_org_member(UUID);
CREATE OR REPLACE FUNCTION public.is_org_member(p_org_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_exists BOOLEAN := FALSE;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM public.organization_members om
    WHERE om.organization_id = p_org_id
      AND om.user_id         = auth.uid()
      AND om.status          = 'active'::public.membership_status
  ) INTO v_exists;
  RETURN v_exists;
EXCEPTION
  WHEN undefined_table THEN
    RETURN FALSE;
END;
$$;

-- ─── HARDEN: get_user_org_ids ────────────────────────────────
-- Returns all organization UUIDs the current user actively belongs to.
-- No parameters — operates on auth.uid() only.
CREATE OR REPLACE FUNCTION public.get_user_org_ids()
RETURNS UUID[]
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_ids UUID[];
BEGIN
  SELECT COALESCE(
    ARRAY_AGG(om.organization_id),
    ARRAY[]::UUID[]
  )
  FROM public.organization_members om
  WHERE om.user_id = auth.uid()
    AND om.status  = 'active'::public.membership_status
  INTO v_ids;
  RETURN COALESCE(v_ids, ARRAY[]::UUID[]);
EXCEPTION
  WHEN undefined_table THEN
    RETURN ARRAY[]::UUID[];
END;
$$;

-- ─── HARDEN: is_org_admin ────────────────────────────────────
-- Returns TRUE if the current user is an owner or admin of the
-- given organization.
-- Parameter renamed to p_org_id.
-- Written in plpgsql to avoid parse-time table validation.
DROP FUNCTION IF EXISTS public.is_org_admin(UUID);
CREATE OR REPLACE FUNCTION public.is_org_admin(p_org_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_exists BOOLEAN := FALSE;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM public.organization_members om
    WHERE om.organization_id = p_org_id
      AND om.user_id         = auth.uid()
      AND om.status          = 'active'::public.membership_status
      AND om.role IN (
        'owner'::public.membership_role,
        'admin'::public.membership_role
      )
  ) INTO v_exists;
  RETURN v_exists;
EXCEPTION
  WHEN undefined_table THEN
    RETURN FALSE;
END;
$$;

-- ─── HARDEN: handle_new_user ─────────────────────────────────
-- Trigger: auto-create user_profiles row on auth.users INSERT.
-- Locked search_path prevents search-path injection.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO public.user_profiles (
    id,
    email,
    full_name,
    avatar_url,
    phone,
    timezone,
    locale
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', NULL),
    COALESCE(NEW.raw_user_meta_data->>'phone', NULL),
    COALESCE(NEW.raw_user_meta_data->>'timezone', 'UTC'),
    COALESCE(NEW.raw_user_meta_data->>'locale', 'en')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- ─── HARDEN: create_audit_log ────────────────────────────────
-- Convenience function for audit log entries.
-- Locked search_path; named parameters already used.
CREATE OR REPLACE FUNCTION public.create_audit_log(
  p_organization_id UUID,
  p_actor_id        UUID,
  p_actor_email     TEXT,
  p_action          TEXT,
  p_resource_type   TEXT,
  p_resource_id     UUID,
  p_old_values      JSONB DEFAULT NULL,
  p_new_values      JSONB DEFAULT NULL,
  p_metadata        JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO public.audit_logs (
    organization_id,
    actor_id,
    actor_email,
    action,
    resource_type,
    resource_id,
    old_values,
    new_values,
    metadata
  ) VALUES (
    p_organization_id,
    p_actor_id,
    p_actor_email,
    p_action,
    p_resource_type,
    p_resource_id,
    p_old_values,
    p_new_values,
    p_metadata
  )
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$;

-- ─── HARDEN: get_org_appointment_stats ───────────────────────
-- Dashboard stats function — locked search_path.
CREATE OR REPLACE FUNCTION public.get_org_appointment_stats(
  p_organization_id UUID,
  p_date_from       TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
  p_date_to         TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE(
  total_appointments BIGINT,
  confirmed_count    BIGINT,
  completed_count    BIGINT,
  cancelled_count    BIGINT,
  no_show_count      BIGINT,
  total_revenue      NUMERIC
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NOT public.is_org_member(p_organization_id) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT,
    COUNT(*) FILTER (WHERE a.status = 'confirmed'::public.appointment_status)::BIGINT,
    COUNT(*) FILTER (WHERE a.status = 'completed'::public.appointment_status)::BIGINT,
    COUNT(*) FILTER (WHERE a.status = 'cancelled'::public.appointment_status)::BIGINT,
    COUNT(*) FILTER (WHERE a.status = 'no_show'::public.appointment_status)::BIGINT,
    COALESCE(
      SUM(a.total_price) FILTER (WHERE a.status = 'completed'::public.appointment_status),
      0
    )::NUMERIC
  FROM public.appointments a
  WHERE a.organization_id = p_organization_id
    AND a.starts_at       >= p_date_from
    AND a.starts_at       <= p_date_to
    AND a.deleted_at      IS NULL;
END;
$$;

-- ─── PRIVILEGE HARDENING ─────────────────────────────────────
-- Revoke PUBLIC execute on all SECURITY DEFINER functions.
-- Only authenticated role (and service_role) should call them.
-- anon role must NOT be able to call tenant-scoped functions directly.

REVOKE ALL ON FUNCTION public.is_org_member(UUID)              FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_user_org_ids()               FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_org_admin(UUID)               FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_org_appointment_stats(UUID, TIMESTAMPTZ, TIMESTAMPTZ) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_audit_log(UUID, UUID, TEXT, TEXT, TEXT, UUID, JSONB, JSONB, JSONB) FROM PUBLIC;

-- Grant only to authenticated (Supabase maps this to logged-in users)
GRANT EXECUTE ON FUNCTION public.is_org_member(UUID)              TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_org_ids()               TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_org_admin(UUID)               TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_org_appointment_stats(UUID, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_audit_log(UUID, UUID, TEXT, TEXT, TEXT, UUID, JSONB, JSONB, JSONB) TO authenticated;

-- update_updated_at_column is a trigger function — called by the DB engine, not by users.
REVOKE ALL ON FUNCTION public.update_updated_at_column() FROM PUBLIC;

-- handle_new_user is a trigger function — called by the DB engine only.
REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC;
