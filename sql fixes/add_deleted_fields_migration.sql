-- Migration to add deleted and reason_for_account_deletion fields to user_profiles table
ALTER TABLE public.user_profiles
    ADD COLUMN IF NOT EXISTS deleted BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS reason_for_account_deletion TEXT;

-- Optional index for faster lookups of active users
CREATE INDEX IF NOT EXISTS idx_user_profiles_deleted ON public.user_profiles (deleted);
