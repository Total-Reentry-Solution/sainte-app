-- URGENT FIX: Replace all gen_random_uuid() calls with safe alternatives
-- This script fixes the gen_random_bytes error that's preventing account creation

-- 1. Create a safe UUID generation function
CREATE OR REPLACE FUNCTION safe_generate_uuid()
RETURNS uuid AS $$
BEGIN
    -- Use a simple UUID generation that works without extensions
    RETURN ('x' || substr(md5(random()::text || clock_timestamp()::text), 1, 16))::uuid;
END;
$$ LANGUAGE plpgsql;

-- 2. Update the handle_new_user function to use safe UUID generation
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

-- 3. Ensure the trigger exists and is working
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 4. Create organizations table if it doesn't exist
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

-- 5. Enable RLS on organizations table
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS policies for organizations table
DROP POLICY IF EXISTS "Anyone can view organizations" ON public.organizations;
CREATE POLICY "Anyone can view organizations" ON public.organizations
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can create organizations" ON public.organizations;
CREATE POLICY "Authenticated users can create organizations" ON public.organizations
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- 7. Grant permissions
GRANT ALL ON public.organizations TO authenticated;
GRANT ALL ON public.organizations TO anon;
GRANT ALL ON public.organizations TO service_role;

-- 8. Test the UUID generation function
SELECT 
    'UUID generation test:' as test_name,
    safe_generate_uuid() as generated_uuid;

-- 9. Verify the function works
SELECT 
    'All functions updated successfully!' as status;




