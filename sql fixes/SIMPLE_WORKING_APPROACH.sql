-- SIMPLE WORKING APPROACH FOR REENTRY APP
-- This completely rebuilds the user creation system to be simple and reliable
-- Run this in your Supabase SQL Editor

-- ===========================================
-- STEP 1: CLEAN SLATE - REMOVE ALL COMPLEXITY
-- ===========================================

-- Drop all existing triggers and functions
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();
DROP FUNCTION IF EXISTS generate_simple_uuid();
DROP FUNCTION IF EXISTS safe_generate_uuid();

-- ===========================================
-- STEP 2: CREATE SIMPLE TABLES
-- ===========================================

-- Create a simple persons table
CREATE TABLE IF NOT EXISTS public.persons (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    email text,
    first_name text,
    last_name text,
    phone_number text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT persons_pkey PRIMARY KEY (id)
);

-- Create a simple user_profiles table
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id uuid NOT NULL,
    email text,
    name text,
    first_name text,
    last_name text,
    phone text,
    address text,
    person_id uuid,
    account_type text DEFAULT 'citizen',
    organizations text[] DEFAULT '{}',
    organization text,
    organization_address text,
    job_title text,
    supervisors_name text,
    supervisors_email text,
    services text[] DEFAULT '{}',
    user_code text,
    deleted boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT user_profiles_pkey PRIMARY KEY (id),
    CONSTRAINT user_profiles_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.persons(id)
);

-- Create organizations table
CREATE TABLE IF NOT EXISTS public.organizations (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    name text NOT NULL,
    address text,
    phone_number text,
    email text,
    website text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT organizations_pkey PRIMARY KEY (id),
    CONSTRAINT organizations_name_unique UNIQUE (name)
);

-- Create client_assignees table
CREATE TABLE IF NOT EXISTS public.client_assignees (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    client_id uuid NOT NULL,
    assignee_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT client_assignees_pkey PRIMARY KEY (id),
    CONSTRAINT client_assignees_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.users(id),
    CONSTRAINT client_assignees_assignee_id_fkey FOREIGN KEY (assignee_id) REFERENCES auth.users(id),
    CONSTRAINT client_assignees_unique UNIQUE (client_id, assignee_id)
);

-- ===========================================
-- STEP 3: SET UP SIMPLE RLS
-- ===========================================

-- Enable RLS
ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_assignees ENABLE ROW LEVEL SECURITY;

-- Simple policies
DROP POLICY IF EXISTS "Users can manage their own profile" ON public.user_profiles;
CREATE POLICY "Users can manage their own profile" ON public.user_profiles
    FOR ALL USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can manage their own person record" ON public.persons;
CREATE POLICY "Users can manage their own person record" ON public.persons
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND person_id = persons.id)
    );

DROP POLICY IF EXISTS "Anyone can view organizations" ON public.organizations;
CREATE POLICY "Anyone can view organizations" ON public.organizations
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert organizations" ON public.organizations;
CREATE POLICY "Authenticated users can insert organizations" ON public.organizations
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can manage their own assignments" ON public.client_assignees;
CREATE POLICY "Users can manage their own assignments" ON public.client_assignees
    FOR ALL USING (auth.uid() = client_id OR auth.uid() = assignee_id);

-- ===========================================
-- STEP 4: GRANT PERMISSIONS
-- ===========================================

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO service_role;

GRANT ALL ON public.persons TO authenticated;
GRANT ALL ON public.persons TO anon;
GRANT ALL ON public.persons TO service_role;

GRANT ALL ON public.user_profiles TO authenticated;
GRANT ALL ON public.user_profiles TO anon;
GRANT ALL ON public.user_profiles TO service_role;

GRANT ALL ON public.organizations TO authenticated;
GRANT ALL ON public.organizations TO anon;
GRANT ALL ON public.organizations TO service_role;

GRANT ALL ON public.client_assignees TO authenticated;
GRANT ALL ON public.client_assignees TO anon;
GRANT ALL ON public.client_assignees TO service_role;

-- ===========================================
-- STEP 5: VERIFICATION
-- ===========================================

-- Test that gen_random_uuid works
SELECT 'UUID Test:' as test_name, gen_random_uuid() as result;

-- Check tables exist
SELECT 'Tables Check:' as test_name, 
       CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'persons') 
            THEN 'persons: ✅' ELSE 'persons: ❌' END as persons_table,
       CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_profiles') 
            THEN 'user_profiles: ✅' ELSE 'user_profiles: ❌' END as user_profiles_table,
       CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'organizations') 
            THEN 'organizations: ✅' ELSE 'organizations: ❌' END as organizations_table,
       CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'client_assignees') 
            THEN 'client_assignees: ✅' ELSE 'client_assignees: ❌' END as client_assignees_table;

-- Final success message
SELECT '🎉 SIMPLE APPROACH READY! 🎉' as status,
       'No triggers, no complex functions - just simple, reliable tables!' as message,
       'The app will handle user creation directly in code.' as next_step;




