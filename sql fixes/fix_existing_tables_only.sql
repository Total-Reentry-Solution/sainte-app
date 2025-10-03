-- Fix Existing Tables Only - Safe Migration
-- This only adds missing columns and fixes policies without recreating existing tables

-- 1. Add missing columns to user_profiles table (if they don't exist)
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
    ADD COLUMN IF NOT EXISTS person_id UUID,
    ADD COLUMN IF NOT EXISTS verification_status TEXT,
    ADD COLUMN IF NOT EXISTS verification TEXT,
    ADD COLUMN IF NOT EXISTS intake_form TEXT,
    ADD COLUMN IF NOT EXISTS mood_logs TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS mood_timeline TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS assignee TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS activity_date TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS mentors TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS push_notification_token TEXT,
    ADD COLUMN IF NOT EXISTS officers TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS password TEXT,
    ADD COLUMN IF NOT EXISTS settings JSONB DEFAULT '{"pushNotification": true, "emailNotification": true, "smsNotification": false}',
    ADD COLUMN IF NOT EXISTS reason_for_account_deletion TEXT,
    ADD COLUMN IF NOT EXISTS address TEXT,
    ADD COLUMN IF NOT EXISTS dob DATE,
    ADD COLUMN IF NOT EXISTS availability TEXT,
    ADD COLUMN IF NOT EXISTS phone_number TEXT;

-- 2. Add missing columns to persons table (if they don't exist)
ALTER TABLE public.persons 
    ADD COLUMN IF NOT EXISTS case_status TEXT DEFAULT 'intake',
    ADD COLUMN IF NOT EXISTS account_status TEXT DEFAULT 'active',
    ADD COLUMN IF NOT EXISTS case_manager_id UUID;

-- 3. Create indexes for better performance (if they don't exist)
CREATE INDEX IF NOT EXISTS idx_user_profiles_deleted ON public.user_profiles(deleted);
CREATE INDEX IF NOT EXISTS idx_user_profiles_account_type ON public.user_profiles(account_type);
CREATE INDEX IF NOT EXISTS idx_user_profiles_person_id ON public.user_profiles(person_id);
CREATE INDEX IF NOT EXISTS idx_persons_case_status ON public.persons(case_status);
CREATE INDEX IF NOT EXISTS idx_persons_account_status ON public.persons(account_status);
CREATE INDEX IF NOT EXISTS idx_persons_case_manager_id ON public.persons(case_manager_id);

-- 4. Fix the user creation function to handle registration properly
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
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the user creation
        RAISE WARNING 'Error creating user profile: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Ensure the trigger exists and is working
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 6. Fix RLS policies to ensure proper access
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id AND deleted = FALSE);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id AND deleted = FALSE);

-- 7. Add policy for service role to manage all profiles (for admin functions)
DROP POLICY IF EXISTS "Service role can manage all profiles" ON public.user_profiles;
CREATE POLICY "Service role can manage all profiles" ON public.user_profiles
    FOR ALL USING (auth.role() = 'service_role');

-- 8. Add RLS policies for persons table
ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own person record" ON public.persons;
CREATE POLICY "Users can view their own person record" ON public.persons
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE user_profiles.person_id = persons.person_id 
            AND user_profiles.id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update their own person record" ON public.persons;
CREATE POLICY "Users can update their own person record" ON public.persons
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE user_profiles.person_id = persons.person_id 
            AND user_profiles.id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Service role can manage all persons" ON public.persons;
CREATE POLICY "Service role can manage all persons" ON public.persons
    FOR ALL USING (auth.role() = 'service_role');

-- 9. Create the update_updated_at_column function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 10. Add trigger for updated_at on persons table
DROP TRIGGER IF EXISTS update_persons_updated_at ON public.persons;
CREATE TRIGGER update_persons_updated_at 
    BEFORE UPDATE ON public.persons 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 11. Grant permissions
GRANT ALL ON public.persons TO authenticated;

-- 12. Final verification - check that all required columns exist
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'user_profiles'
    AND column_name IN ('deleted', 'account_type', 'person_id', 'organizations', 'services')
ORDER BY column_name;

