-- Add test citizens to both user_profiles and persons tables
-- This will create citizens that can be searched for

-- 1. Add to user_profiles table
INSERT INTO user_profiles (
    id,
    name,
    email,
    account_type,
    created_at,
    updated_at
) VALUES 
    (gen_random_uuid(), 'Ahmad Citizen', 'ahmad.citizen@example.com', 'citizen', NOW(), NOW()),
    (gen_random_uuid(), 'John Doe', 'john.doe@example.com', 'citizen', NOW(), NOW()),
    (gen_random_uuid(), 'Jane Smith', 'jane.smith@example.com', 'citizen', NOW(), NOW()),
    (gen_random_uuid(), 'Mike Johnson', 'mike.johnson@example.com', 'citizen', NOW(), NOW()),
    (gen_random_uuid(), 'Sarah Williams', 'sarah.williams@example.com', 'citizen', NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

-- 2. Get the IDs we just inserted
WITH new_citizens AS (
    SELECT id, name, email 
    FROM user_profiles 
    WHERE email IN (
        'ahmad.citizen@example.com',
        'john.doe@example.com',
        'jane.smith@example.com',
        'mike.johnson@example.com',
        'sarah.williams@example.com'
    )
    AND account_type = 'citizen'
)
-- 3. Add corresponding records to persons table
INSERT INTO persons (
    person_id,
    first_name,
    last_name,
    email,
    account_status,
    case_status,
    created_at,
    updated_at
)
SELECT 
    nc.id,
    SPLIT_PART(nc.name, ' ', 1) as first_name,
    SPLIT_PART(nc.name, ' ', 2) as last_name,
    nc.email,
    'active',
    'intake',
    NOW(),
    NOW()
FROM new_citizens nc
ON CONFLICT (email) DO NOTHING;

-- 4. Verify the data was added
SELECT 
    up.id,
    up.name,
    up.email,
    up.account_type,
    p.first_name,
    p.last_name,
    p.account_status
FROM user_profiles up
LEFT JOIN persons p ON up.id = p.person_id
WHERE up.account_type = 'citizen'
ORDER BY up.name; 