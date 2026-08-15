-- ============================================================
-- ReserveHub Migration 6: Audit Foundation & Seed Data
-- audit_logs table, seed demo organization + owner user
-- ============================================================

-- ─── TABLE: audit_logs ───────────────────────────────────────
-- Immutable audit trail for all significant actions in the system.
-- Designed to be append-only (no UPDATE/DELETE policies).
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES public.organizations(id) ON DELETE SET NULL,
  actor_id        UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  actor_email     TEXT,
  action          TEXT NOT NULL,
  resource_type   TEXT NOT NULL,
  resource_id     UUID,
  old_values      JSONB,
  new_values      JSONB,
  ip_address      INET,
  user_agent      TEXT,
  metadata        JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT audit_logs_action_not_empty CHECK (char_length(action) > 0),
  CONSTRAINT audit_logs_resource_type_not_empty CHECK (char_length(resource_type) > 0)
);

-- ─── INDEXES: audit_logs ─────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_audit_logs_org_id ON public.audit_logs(organization_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor_id ON public.audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource ON public.audit_logs(resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(organization_id, created_at DESC);

-- ─── ENABLE RLS: audit_logs ──────────────────────────────────
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Org members can read their own audit logs
DROP POLICY IF EXISTS "audit_logs_member_select" ON public.audit_logs;
CREATE POLICY "audit_logs_member_select"
  ON public.audit_logs FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

-- Only the system (SECURITY DEFINER functions) can insert audit logs
-- No direct INSERT from application layer
DROP POLICY IF EXISTS "audit_logs_system_insert" ON public.audit_logs;
CREATE POLICY "audit_logs_system_insert"
  ON public.audit_logs FOR INSERT TO authenticated
  WITH CHECK (public.is_org_member(organization_id));

-- No UPDATE or DELETE on audit_logs (immutable by design)

-- ─── FUNCTION: create_audit_log ──────────────────────────────
-- Convenience function for creating audit log entries from triggers or services.
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

-- ─── FUNCTION: get_org_appointment_stats ─────────────────────
-- Returns appointment statistics for an organization (used by dashboard).
CREATE OR REPLACE FUNCTION public.get_org_appointment_stats(
  p_organization_id UUID,
  p_date_from       TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
  p_date_to         TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE(
  total_appointments    BIGINT,
  confirmed_count       BIGINT,
  completed_count       BIGINT,
  cancelled_count       BIGINT,
  no_show_count         BIGINT,
  total_revenue         NUMERIC
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  IF NOT public.is_org_member(p_organization_id) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT AS total_appointments,
    COUNT(*) FILTER (WHERE a.status = 'confirmed'::public.appointment_status)::BIGINT AS confirmed_count,
    COUNT(*) FILTER (WHERE a.status = 'completed'::public.appointment_status)::BIGINT AS completed_count,
    COUNT(*) FILTER (WHERE a.status = 'cancelled'::public.appointment_status)::BIGINT AS cancelled_count,
    COUNT(*) FILTER (WHERE a.status = 'no_show'::public.appointment_status)::BIGINT AS no_show_count,
    COALESCE(SUM(a.total_price) FILTER (WHERE a.status = 'completed'::public.appointment_status), 0)::NUMERIC AS total_revenue
  FROM public.appointments a
  WHERE a.organization_id = p_organization_id
    AND a.starts_at >= p_date_from
    AND a.starts_at <= p_date_to
    AND a.deleted_at IS NULL;
END;
$$;

-- ─── SEED DATA ───────────────────────────────────────────────
-- Creates a demo owner user and a demo organization for immediate testing.
DO $$
DECLARE
  v_owner_uuid UUID := gen_random_uuid();
  v_org_uuid   UUID := gen_random_uuid();
  v_biz_uuid   UUID := gen_random_uuid();
  v_branch_uuid UUID := gen_random_uuid();
  v_emp_uuid   UUID := gen_random_uuid();
  v_svc1_uuid  UUID := gen_random_uuid();
  v_svc2_uuid  UUID := gen_random_uuid();
  v_cal_uuid   UUID := gen_random_uuid();
  v_cust_uuid  UUID := gen_random_uuid();
BEGIN
  -- ── Auth user (owner) ──────────────────────────────────────
  INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_user_meta_data, raw_app_meta_data,
    is_sso_user, is_anonymous,
    confirmation_token, confirmation_sent_at,
    recovery_token, recovery_sent_at,
    email_change_token_new, email_change, email_change_sent_at,
    email_change_token_current, email_change_confirm_status,
    reauthentication_token, reauthentication_sent_at,
    phone, phone_change, phone_change_token, phone_change_sent_at
  ) VALUES (
    v_owner_uuid,
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'owner@reservehub.app',
    crypt('Reserve2026!', gen_salt('bf', 10)),
    NOW(), NOW(), NOW(),
    jsonb_build_object('full_name', 'Alex Rivera', 'timezone', 'America/New_York', 'locale', 'en'),
    jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
    FALSE, FALSE,
    '', NULL, '', NULL, '', '', NULL, '', 0, '', NULL,
    NULL, '', '', NULL
  )
  ON CONFLICT (id) DO NOTHING;

  -- ── Organization ──────────────────────────────────────────
  INSERT INTO public.organizations (
    id, name, slug, email, phone, country, timezone, locale, currency,
    status, subscription_plan, created_by
  ) VALUES (
    v_org_uuid,
    'ReserveHub Demo',
    'reservehub-demo',
    'owner@reservehub.app',
    '+1-555-000-0001',
    'US', 'America/New_York', 'en', 'USD',
    'active'::public.organization_status,
    'professional',
    v_owner_uuid
  )
  ON CONFLICT (slug) DO NOTHING;

  -- ── Organization membership (owner) ───────────────────────
  INSERT INTO public.organization_members (
    organization_id, user_id, role, status, accepted_at
  ) VALUES (
    v_org_uuid, v_owner_uuid,
    'owner'::public.membership_role,
    'active'::public.membership_status,
    NOW()
  )
  ON CONFLICT (organization_id, user_id) DO NOTHING;

  -- ── Business ──────────────────────────────────────────────
  INSERT INTO public.businesses (
    id, organization_id, name, slug, description, category,
    email, phone, country, timezone, locale, currency,
    is_active, created_by
  ) VALUES (
    v_biz_uuid, v_org_uuid,
    'Luxe Hair Studio',
    'luxe-hair-studio',
    'Premium hair salon offering cuts, color, and styling.',
    'Hair Salon',
    'hello@luxehair.com', '+1-555-000-0002',
    'US', 'America/New_York', 'en', 'USD',
    TRUE, v_owner_uuid
  )
  ON CONFLICT (organization_id, slug) DO NOTHING;

  -- ── Branch ────────────────────────────────────────────────
  INSERT INTO public.branches (
    id, organization_id, business_id, name, slug,
    address_line1, city, state, postal_code, country,
    timezone, is_main_branch, is_active, capacity, created_by
  ) VALUES (
    v_branch_uuid, v_org_uuid, v_biz_uuid,
    'Downtown Location',
    'downtown',
    '123 Main Street', 'New York', 'NY', '10001', 'US',
    'America/New_York', TRUE, TRUE, 10, v_owner_uuid
  )
  ON CONFLICT (business_id, slug) DO NOTHING;

  -- ── Employee ──────────────────────────────────────────────
  INSERT INTO public.employees (
    id, organization_id, business_id, branch_id, user_id,
    first_name, last_name, display_name, email, title,
    color, status, is_bookable, created_by
  ) VALUES (
    v_emp_uuid, v_org_uuid, v_biz_uuid, v_branch_uuid, v_owner_uuid,
    'Alex', 'Rivera', 'Alex R.',
    'owner@reservehub.app',
    'Senior Stylist',
    '#4F46E5',
    'active'::public.employee_status,
    TRUE, v_owner_uuid
  )
  ON CONFLICT (id) DO NOTHING;

  -- ── Services ──────────────────────────────────────────────
  INSERT INTO public.services (
    id, organization_id, business_id, name, slug, description,
    category, duration_mins, price, currency,
    max_capacity, is_online_bookable, status, sort_order, created_by
  ) VALUES
    (
      v_svc1_uuid, v_org_uuid, v_biz_uuid,
      'Haircut & Style', 'haircut-style',
      'Classic haircut with blow-dry and styling.',
      'Hair', 60, 75.00, 'USD', 1, TRUE,
      'active'::public.service_status, 1, v_owner_uuid
    ),
    (
      v_svc2_uuid, v_org_uuid, v_biz_uuid,
      'Color & Highlights', 'color-highlights',
      'Full color treatment with balayage highlights.',
      'Color', 120, 150.00, 'USD', 1, TRUE,
      'active'::public.service_status, 2, v_owner_uuid
    )
  ON CONFLICT (business_id, slug) DO NOTHING;

  -- ── Employee ↔ Services ───────────────────────────────────
  INSERT INTO public.employee_services (organization_id, employee_id, service_id, is_active)
  VALUES
    (v_org_uuid, v_emp_uuid, v_svc1_uuid, TRUE),
    (v_org_uuid, v_emp_uuid, v_svc2_uuid, TRUE)
  ON CONFLICT (employee_id, service_id) DO NOTHING;

  -- ── Branch ↔ Services ─────────────────────────────────────
  INSERT INTO public.branch_services (organization_id, branch_id, service_id, is_active)
  VALUES
    (v_org_uuid, v_branch_uuid, v_svc1_uuid, TRUE),
    (v_org_uuid, v_branch_uuid, v_svc2_uuid, TRUE)
  ON CONFLICT (branch_id, service_id) DO NOTHING;

  -- ── Calendar ──────────────────────────────────────────────
  INSERT INTO public.calendars (
    id, organization_id, business_id, branch_id, employee_id,
    calendar_type, name, timezone, is_active, created_by
  ) VALUES (
    v_cal_uuid, v_org_uuid, v_biz_uuid, v_branch_uuid, v_emp_uuid,
    'employee'::public.calendar_type,
    'Alex Rivera - Calendar',
    'America/New_York', TRUE, v_owner_uuid
  )
  ON CONFLICT (id) DO NOTHING;

  -- ── Business Hours (Mon-Fri 9am-6pm, Sat 10am-4pm) ───────
  INSERT INTO public.business_hours (
    organization_id, business_id, branch_id, day_of_week, is_open, open_time, close_time, timezone
  ) VALUES
    (v_org_uuid, v_biz_uuid, v_branch_uuid, 'monday'::public.day_of_week,    TRUE, '09:00', '18:00', 'America/New_York'),
    (v_org_uuid, v_biz_uuid, v_branch_uuid, 'tuesday'::public.day_of_week,   TRUE, '09:00', '18:00', 'America/New_York'),
    (v_org_uuid, v_biz_uuid, v_branch_uuid, 'wednesday'::public.day_of_week, TRUE, '09:00', '18:00', 'America/New_York'),
    (v_org_uuid, v_biz_uuid, v_branch_uuid, 'thursday'::public.day_of_week,  TRUE, '09:00', '18:00', 'America/New_York'),
    (v_org_uuid, v_biz_uuid, v_branch_uuid, 'friday'::public.day_of_week,    TRUE, '09:00', '18:00', 'America/New_York'),
    (v_org_uuid, v_biz_uuid, v_branch_uuid, 'saturday'::public.day_of_week,  TRUE, '10:00', '16:00', 'America/New_York'),
    (v_org_uuid, v_biz_uuid, v_branch_uuid, 'sunday'::public.day_of_week,    FALSE, NULL, NULL, 'America/New_York')
  ON CONFLICT DO NOTHING;

  -- ── Working Hours for employee ────────────────────────────
  INSERT INTO public.working_hours (
    organization_id, employee_id, branch_id, day_of_week, is_working, start_time, end_time, timezone
  ) VALUES
    (v_org_uuid, v_emp_uuid, v_branch_uuid, 'monday'::public.day_of_week,    TRUE, '09:00', '17:00', 'America/New_York'),
    (v_org_uuid, v_emp_uuid, v_branch_uuid, 'tuesday'::public.day_of_week,   TRUE, '09:00', '17:00', 'America/New_York'),
    (v_org_uuid, v_emp_uuid, v_branch_uuid, 'wednesday'::public.day_of_week, TRUE, '09:00', '17:00', 'America/New_York'),
    (v_org_uuid, v_emp_uuid, v_branch_uuid, 'thursday'::public.day_of_week,  TRUE, '09:00', '17:00', 'America/New_York'),
    (v_org_uuid, v_emp_uuid, v_branch_uuid, 'friday'::public.day_of_week,    TRUE, '09:00', '17:00', 'America/New_York'),
    (v_org_uuid, v_emp_uuid, v_branch_uuid, 'saturday'::public.day_of_week,  FALSE, NULL, NULL, 'America/New_York'),
    (v_org_uuid, v_emp_uuid, v_branch_uuid, 'sunday'::public.day_of_week,    FALSE, NULL, NULL, 'America/New_York')
  ON CONFLICT DO NOTHING;

  -- ── Demo Customer ─────────────────────────────────────────
  INSERT INTO public.customers (
    id, organization_id, first_name, last_name, email, phone,
    status, loyalty_points, total_visits, total_spent, created_by
  ) VALUES (
    v_cust_uuid, v_org_uuid,
    'Jordan', 'Smith',
    'jordan.smith@example.com', '+1-555-100-0001',
    'active'::public.customer_status,
    250, 5, 425.00, v_owner_uuid
  )
  ON CONFLICT (id) DO NOTHING;

  -- ── Demo Appointments ─────────────────────────────────────
  INSERT INTO public.appointments (
    id, organization_id, business_id, branch_id, customer_id, calendar_id,
    appointment_type, status, title,
    starts_at, ends_at, duration_mins, timezone,
    total_price, currency, booked_online, booking_source, created_by
  ) VALUES
    (
      gen_random_uuid(), v_org_uuid, v_biz_uuid, v_branch_uuid, v_cust_uuid, v_cal_uuid,
      'single'::public.appointment_type,
      'confirmed'::public.appointment_status,
      'Haircut & Style - Jordan Smith',
      NOW() + INTERVAL '1 day' + INTERVAL '10 hours',
      NOW() + INTERVAL '1 day' + INTERVAL '11 hours',
      60, 'America/New_York',
      75.00, 'USD', FALSE, 'staff', v_owner_uuid
    ),
    (
      gen_random_uuid(), v_org_uuid, v_biz_uuid, v_branch_uuid, v_cust_uuid, v_cal_uuid,
      'single'::public.appointment_type,
      'pending'::public.appointment_status,
      'Color & Highlights - Jordan Smith',
      NOW() + INTERVAL '3 days' + INTERVAL '14 hours',
      NOW() + INTERVAL '3 days' + INTERVAL '16 hours',
      120, 'America/New_York',
      150.00, 'USD', TRUE, 'online', v_owner_uuid
    )
  ON CONFLICT (id) DO NOTHING;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Seed data insertion failed: %', SQLERRM;
END $$;
