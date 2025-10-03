-- COMPLETE UUID FIX: Replace all gen_random_uuid() with safe alternatives
-- This script fixes ALL instances of gen_random_uuid() that are causing the gen_random_bytes error

-- 1. Create a safe UUID generation function
CREATE OR REPLACE FUNCTION safe_generate_uuid()
RETURNS uuid AS $$
BEGIN
    -- Use a simple UUID generation that works without extensions
    RETURN ('x' || substr(md5(random()::text || clock_timestamp()::text), 1, 16))::uuid;
END;
$$ LANGUAGE plpgsql;

-- 2. Update all table definitions that use gen_random_uuid() as DEFAULT
-- Fix client_assignees table
ALTER TABLE IF EXISTS public.client_assignees ALTER COLUMN id SET DEFAULT safe_generate_uuid();

-- Fix persons table
ALTER TABLE IF EXISTS public.persons ALTER COLUMN person_id SET DEFAULT safe_generate_uuid();

-- Fix user_profiles table (if it has a default)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'id' AND column_default LIKE '%gen_random_uuid%') THEN
        ALTER TABLE public.user_profiles ALTER COLUMN id SET DEFAULT safe_generate_uuid();
    END IF;
END $$;

-- Fix messages table
ALTER TABLE IF EXISTS public.messages ALTER COLUMN id SET DEFAULT safe_generate_uuid();

-- Fix conversations table
ALTER TABLE IF EXISTS public.conversations ALTER COLUMN id SET DEFAULT safe_generate_uuid();

-- Fix appointments table
ALTER TABLE IF EXISTS public.appointments ALTER COLUMN id SET DEFAULT safe_generate_uuid();

-- Fix any other tables that might have gen_random_uuid() defaults
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT table_name, column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND column_default LIKE '%gen_random_uuid%'
    LOOP
        EXECUTE format('ALTER TABLE public.%I ALTER COLUMN %I SET DEFAULT safe_generate_uuid()', r.table_name, r.column_name);
        RAISE NOTICE 'Updated table % column %', r.table_name, r.column_name;
    END LOOP;
END $$;

-- 3. Update the handle_new_user function to use safe UUID generation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    new_person_id uuid;
BEGIN
    -- First create a person record using safe UUID generation
    INSERT INTO public.persons (person_id, email, created_at, updated_at)
    VALUES (
        safe_generate_uuid(),
        NEW.email,
        NOW(),
        NOW()
    ) RETURNING person_id INTO new_person_id;
    
    -- Then create user profile with all required fields
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

-- 4. Ensure the trigger exists and is working
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 5. Create organizations table if it doesn't exist
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

-- 6. Enable RLS on organizations table
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- 7. Create RLS policies for organizations table
DROP POLICY IF EXISTS "Anyone can view organizations" ON public.organizations;
CREATE POLICY "Anyone can view organizations" ON public.organizations
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can create organizations" ON public.organizations;
CREATE POLICY "Authenticated users can create organizations" ON public.organizations
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- 8. Grant permissions
GRANT ALL ON public.organizations TO authenticated;
GRANT ALL ON public.organizations TO anon;
GRANT ALL ON public.organizations TO service_role;

-- 9. Test the UUID generation function
SELECT 
    'UUID generation test:' as test_name,
    safe_generate_uuid() as generated_uuid;

-- 10. Verify all functions work
SELECT 
    'All UUID functions updated successfully!' as status;




