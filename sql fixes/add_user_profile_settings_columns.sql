-- Migration to add settings and notification fields to user_profiles table
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS push_notification_token text;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS settings jsonb DEFAULT '{}'::jsonb;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS deleted boolean DEFAULT false;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS reason_for_account_deletion text;
