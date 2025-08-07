-- Migration to add accountType field to user_profiles table
-- This field will store the user's account type (citizen, case_manager, etc.)

-- Add the accountType column to user_profiles table
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS account_type text DEFAULT 'citizen';

-- Add an index for better query performance when filtering by account type
CREATE INDEX IF NOT EXISTS idx_user_profiles_account_type ON public.user_profiles (account_type);

-- Update existing users to have the default account type
UPDATE public.user_profiles SET account_type = 'citizen' WHERE account_type IS NULL; 