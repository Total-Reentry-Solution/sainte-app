-- Migration to add organizations field to user_profiles table
-- This field will store an array of organization IDs that the user belongs to

-- Add the organizations column to user_profiles table
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS organizations text[] DEFAULT '{}';

-- Add an index for better query performance when searching by organizations
CREATE INDEX IF NOT EXISTS idx_user_profiles_organizations ON public.user_profiles USING GIN (organizations); 