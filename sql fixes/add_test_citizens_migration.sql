-- Add test citizens to the database
-- Run this in your Supabase SQL Editor

-- 1. Ensure the persons table has the necessary fields
ALTER TABLE public.persons ADD COLUMN IF NOT EXISTS case_status text DEFAULT 'intake';
ALTER TABLE public.persons ADD COLUMN IF NOT EXISTS account_status text DEFAULT 'active';
ALTER TABLE public.persons ADD COLUMN IF NOT EXISTS case_manager_id uuid;

-- 2. Insert test citizens
INSERT INTO public.persons (first_name, last_name, email, case_status, account_status) VALUES
('John', 'Doe', 'john.doe@example.com', 'intake', 'active'),
('Jane', 'Smith', 'jane.smith@example.com', 'active', 'active'),
('Mike', 'Johnson', 'mike.johnson@example.com', 'intake', 'active'),
('Sarah', 'Wilson', 'sarah.wilson@example.com', 'active', 'active'),
('David', 'Brown', 'david.brown@example.com', 'intake', 'active'),
('Emily', 'Davis', 'emily.davis@example.com', 'active', 'active'),
('Robert', 'Miller', 'robert.miller@example.com', 'intake', 'active'),
('Lisa', 'Garcia', 'lisa.garcia@example.com', 'active', 'active'),
('James', 'Martinez', 'james.martinez@example.com', 'intake', 'active'),
('Maria', 'Anderson', 'maria.anderson@example.com', 'active', 'active')
ON CONFLICT DO NOTHING;

-- Add test citizens to the persons table for search testing
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
    (gen_random_uuid(), 'John', 'Doe', 'john.doe@example.com', 'active', 'intake', NOW(), NOW()),
    (gen_random_uuid(), 'Jane', 'Smith', 'jane.smith@example.com', 'active', 'intake', NOW(), NOW()),
    (gen_random_uuid(), 'Mike', 'Johnson', 'mike.johnson@example.com', 'active', 'intake', NOW(), NOW()),
    (gen_random_uuid(), 'Sarah', 'Williams', 'sarah.williams@example.com', 'active', 'intake', NOW(), NOW()),
    (gen_random_uuid(), 'David', 'Brown', 'david.brown@example.com', 'active', 'intake', NOW(), NOW()),
    (gen_random_uuid(), 'Lisa', 'Davis', 'lisa.davis@example.com', 'active', 'intake', NOW(), NOW()),
    (gen_random_uuid(), 'Robert', 'Miller', 'robert.miller@example.com', 'active', 'intake', NOW(), NOW()),
    (gen_random_uuid(), 'Emily', 'Wilson', 'emily.wilson@example.com', 'active', 'intake', NOW(), NOW()),
    (gen_random_uuid(), 'James', 'Taylor', 'james.taylor@example.com', 'active', 'intake', NOW(), NOW()),
    (gen_random_uuid(), 'Amanda', 'Anderson', 'amanda.anderson@example.com', 'active', 'intake', NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

-- Verify the data was inserted
SELECT 
    person_id,
    first_name,
    last_name,
    email,
    account_status,
    case_status
FROM persons 
WHERE account_status = 'active'
ORDER BY first_name
LIMIT 10; 