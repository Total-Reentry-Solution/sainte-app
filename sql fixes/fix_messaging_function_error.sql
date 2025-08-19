-- Fix Messaging Function Error - Single File Solution
-- This removes the problematic trigger that's causing the function error

-- Drop the problematic trigger and functions
DROP TRIGGER IF EXISTS validate_person_message_insert ON public.messages;
DROP FUNCTION IF EXISTS validate_person_before_message_insert();
DROP FUNCTION IF EXISTS ensure_person_exists(TEXT);
DROP FUNCTION IF EXISTS ensure_person_exists(UUID);

-- That's it! The app will now work with the code changes we made. 