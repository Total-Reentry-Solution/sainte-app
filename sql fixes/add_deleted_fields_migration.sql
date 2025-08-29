-- Migration to add deleted and reason_for_account_deletion fields
-- Adds soft delete support for user accounts

ALTER TABLE public.user_profiles
    ADD COLUMN IF NOT EXISTS deleted boolean DEFAULT false,
    ADD COLUMN IF NOT EXISTS reason_for_account_deletion text;

-- Index to speed up queries filtering by deletion status
CREATE INDEX IF NOT EXISTS idx_user_profiles_deleted
    ON public.user_profiles(deleted);
