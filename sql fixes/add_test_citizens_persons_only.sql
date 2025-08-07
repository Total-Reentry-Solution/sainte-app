-- Add test citizens directly to persons table
-- This avoids the user_profiles table structure issue

INSERT INTO persons (
    person_id,
    first_name,
    last_name,
    email,
    account_status,
    case_status,
    created_at,
    updated_at
) VALUES 
    (gen_random_uuid(), 'Ahmad', 'Citizen', 'ahmad.citizen@example.com', 'active', 'intake', NOW(), NOW()),
    (gen_random_uuid(), 'John', 'Doe', 'john.doe@example.com', 'active', 'intake', NOW(), NOW()),
    (gen_random_uuid(), 'Jane', 'Smith', 'jane.smith@example.com', 'active', 'intake', NOW(), NOW()),
    (gen_random_uuid(), 'Mike', 'Johnson', 'mike.johnson@example.com', 'active', 'intake', NOW(), NOW()),
    (gen_random_uuid(), 'Sarah', 'Williams', 'sarah.williams@example.com', 'active', 'intake', NOW(), NOW());

-- Verify the data was added
SELECT 
    person_id,
    first_name,
    last_name,
    email,
    account_status,
    case_status
FROM persons 
WHERE email IN (
    'ahmad.citizen@example.com',
    'john.doe@example.com',
    'jane.smith@example.com',
    'mike.johnson@example.com',
    'sarah.williams@example.com'
)
ORDER BY first_name; 