-- Check the actual schema of user_profiles table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_profiles'
ORDER BY ordinal_position;

-- Also check what columns exist in user_profiles
SELECT * FROM user_profiles LIMIT 1; 