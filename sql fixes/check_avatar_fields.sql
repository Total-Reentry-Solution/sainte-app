-- Check if avatar fields exist in user_profiles table
-- Run this in your Supabase SQL Editor to verify the fix worked

-- Check table structure
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
AND column_name IN ('avatar_url', 'avatar')
ORDER BY column_name;

-- Check if any users have avatar data
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN avatar_url IS NOT NULL THEN 1 END) as users_with_avatar_url,
    COUNT(CASE WHEN avatar IS NOT NULL THEN 1 END) as users_with_avatar
FROM user_profiles;

-- Check RLS policies
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'user_profiles';
