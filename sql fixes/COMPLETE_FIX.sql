-- COMPLETE DATABASE FIX FOR SAINTE APP
-- This single migration fixes all the issues

-- 1. Create client_assignees table (the missing table causing errors)
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

-- 2. Add ALL missing columns to user_profiles table
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
    ADD COLUMN IF NOT EXISTS address TEXT,
    ADD COLUMN IF NOT EXISTS dob DATE,
    ADD COLUMN IF NOT EXISTS availability TEXT,
    ADD COLUMN IF NOT EXISTS phone_number TEXT;

-- 3. Add missing columns to persons table
ALTER TABLE public.persons 
    ADD COLUMN IF NOT EXISTS case_status TEXT DEFAULT 'intake',
    ADD COLUMN IF NOT EXISTS account_status TEXT DEFAULT 'active',
    ADD COLUMN IF NOT EXISTS case_manager_id UUID;

-- 4. Add missing columns to messages table
ALTER TABLE public.messages 
    ADD COLUMN IF NOT EXISTS sender_person_id UUID,
    ADD COLUMN IF NOT EXISTS receiver_person_id UUID,
    ADD COLUMN IF NOT EXISTS sender_id UUID,
    ADD COLUMN IF NOT EXISTS receiver_id UUID,
    ADD COLUMN IF NOT EXISTS text TEXT,
    ADD COLUMN IF NOT EXISTS sent_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 5. Create all necessary indexes
CREATE INDEX IF NOT EXISTS idx_client_assignees_client_id ON public.client_assignees(client_id);
CREATE INDEX IF NOT EXISTS idx_client_assignees_assignee_id ON public.client_assignees(assignee_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_deleted ON public.user_profiles(deleted);
CREATE INDEX IF NOT EXISTS idx_user_profiles_account_type ON public.user_profiles(account_type);
CREATE INDEX IF NOT EXISTS idx_user_profiles_person_id ON public.user_profiles(person_id);
CREATE INDEX IF NOT EXISTS idx_persons_case_status ON public.persons(case_status);
CREATE INDEX IF NOT EXISTS idx_persons_account_status ON public.persons(account_status);
CREATE INDEX IF NOT EXISTS idx_persons_case_manager_id ON public.persons(case_manager_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_person_id ON public.messages(sender_person_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_person_id ON public.messages(receiver_person_id);
CREATE INDEX IF NOT EXISTS idx_messages_sent_at ON public.messages(sent_at);

-- 6. Create the update_updated_at_column function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 7. Add triggers for updated_at columns
CREATE TRIGGER update_client_assignees_updated_at 
    BEFORE UPDATE ON public.client_assignees 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_persons_updated_at 
    BEFORE UPDATE ON public.persons 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at 
    BEFORE UPDATE ON public.messages 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 8. Fix the user creation function to handle registration properly
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

-- 9. Ensure the trigger exists and is working
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 10. Enable RLS on all tables
ALTER TABLE public.client_assignees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 11. Create RLS policies for client_assignees
CREATE POLICY "Users can view their own assignments" ON public.client_assignees
    FOR SELECT USING (client_id = auth.uid() OR assignee_id = auth.uid());

CREATE POLICY "Users can create assignments" ON public.client_assignees
    FOR INSERT WITH CHECK (client_id = auth.uid() OR assignee_id = auth.uid());

CREATE POLICY "Users can update their own assignments" ON public.client_assignees
    FOR UPDATE USING (client_id = auth.uid() OR assignee_id = auth.uid());

CREATE POLICY "Users can delete their own assignments" ON public.client_assignees
    FOR DELETE USING (client_id = auth.uid() OR assignee_id = auth.uid());

-- 12. Create RLS policies for user_profiles
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id AND deleted = FALSE);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id AND deleted = FALSE);

CREATE POLICY "Service role can manage all profiles" ON public.user_profiles
    FOR ALL USING (auth.role() = 'service_role');

-- 13. Create RLS policies for persons
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

-- 14. Create RLS policies for messages
CREATE POLICY "Users can view their own messages" ON public.messages
    FOR SELECT USING (
        sender_id = auth.uid() OR 
        receiver_id = auth.uid() OR
        sender_person_id IN (
            SELECT person_id FROM public.user_profiles WHERE id = auth.uid()
        ) OR
        receiver_person_id IN (
            SELECT person_id FROM public.user_profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can insert their own messages" ON public.messages
    FOR INSERT WITH CHECK (
        sender_id = auth.uid() OR
        sender_person_id IN (
            SELECT person_id FROM public.user_profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own messages" ON public.messages
    FOR UPDATE USING (
        sender_id = auth.uid() OR 
        receiver_id = auth.uid() OR
        sender_person_id IN (
            SELECT person_id FROM public.user_profiles WHERE id = auth.uid()
        ) OR
        receiver_person_id IN (
            SELECT person_id FROM public.user_profiles WHERE id = auth.uid()
        )
    );

-- 15. Grant all necessary permissions
GRANT ALL ON public.client_assignees TO authenticated;
GRANT ALL ON public.persons TO authenticated;
GRANT ALL ON public.messages TO authenticated;

-- 16. Final verification - show all tables and their columns
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('user_profiles', 'persons', 'client_assignees', 'messages', 'organizations', 'conversations', 'appointments')
ORDER BY tablename;

-- 17. Show user_profiles columns to verify they exist
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'user_profiles'
    AND column_name IN ('deleted', 'account_type', 'person_id', 'organizations', 'services', 'name')
ORDER BY column_name;

