-- Complete migration to fix case manager joining and account type issues
-- Run this in your Supabase SQL Editor

-- 1. Add missing fields to user_profiles table
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS organizations text[] DEFAULT '{}';
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS account_type text DEFAULT 'citizen';

-- 2. Add missing case manager specific fields
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS organization text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS organization_address text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS job_title text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS supervisors_name text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS supervisors_email text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS services text[];

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_organizations ON public.user_profiles USING GIN (organizations);
CREATE INDEX IF NOT EXISTS idx_user_profiles_account_type ON public.user_profiles (account_type);
CREATE INDEX IF NOT EXISTS idx_user_profiles_organization ON public.user_profiles (organization);

-- 4. Update existing users to have proper default values
UPDATE public.user_profiles SET account_type = 'citizen' WHERE account_type IS NULL;
UPDATE public.user_profiles SET organizations = '{}' WHERE organizations IS NULL;

-- 5. Fix any case managers who were incorrectly set as citizens
-- Update users who have organization info but are marked as citizens to be case managers
UPDATE public.user_profiles 
SET account_type = 'case_manager' 
WHERE account_type = 'citizen' 
AND (
    organization IS NOT NULL 
    OR job_title IS NOT NULL 
    OR supervisors_name IS NOT NULL 
    OR supervisors_email IS NOT NULL
);

-- Also update users who have services but are marked as citizens to be case managers
UPDATE public.user_profiles 
SET account_type = 'case_manager' 
WHERE account_type = 'citizen' 
AND services IS NOT NULL 
AND array_length(services, 1) > 0;

-- 6. Ensure the trigger function exists and is working properly
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
    INSERT INTO public.user_profiles (
        id, 
        email, 
        person_id, 
        account_type,
        organizations,
        created_at, 
        updated_at
    )
    VALUES (
        NEW.id,
        NEW.email,
        new_person_id,
        'citizen', -- default account type
        '{}', -- empty organizations array
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

-- 8. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.user_profiles TO authenticated;
GRANT ALL ON public.persons TO authenticated; 