-- Test query to see what citizens are in the persons table
SELECT 
    person_id,
    first_name,
    last_name,
    email,
    account_status,
    case_status,
    case_manager_id
FROM persons 
WHERE account_status = 'active'
ORDER BY first_name, last_name
LIMIT 20; 