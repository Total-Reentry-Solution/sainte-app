-- Test the exact search query that the app should be using
SELECT 
    person_id,
    first_name,
    last_name,
    email,
    account_status
FROM persons 
WHERE account_status = 'active'
  AND (
    first_name ILIKE '%A%' 
    OR last_name ILIKE '%A%' 
    OR email ILIKE '%A%'
  )
ORDER BY first_name; 