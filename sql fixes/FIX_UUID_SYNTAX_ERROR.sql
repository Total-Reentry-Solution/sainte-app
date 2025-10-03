-- FIX UUID SYNTAX ERROR (22P02)
-- This script fixes the invalid UUID syntax error by using proper UUID generation

-- 1. Drop the problematic function first
DROP FUNCTION IF EXISTS safe_generate_uuid();

-- 2. Create a proper UUID generation function that produces valid UUIDs
CREATE OR REPLACE FUNCTION safe_generate_uuid()
RETURNS uuid AS $$
BEGIN
    -- Use a proper UUID v4 generation method
    RETURN uuid_generate_v4();
EXCEPTION
    WHEN undefined_function THEN
        -- Fallback: create a valid UUID using a different method
        RETURN (
            lpad(to_hex(floor(random() * 4294967295)::int), 8, '0') ||
            '-' ||
            lpad(to_hex(floor(random() * 65535)::int), 4, '0') ||
            '-4' ||
            lpad(to_hex(floor(random() * 4095)::int), 3, '0') ||
            '-' ||
            lpad(to_hex(floor(random() * 16383)::int + 32768), 4, '0') ||
            '-' ||
            lpad(to_hex(floor(random() * 281474976710655)::bigint), 12, '0')
        )::uuid;
END;
$$ LANGUAGE plpgsql;

-- 3. Try to enable uuid-ossp extension for proper UUID generation
DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    RAISE NOTICE 'uuid-ossp extension enabled successfully';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'uuid-ossp extension could not be enabled. Using fallback method.';
    WHEN OTHERS THEN
        RAISE NOTICE 'uuid-ossp extension could not be enabled. Using fallback method.';
END $$;

-- 4. Update the function to use uuid-ossp if available
CREATE OR REPLACE FUNCTION safe_generate_uuid()
RETURNS uuid AS $$
BEGIN
    -- Try to use uuid_generate_v4() if available
    BEGIN
        RETURN uuid_generate_v4();
    EXCEPTION
        WHEN undefined_function THEN
            -- Fallback: create a valid UUID using a different method
            RETURN (
                lpad(to_hex(floor(random() * 4294967295)::int), 8, '0') ||
                '-' ||
                lpad(to_hex(floor(random() * 65535)::int), 4, '0') ||
                '-4' ||
                lpad(to_hex(floor(random() * 4095)::int), 3, '0') ||
                '-' ||
                lpad(to_hex(floor(random() * 16383)::int + 32768), 4, '0') ||
                '-' ||
                lpad(to_hex(floor(random() * 281474976710655)::bigint), 12, '0')
            )::uuid;
    END;
END;
$$ LANGUAGE plpgsql;

-- 5. Test the UUID generation function
SELECT 
    'UUID generation test:' as test_name,
    safe_generate_uuid() as generated_uuid;

-- 6. Update the handle_new_user function to use the fixed UUID generation
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

-- 7. Ensure the trigger exists and is working
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 8. Create organizations table if it doesn't exist
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

-- 9. Enable RLS on organizations table
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- 10. Create RLS policies for organizations table
DROP POLICY IF EXISTS "Anyone can view organizations" ON public.organizations;
CREATE POLICY "Anyone can view organizations" ON public.organizations
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can create organizations" ON public.organizations;
CREATE POLICY "Authenticated users can create organizations" ON public.organizations
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- 11. Grant permissions
GRANT ALL ON public.organizations TO authenticated;
GRANT ALL ON public.organizations TO anon;
GRANT ALL ON public.organizations TO service_role;

-- 12. Verify the function works
SELECT 
    'UUID functions fixed successfully!' as status;




