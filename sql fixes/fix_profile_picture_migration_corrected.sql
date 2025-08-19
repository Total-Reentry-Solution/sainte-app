-- Fix Profile Picture Functionality (Corrected Version)
-- This migration ensures profile pictures can be properly stored and retrieved

-- 1. Ensure avatar_url field exists in user_profiles table
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS avatar_url text;

-- 2. Create avatars storage bucket if it doesn't exist
-- Note: This needs to be run in Supabase Storage section, not SQL Editor
-- Go to Storage > Create bucket: 'avatars' with public access

-- 3. Add RLS policy for avatar_url access
-- Drop existing policies if they exist to avoid conflicts
DROP POLICY IF EXISTS "Users can view avatar_url of other users" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update their own avatar_url" ON public.user_profiles;

-- Create new policies
CREATE POLICY "Users can view avatar_url of other users" ON public.user_profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update their own avatar_url" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- 4. Create index for avatar_url queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_avatar_url ON public.user_profiles(avatar_url);

-- 5. Update existing users to have default avatar if they don't have one
UPDATE public.user_profiles 
SET avatar_url = 'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png?20150327203541'
WHERE avatar_url IS NULL OR avatar_url = '';

-- 6. Ensure the storage bucket has proper policies
-- Note: These policies need to be set in Supabase Storage section
-- Go to Storage > avatars > Policies and add:

-- Policy: "Anyone can view avatars"
-- SELECT: true

-- Policy: "Authenticated users can upload avatars"
-- INSERT: auth.role() = 'authenticated'

-- Policy: "Users can update their own avatars"
-- UPDATE: auth.uid()::text = (storage.foldername(name))[1]

-- Policy: "Users can delete their own avatars"
-- DELETE: auth.uid()::text = (storage.foldername(name))[1]
