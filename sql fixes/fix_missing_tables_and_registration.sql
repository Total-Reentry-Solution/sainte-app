-- Fix Missing Tables and Registration Issues
-- Run this in your Supabase SQL Editor

-- 1. Create the missing client_assignees table
CREATE TABLE IF NOT EXISTS public.client_assignees (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    client_id uuid NOT NULL,
    assignee_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT client_assignees_pkey PRIMARY KEY (id),
    CONSTRAINT client_assignees_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.users(id),
    CONSTRAINT client_assignees_assignee_id_fkey FOREIGN KEY (assignee_id) REFERENCES auth.users(id),
    CONSTRAINT client_assignees_unique UNIQUE (client_id, assignee_id)
);

-- 2. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_client_assignees_client_id ON public.client_assignees(client_id);
CREATE INDEX IF NOT EXISTS idx_client_assignees_assignee_id ON public.client_assignees(assignee_id);

-- 3. Enable RLS on client_assignees table
ALTER TABLE public.client_assignees ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS policies for client_assignees
CREATE POLICY "Users can view their own assignments" ON public.client_assignees
    FOR SELECT USING (client_id = auth.uid() OR assignee_id = auth.uid());

CREATE POLICY "Users can create assignments" ON public.client_assignees
    FOR INSERT WITH CHECK (client_id = auth.uid() OR assignee_id = auth.uid());

CREATE POLICY "Users can update their own assignments" ON public.client_assignees
    FOR UPDATE USING (client_id = auth.uid() OR assignee_id = auth.uid());

CREATE POLICY "Users can delete their own assignments" ON public.client_assignees
    FOR DELETE USING (client_id = auth.uid() OR assignee_id = auth.uid());

-- 5. Add trigger for updated_at on client_assignees table
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_client_assignees_updated_at 
    BEFORE UPDATE ON public.client_assignees 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 6. Fix the user creation function to handle registration properly
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

-- 7. Ensure the trigger exists and is working
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 8. Add a function to safely create user profiles during registration
CREATE OR REPLACE FUNCTION create_user_profile_on_registration(
    user_id uuid,
    user_email text,
    user_name text DEFAULT NULL
)
RETURNS void AS $$
DECLARE
    new_person_id uuid;
BEGIN
    -- Check if user profile already exists
    IF EXISTS (SELECT 1 FROM public.user_profiles WHERE id = user_id) THEN
        RETURN; -- Profile already exists, nothing to do
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
        'citizen',
        new_person_id,
        '{}',
        '{}',
        FALSE,
        NOW(),
        NOW()
    );
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail
        RAISE WARNING 'Error creating user profile during registration: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_user_profile_on_registration(uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_profile_on_registration(uuid, text, text) TO anon;
GRANT EXECUTE ON FUNCTION create_user_profile_on_registration(uuid, text, text) TO service_role;

-- 10. Fix RLS policies to ensure proper access
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id AND deleted = FALSE);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id AND deleted = FALSE);

-- 11. Add policy for service role to manage all profiles (for admin functions)
DROP POLICY IF EXISTS "Service role can manage all profiles" ON public.user_profiles;
CREATE POLICY "Service role can manage all profiles" ON public.user_profiles
    FOR ALL USING (auth.role() = 'service_role');

-- 12. Ensure persons table has all necessary fields
ALTER TABLE public.persons 
    ADD COLUMN IF NOT EXISTS case_status text DEFAULT 'intake',
    ADD COLUMN IF NOT EXISTS account_status text DEFAULT 'active',
    ADD COLUMN IF NOT EXISTS case_manager_id uuid;

-- 13. Create indexes for persons table
CREATE INDEX IF NOT EXISTS idx_persons_case_status ON public.persons(case_status);
CREATE INDEX IF NOT EXISTS idx_persons_account_status ON public.persons(account_status);
CREATE INDEX IF NOT EXISTS idx_persons_case_manager_id ON public.persons(case_manager_id);

-- 14. Add RLS policies for persons table
ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own person record" ON public.persons
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE user_profiles.person_id = persons.person_id 
            AND user_profiles.id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own person record" ON public.persons
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE user_profiles.person_id = persons.person_id 
            AND user_profiles.id = auth.uid()
        )
    );

CREATE POLICY "Service role can manage all persons" ON public.persons
    FOR ALL USING (auth.role() = 'service_role');

-- 15. Add trigger for updated_at on persons table
CREATE TRIGGER update_persons_updated_at 
    BEFORE UPDATE ON public.persons 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 16. Grant permissions
GRANT ALL ON public.client_assignees TO authenticated;
GRANT ALL ON public.persons TO authenticated;

-- 17. Final verification - check that all tables exist
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('user_profiles', 'persons', 'client_assignees', 'organizations', 'conversations', 'messages', 'appointments')
ORDER BY tablename;

