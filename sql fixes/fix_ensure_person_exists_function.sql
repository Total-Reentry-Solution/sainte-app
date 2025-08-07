-- Fix ensure_person_exists Function Parameter Type Mismatch
-- The function was created with TEXT parameter but is being called with UUID

-- 1. Drop the existing function and trigger
DROP TRIGGER IF EXISTS validate_person_message_insert ON public.messages;
DROP FUNCTION IF EXISTS validate_person_before_message_insert();
DROP FUNCTION IF EXISTS ensure_person_exists(TEXT);

-- 2. Create the function with the correct parameter type (UUID)
CREATE OR REPLACE FUNCTION ensure_person_exists(person_id_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if person exists in persons table
    IF EXISTS (SELECT 1 FROM public.persons WHERE person_id = person_id_uuid::TEXT) THEN
        RETURN TRUE;
    END IF;
    
    -- If not in persons table, check if exists in user_profiles and insert
    IF EXISTS (SELECT 1 FROM public.user_profiles WHERE person_id = person_id_uuid::TEXT) THEN
        INSERT INTO public.persons (person_id, first_name, last_name, email, phone, avatar_url, address, account_type, organizations, created_at, updated_at)
        SELECT 
            person_id,
            first_name,
            last_name,
            email,
            phone,
            avatar_url,
            address,
            account_type::TEXT,
            organizations,
            created_at,
            updated_at
        FROM public.user_profiles 
        WHERE person_id = person_id_uuid::TEXT;
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create the trigger function with the correct parameter handling
CREATE OR REPLACE FUNCTION validate_person_before_message_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate sender_person_id if provided
    IF NEW.sender_person_id IS NOT NULL THEN
        IF NOT ensure_person_exists(NEW.sender_person_id::UUID) THEN
            RAISE EXCEPTION 'Sender person_id does not exist: %', NEW.sender_person_id;
        END IF;
    END IF;
    
    -- Validate receiver_person_id if provided
    IF NEW.receiver_person_id IS NOT NULL THEN
        IF NOT ensure_person_exists(NEW.receiver_person_id::UUID) THEN
            RAISE EXCEPTION 'Receiver person_id does not exist: %', NEW.receiver_person_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Create the trigger
CREATE TRIGGER validate_person_message_insert
  BEFORE INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION validate_person_before_message_insert();

-- 5. Grant necessary permissions
GRANT EXECUTE ON FUNCTION ensure_person_exists(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION validate_person_before_message_insert() TO authenticated;

-- 6. Alternative: If the above doesn't work, let's disable the trigger temporarily
-- This will allow messages to be sent without the validation
-- DROP TRIGGER IF EXISTS validate_person_message_insert ON public.messages;

-- 7. Verification
-- Check if the function exists with the correct signature
SELECT 
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND p.proname = 'ensure_person_exists';

-- Check if the trigger exists
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'validate_person_message_insert'; 