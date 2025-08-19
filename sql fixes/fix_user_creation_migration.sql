-- Migration to fix user creation issues
-- This migration ensures proper person_id handling and adds missing fields

-- 1. Make sure person_id is nullable in user_profiles (it will be set by trigger)
ALTER TABLE public.user_profiles ALTER COLUMN person_id DROP NOT NULL;

-- 2. Add organizations field if not exists
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS organizations text[] DEFAULT '{}';

-- 3. Add account_type field if not exists
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS account_type text DEFAULT 'citizen';

-- 4. Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_organizations ON public.user_profiles USING GIN (organizations);
CREATE INDEX IF NOT EXISTS idx_user_profiles_account_type ON public.user_profiles (account_type);

-- 5. Update existing users to have default values
UPDATE public.user_profiles SET account_type = 'citizen' WHERE account_type IS NULL;
UPDATE public.user_profiles SET organizations = '{}' WHERE organizations IS NULL;

-- 6. Ensure the trigger function exists and is working
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    new_person_id uuid;
BEGIN
    -- First create a person record
    INSERT INTO public.persons (person_id, email, created_at, updated_at)
    VALUES (
        gen_random_uuid(),
        NEW.email,
        NOW(),
        NOW()
    ) RETURNING person_id INTO new_person_id;
    
    -- Then create user profile and link it to the person
    INSERT INTO public.user_profiles (id, email, person_id, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        new_person_id,
        NOW(),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Ensure the trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user(); 