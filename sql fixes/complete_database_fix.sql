-- Complete Database Schema Fix for Sainte App
-- This migration adds all missing columns to match the UserDto expectations

-- Add missing columns to user_profiles table
ALTER TABLE public.user_profiles
    ADD COLUMN IF NOT EXISTS deleted BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS reason_for_account_deletion TEXT,
    ADD COLUMN IF NOT EXISTS name TEXT,
    ADD COLUMN IF NOT EXISTS account_type TEXT DEFAULT 'citizen',
    ADD COLUMN IF NOT EXISTS organizations TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS organization TEXT,
    ADD COLUMN IF NOT EXISTS organization_address TEXT,
    ADD COLUMN IF NOT EXISTS job_title TEXT,
    ADD COLUMN IF NOT EXISTS supervisors_name TEXT,
    ADD COLUMN IF NOT EXISTS supervisors_email TEXT,
    ADD COLUMN IF NOT EXISTS services TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS user_code TEXT,
    ADD COLUMN IF NOT EXISTS push_notification_token TEXT;

-- Create index for better performance on deleted column
CREATE INDEX IF NOT EXISTS idx_user_profiles_deleted ON public.user_profiles (deleted);

-- Create index for account_type lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_account_type ON public.user_profiles (account_type);

-- Update existing records to have default values
UPDATE public.user_profiles 
SET 
    deleted = FALSE,
    account_type = 'citizen',
    organizations = '{}',
    services = '{}'
WHERE deleted IS NULL OR account_type IS NULL;

-- Add RLS policy for deleted column filtering
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id AND deleted = FALSE);

-- Update the user creation function to include new fields
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure the trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Add function to safely get user profile with all fields
CREATE OR REPLACE FUNCTION get_user_profile(user_id uuid)
RETURNS TABLE (
    id uuid,
    email text,
    name text,
    first_name text,
    last_name text,
    phone text,
    avatar_url text,
    address text,
    person_id uuid,
    account_type text,
    organizations text[],
    organization text,
    organization_address text,
    job_title text,
    supervisors_name text,
    supervisors_email text,
    services text[],
    user_code text,
    deleted boolean,
    reason_for_account_deletion text,
    push_notification_token text,
    created_at timestamptz,
    updated_at timestamptz
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        up.id,
        up.email,
        up.name,
        up.first_name,
        up.last_name,
        up.phone,
        up.avatar_url,
        up.address,
        up.person_id,
        up.account_type,
        up.organizations,
        up.organization,
        up.organization_address,
        up.job_title,
        up.supervisors_name,
        up.supervisors_email,
        up.services,
        up.user_code,
        up.deleted,
        up.reason_for_account_deletion,
        up.push_notification_token,
        up.created_at,
        up.updated_at
    FROM public.user_profiles up
    WHERE up.id = user_id AND up.deleted = FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_user_profile(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_profile(uuid) TO anon;

-- Add RLS policies for the new fields
CREATE POLICY "Users can update own profile fields" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id AND deleted = FALSE);

-- Ensure all existing policies are correct
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Add policy for service role to manage all profiles (for admin functions)
CREATE POLICY "Service role can manage all profiles" ON public.user_profiles
    FOR ALL USING (auth.role() = 'service_role');

-- Update the updated_at trigger to work with new fields
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Ensure the trigger exists and works
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON public.user_profiles 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Add a function to safely create user profiles with validation
CREATE OR REPLACE FUNCTION create_user_profile_safe(
    user_id uuid,
    user_email text,
    user_name text DEFAULT NULL,
    user_account_type text DEFAULT 'citizen',
    user_organizations text[] DEFAULT '{}',
    user_services text[] DEFAULT '{}'
)
RETURNS uuid AS $$
DECLARE
    new_person_id uuid;
    profile_id uuid;
BEGIN
    -- Validate inputs
    IF user_id IS NULL OR user_email IS NULL THEN
        RAISE EXCEPTION 'User ID and email are required';
    END IF;
    
    -- Check if user profile already exists
    IF EXISTS (SELECT 1 FROM public.user_profiles WHERE id = user_id) THEN
        RAISE EXCEPTION 'User profile already exists';
    END IF;
    
    -- Create person record first
    INSERT INTO public.persons (person_id, email, created_at, updated_at)
    VALUES (
        gen_random_uuid(),
        user_email,
        NOW(),
        NOW()
    ) RETURNING person_id INTO new_person_id;
    
    -- Create user profile
    INSERT INTO public.user_profiles (
        id,
        email,
        name,
        account_type,
        person_id,
        organizations,
        services,
        deleted,
        created_at,
        updated_at
    )
    VALUES (
        user_id,
        user_email,
        COALESCE(user_name, user_email),
        user_account_type,
        new_person_id,
        user_organizations,
        user_services,
        FALSE,
        NOW(),
        NOW()
    ) RETURNING id INTO profile_id;
    
    RETURN profile_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions for the safe creation function
GRANT EXECUTE ON FUNCTION create_user_profile_safe(uuid, text, text, text, text[], text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_profile_safe(uuid, text, text, text, text[], text[]) TO service_role;

-- Add helpful comments to the table
COMMENT ON TABLE public.user_profiles IS 'User profiles table with all required fields for Sainte app';
COMMENT ON COLUMN public.user_profiles.deleted IS 'Soft delete flag - users marked as deleted rather than removed';
COMMENT ON COLUMN public.user_profiles.account_type IS 'Type of account: citizen, case_manager, admin, etc.';
COMMENT ON COLUMN public.user_profiles.organizations IS 'Array of organization IDs the user belongs to';
COMMENT ON COLUMN public.user_profiles.services IS 'Array of services the user has access to';

-- Final verification query
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
    AND table_schema = 'public'
ORDER BY ordinal_position;




