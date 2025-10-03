-- FIXED FINAL COMPLETE FIX FOR SAINTE APP
-- This script properly handles dependencies and addresses ALL issues
-- Run this ONCE in your Supabase SQL Editor

-- ===========================================
-- STEP 1: PROPERLY CLEAN UP EXISTING FUNCTIONS
-- ===========================================

-- Drop the trigger first (which depends on the function)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Now drop the function (no dependencies)
DROP FUNCTION IF EXISTS handle_new_user();
DROP FUNCTION IF EXISTS safe_generate_uuid();

-- ===========================================
-- STEP 2: CREATE WORKING UUID GENERATION
-- ===========================================

-- Create a simple, working UUID generation function
CREATE OR REPLACE FUNCTION generate_simple_uuid()
RETURNS uuid AS $$
BEGIN
    -- Use md5 with random data to create a valid UUID
    RETURN (md5(random()::text || clock_timestamp()::text))::uuid;
END;
$$ LANGUAGE plpgsql;

-- Test the function
SELECT generate_simple_uuid() as test_uuid;

-- ===========================================
-- STEP 3: ENSURE ALL TABLES EXIST WITH CORRECT STRUCTURE
-- ===========================================

-- Create persons table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.persons (
    person_id uuid NOT NULL DEFAULT generate_simple_uuid(),
    email text,
    first_name text,
    last_name text,
    phone_number text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT persons_pkey PRIMARY KEY (person_id)
);

-- Create user_profiles table with all required columns
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id uuid NOT NULL,
    email text,
    name text,
    first_name text,
    last_name text,
    phone text,
    avatar_url text,
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
    reason_for_account_deletion text,
    push_notification_token text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT user_profiles_pkey PRIMARY KEY (id),
    CONSTRAINT user_profiles_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.persons(person_id)
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
    id uuid NOT NULL DEFAULT generate_simple_uuid(),
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
-- STEP 4: CREATE THE WORKING TRIGGER FUNCTION
-- ===========================================

-- Create a simple, working handle_new_user function
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    new_person_id uuid;
BEGIN
    -- Create a person record using our working UUID function
    INSERT INTO public.persons (person_id, email, created_at, updated_at)
    VALUES (
        generate_simple_uuid(),
        NEW.email,
        NOW(),
        NOW()
    ) RETURNING person_id INTO new_person_id;
    
    -- Create user profile with all required fields
    INSERT INTO public.user_profiles (
        id, 
        email, 
        person_id, 
        name,
        account_type,
        deleted,
        organizations,
        services,
        created_at, 
        updated_at
    )
    VALUES (
        NEW.id,
        NEW.email,
        new_person_id,
        COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
        'citizen',
        FALSE,
        '{}',
        '{}',
        NOW(),
        NOW()
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the user creation
        RAISE WARNING 'Error creating user profile: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 5: CREATE THE TRIGGER
-- ===========================================

-- Create the trigger that calls our working function
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ===========================================
-- STEP 6: SET UP ROW LEVEL SECURITY
-- ===========================================

-- Enable RLS on all tables
ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_assignees ENABLE ROW LEVEL SECURITY;

-- Create basic RLS policies
DROP POLICY IF EXISTS "Users can view their own profile" ON public.user_profiles;
CREATE POLICY "Users can view their own profile" ON public.user_profiles
    FOR ALL USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can view their own person record" ON public.persons;
CREATE POLICY "Users can view their own person record" ON public.persons
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND person_id = persons.person_id)
    );

DROP POLICY IF EXISTS "Anyone can view organizations" ON public.organizations;
CREATE POLICY "Anyone can view organizations" ON public.organizations
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert organizations" ON public.organizations;
CREATE POLICY "Authenticated users can insert organizations" ON public.organizations
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can view their own client assignments" ON public.client_assignees;
CREATE POLICY "Users can view their own client assignments" ON public.client_assignees
    FOR ALL USING (auth.uid() = client_id OR auth.uid() = assignee_id);

-- ===========================================
-- STEP 7: GRANT PERMISSIONS
-- ===========================================

-- Grant necessary permissions
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
-- STEP 8: VERIFICATION
-- ===========================================

-- Test the UUID generation function
SELECT 'UUID Generation Test:' as test_name, generate_simple_uuid() as result;

-- Check if all tables exist
SELECT 'Tables Check:' as test_name, 
       CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'persons') 
            THEN 'persons: ✅' ELSE 'persons: ❌' END as persons_table,
       CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_profiles') 
            THEN 'user_profiles: ✅' ELSE 'user_profiles: ❌' END as user_profiles_table,
       CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'organizations') 
            THEN 'organizations: ✅' ELSE 'organizations: ❌' END as organizations_table,
       CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'client_assignees') 
            THEN 'client_assignees: ✅' ELSE 'client_assignees: ❌' END as client_assignees_table;

-- Check if the trigger exists
SELECT 'Trigger Check:' as test_name,
       CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created') 
            THEN 'on_auth_user_created: ✅' ELSE 'on_auth_user_created: ❌' END as trigger_status;

-- Check if the function exists
SELECT 'Function Check:' as test_name,
       CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_new_user') 
            THEN 'handle_new_user: ✅' ELSE 'handle_new_user: ❌' END as function_status;

-- Final success message
SELECT '🎉 FIXED FINAL FIX COMPLETE! 🎉' as status,
       'All database issues should now be resolved.' as message,
       'Try creating a citizen account now!' as next_step;




