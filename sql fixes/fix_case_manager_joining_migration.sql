-- Comprehensive migration to fix case manager joining functionality
-- This migration addresses the database schema issues that prevent case managers from joining organizations

-- 1. Add organizations field to user_profiles table
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS organizations text[] DEFAULT '{}';

-- 2. Add account_type field to user_profiles table  
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS account_type text DEFAULT 'citizen';

-- 3. Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_organizations ON public.user_profiles USING GIN (organizations);
CREATE INDEX IF NOT EXISTS idx_user_profiles_account_type ON public.user_profiles (account_type);

-- 4. Update existing users to have the default account type
UPDATE public.user_profiles SET account_type = 'citizen' WHERE account_type IS NULL;

-- 5. Ensure organizations field is initialized for existing users
UPDATE public.user_profiles SET organizations = '{}' WHERE organizations IS NULL;a 