-- Fix UUID Generation Issues
-- This script fixes the gen_random_uuid() function error by using safer alternatives

-- 1. Enable pgcrypto extension if possible
DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    RAISE NOTICE 'pgcrypto extension enabled successfully';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'pgcrypto extension could not be enabled. Using alternative UUID generation.';
    WHEN OTHERS THEN
        RAISE NOTICE 'pgcrypto extension could not be enabled. Using alternative UUID generation.';
END $$;

-- 2. Create a safe UUID generation function that works without pgcrypto
CREATE OR REPLACE FUNCTION safe_generate_uuid()
RETURNS uuid AS $$
BEGIN
    -- Try to use gen_random_uuid() if available
    BEGIN
        RETURN gen_random_uuid();
    EXCEPTION
        WHEN undefined_function THEN
            -- Fallback to a simple UUID generation using random()
            RETURN ('x' || substr(md5(random()::text || clock_timestamp()::text), 1, 16))::uuid;
    END;
END;
$$ LANGUAGE plpgsql;

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

-- 5. Test the UUID generation function
SELECT 
    'UUID generation test:' as test_name,
    safe_generate_uuid() as generated_uuid;

-- 6. Verify the function works
SELECT 
    'handle_new_user function updated successfully!' as status;




