-- Test search query to verify search functionality
-- Replace 'test' with any search term you want to test

SELECT 
    person_id,
    first_name,
    last_name,
    email,
    account_status
FROM persons 
WHERE account_status = 'active'
  AND (
    first_name ILIKE '%test%' 
    OR last_name ILIKE '%test%' 
    OR email ILIKE '%test%'
  )
ORDER BY first_name, last_name; 