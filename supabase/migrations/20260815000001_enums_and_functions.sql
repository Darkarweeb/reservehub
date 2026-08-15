-- ============================================================
-- ReserveHub Migration 1: ENUM Types & Shared Utility Functions
-- ============================================================

-- ─── ENUM: Organization Status ───────────────────────────────
DROP TYPE IF EXISTS public.organization_status CASCADE;
CREATE TYPE public.organization_status AS ENUM (
  'active',
  'suspended',
  'cancelled',
  'pending_setup',
  'trial'
);

-- ─── ENUM: Membership Role ───────────────────────────────────
DROP TYPE IF EXISTS public.membership_role CASCADE;
CREATE TYPE public.membership_role AS ENUM (
  'owner',
  'admin',
  'manager',
  'staff',
  'receptionist',
  'viewer'
);

-- ─── ENUM: Membership Status ─────────────────────────────────
DROP TYPE IF EXISTS public.membership_status CASCADE;
CREATE TYPE public.membership_status AS ENUM (
  'active',
  'invited',
  'suspended',
  'removed'
);

-- ─── ENUM: Employee Status ───────────────────────────────────
DROP TYPE IF EXISTS public.employee_status CASCADE;
CREATE TYPE public.employee_status AS ENUM (
  'active',
  'inactive',
  'on_leave',
  'terminated'
);

-- ─── ENUM: Customer Status ───────────────────────────────────
DROP TYPE IF EXISTS public.customer_status CASCADE;
CREATE TYPE public.customer_status AS ENUM (
  'active',
  'inactive',
  'blocked',
  'vip'
);

-- ─── ENUM: Appointment Status ────────────────────────────────
DROP TYPE IF EXISTS public.appointment_status CASCADE;
CREATE TYPE public.appointment_status AS ENUM (
  'pending',
  'confirmed',
  'in_progress',
  'completed',
  'cancelled',
  'no_show',
  'rescheduled',
  'waitlisted'
);

-- ─── ENUM: Appointment Type ──────────────────────────────────
DROP TYPE IF EXISTS public.appointment_type CASCADE;
CREATE TYPE public.appointment_type AS ENUM (
  'single',
  'recurring',
  'group',
  'walk_in',
  'online',
  'resource_only'
);

-- ─── ENUM: Recurrence Frequency ──────────────────────────────
DROP TYPE IF EXISTS public.recurrence_frequency CASCADE;
CREATE TYPE public.recurrence_frequency AS ENUM (
  'daily',
  'weekly',
  'biweekly',
  'monthly',
  'custom'
);

-- ─── ENUM: Day of Week ────────────────────────────────────────
DROP TYPE IF EXISTS public.day_of_week CASCADE;
CREATE TYPE public.day_of_week AS ENUM (
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday'
);

-- ─── ENUM: Service Status ────────────────────────────────────
DROP TYPE IF EXISTS public.service_status CASCADE;
CREATE TYPE public.service_status AS ENUM (
  'active',
  'inactive',
  'archived'
);

-- ─── ENUM: Calendar Type ─────────────────────────────────────
DROP TYPE IF EXISTS public.calendar_type CASCADE;
CREATE TYPE public.calendar_type AS ENUM (
  'business',
  'branch',
  'employee',
  'resource'
);

-- ─── ENUM: Availability Type ─────────────────────────────────
DROP TYPE IF EXISTS public.availability_type CASCADE;
CREATE TYPE public.availability_type AS ENUM (
  'available',
  'unavailable',
  'break',
  'time_off',
  'holiday',
  'blocked'
);

-- ─── FUNCTION: update_updated_at_column ──────────────────────
-- Reusable trigger function to auto-update updated_at on any table
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- ─── FUNCTION: is_org_member ─────────────────────────────────
-- Stub: real implementation defined in migration 2 after organization_members is created.
CREATE OR REPLACE FUNCTION public.is_org_member(org_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT FALSE;
$$;

-- ─── FUNCTION: get_user_org_ids ──────────────────────────────
-- Stub: real implementation defined in migration 2 after organization_members is created.
CREATE OR REPLACE FUNCTION public.get_user_org_ids()
RETURNS UUID[]
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT ARRAY[]::UUID[];
$$;

-- ─── FUNCTION: is_org_admin ──────────────────────────────────
-- Stub: real implementation defined in migration 2 after organization_members is created.
CREATE OR REPLACE FUNCTION public.is_org_admin(org_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT FALSE;
$$;

-- ─── FUNCTION: handle_new_user ───────────────────────────────
-- Trigger: auto-create user_profiles row when a new auth.users row is inserted.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
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
