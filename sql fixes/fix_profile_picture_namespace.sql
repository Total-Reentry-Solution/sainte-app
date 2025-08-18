-- Fix Profile Picture Namespace Issue
-- Run this in your Supabase SQL Editor to fix the problem immediately

-- 1. Ensure user_profiles table has the avatar_url field
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS avatar_url text;

-- 2. Also add avatar field as alternative (some code might use this)
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS avatar text;

-- 3. Add RLS policies for avatar access
DROP POLICY IF EXISTS "Users can view avatar_url of other users" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update their own avatar_url" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view avatar of other users" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update their own avatar" ON public.user_profiles;

CREATE POLICY "Users can view avatar_url of other users" ON public.user_profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update their own avatar_url" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view avatar of other users" ON public.user_profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update their own avatar" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- 4. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_avatar_url ON public.user_profiles(avatar_url);
CREATE INDEX IF NOT EXISTS idx_user_profiles_avatar ON public.user_profiles(avatar);

-- 5. Update existing users to have default avatar if they don't have one
UPDATE public.user_profiles 
SET avatar_url = 'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png?20150327203541'
WHERE avatar_url IS NULL OR avatar_url = '';

UPDATE public.user_profiles 
SET avatar = 'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png?20150327203541'
WHERE avatar IS NULL OR avatar = '';

-- 6. Ensure the table has proper permissions
GRANT ALL ON public.user_profiles TO authenticated;
GRANT SELECT ON public.user_profiles TO anon;

-- 7. Verify the fix worked
SELECT 
    '✅ Profile picture fields added successfully' as status,
    COUNT(*) as total_users,
    COUNT(CASE WHEN avatar_url IS NOT NULL THEN 1 END) as users_with_avatar_url,
    COUNT(CASE WHEN avatar IS NOT NULL THEN 1 END) as users_with_avatar
FROM public.user_profiles;
