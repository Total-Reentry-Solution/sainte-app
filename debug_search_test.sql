-- Debug script to test search functionality
-- Run these queries one by one to see what's in your database

-- 1. Check if there are any users in user_profiles with account_type = 'citizen'
SELECT 
    user_id,
    name,
    email,
    account_type
FROM user_profiles 
WHERE account_type = 'citizen'
ORDER BY name;

-- 2. Check if there are any active persons
SELECT 
    person_id,
    first_name,
    last_name,
    email,
    account_status
FROM persons 
WHERE account_status = 'active'
ORDER BY first_name;

-- 3. Test search for 'A' in user_profiles (citizens only)
SELECT 
    user_id,
    name,
    email,
    account_type
FROM user_profiles 
WHERE account_type = 'citizen'
  AND (name ILIKE '%A%' OR email ILIKE '%A%')
ORDER BY name;

-- 4. Check the relationship between user_profiles and persons
SELECT 
    up.user_id,
    up.name as profile_name,
    up.email as profile_email,
    up.account_type,
    p.person_id,
    p.first_name,
    p.last_name,
    p.email as person_email,
    p.account_status
FROM user_profiles up
LEFT JOIN persons p ON up.user_id = p.person_id
WHERE up.account_type = 'citizen'
ORDER BY up.name; 