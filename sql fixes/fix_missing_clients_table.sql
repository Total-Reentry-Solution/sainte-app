-- Fix for missing clients table
-- Run this in your Supabase SQL Editor

-- 1. Create the missing clients table
CREATE TABLE IF NOT EXISTS public.clients (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    name text NOT NULL,
    avatar text DEFAULT 'https://via.placeholder.com/150',
    email text,
    reason_for_request text,
    what_you_need_in_a_mentor text,
    assignees text[] DEFAULT '{}',
    dropped_reason text,
    client_id text,
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'dropped', 'decline')),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT clients_pkey PRIMARY KEY (id)
);

-- 2. Add missing fields to user_profiles table (if not already added)
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS organizations text[] DEFAULT '{}';
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS account_type text DEFAULT 'citizen';
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS organization text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS organization_address text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS job_title text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS supervisors_name text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS supervisors_email text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS services text[];

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_clients_status ON public.clients(status);
CREATE INDEX IF NOT EXISTS idx_clients_assignees ON public.clients USING GIN(assignees);
CREATE INDEX IF NOT EXISTS idx_user_profiles_account_type ON public.user_profiles(account_type);
CREATE INDEX IF NOT EXISTS idx_user_profiles_organizations ON public.user_profiles USING GIN(organizations);

-- 4. Add trigger for updated_at on clients table
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_clients_updated_at 
    BEFORE UPDATE ON public.clients 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 5. Grant necessary permissions
GRANT ALL ON public.clients TO authenticated;
GRANT ALL ON public.user_profiles TO authenticated;

-- 6. Insert sample data for testing (optional)
INSERT INTO public.clients (name, email, reason_for_request, status) VALUES
('John Doe', 'john.doe@example.com', 'Need help with job search and housing', 'pending'),
('Jane Smith', 'jane.smith@example.com', 'Looking for mentorship in career development', 'active'),
('Mike Johnson', 'mike.johnson@example.com', 'Need support with reintegration', 'pending')
ON CONFLICT DO NOTHING; 