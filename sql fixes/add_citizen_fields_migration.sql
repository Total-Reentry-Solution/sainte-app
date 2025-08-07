-- Add missing fields for citizens to user_profiles table
-- Run this in your Supabase SQL Editor

-- 1. Add missing fields for citizens
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS assignees text[] DEFAULT '{}';
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS reason_for_request text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS what_you_need_in_a_mentor text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS dropped_reason text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS client_id text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS status text DEFAULT 'pending';

-- 2. Add missing fields for case managers (if not already added)
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS organizations text[] DEFAULT '{}';
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS account_type text DEFAULT 'citizen';
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS organization text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS organization_address text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS job_title text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS supervisors_name text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS supervisors_email text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS services text[];

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_account_type ON public.user_profiles(account_type);
CREATE INDEX IF NOT EXISTS idx_user_profiles_status ON public.user_profiles(status);
CREATE INDEX IF NOT EXISTS idx_user_profiles_assignees ON public.user_profiles USING GIN(assignees);
CREATE INDEX IF NOT EXISTS idx_user_profiles_organizations ON public.user_profiles USING GIN(organizations);

-- 4. Update existing users to have proper account_type
UPDATE public.user_profiles SET account_type = 'citizen' WHERE account_type IS NULL;

-- 5. Grant necessary permissions
GRANT ALL ON public.user_profiles TO authenticated; 