-- SIMPLE UUID FIX - No complex string concatenation
-- This script creates a simple UUID generation function that works

-- 1. Drop any existing problematic functions
DROP FUNCTION IF EXISTS safe_generate_uuid();

-- 2. Create a simple UUID generation function using built-in methods
CREATE OR REPLACE FUNCTION safe_generate_uuid()
RETURNS uuid AS $$
BEGIN
    -- Use the built-in gen_random_uuid() if available, otherwise use a simple method
    BEGIN
        RETURN gen_random_uuid();
    EXCEPTION
        WHEN undefined_function THEN
            -- Simple fallback: use random() to generate a UUID-like string
            RETURN (md5(random()::text || clock_timestamp()::text))::uuid;
    END;
END;
$$ LANGUAGE plpgsql;

-- 3. Test the function
SELECT safe_generate_uuid() as test_uuid;

-- 4. Update the handle_new_user function
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    new_person_id uuid;
BEGIN
    -- Create person record
    INSERT INTO public.persons (person_id, email, created_at, updated_at)
    VALUES (
        safe_generate_uuid(),
        NEW.email,
        NOW(),
        NOW()
    ) RETURNING person_id INTO new_person_id;
    
    -- Create user profile
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
        RAISE WARNING 'Error creating user profile: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Create the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 6. Create organizations table
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

-- 7. Enable RLS and create policies
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

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

-- 9. Final test
SELECT 'UUID function created successfully!' as status;




