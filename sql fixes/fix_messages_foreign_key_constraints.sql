-- Fix Messages Table Foreign Key Constraints
-- This migration makes the foreign key constraints optional to support dual ID messaging

-- 1. Drop existing foreign key constraints
ALTER TABLE public.messages 
DROP CONSTRAINT IF EXISTS messages_sender_id_fkey;

ALTER TABLE public.messages 
DROP CONSTRAINT IF EXISTS messages_receiver_id_fkey;

-- 2. Add new foreign key constraints that allow NULL values
-- This allows messages to be sent using personID even if userID doesn't exist

-- For sender_id - make it optional but validate if present
ALTER TABLE public.messages 
ADD CONSTRAINT messages_sender_id_fkey 
FOREIGN KEY (sender_id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE;

-- For receiver_id - make it optional but validate if present
ALTER TABLE public.messages 
ADD CONSTRAINT messages_receiver_id_fkey 
FOREIGN KEY (receiver_id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE;

-- 3. Update RLS policies to handle both personID and userID scenarios
DROP POLICY IF EXISTS "Users can view their messages" ON public.messages;
CREATE POLICY "Users can view their messages" ON public.messages
  FOR SELECT USING (
    -- Allow viewing if user is sender or receiver by userID
    sender_id = auth.uid() OR receiver_id = auth.uid()
    OR
    -- Allow viewing if user is sender or receiver by personID
    sender_person_id = (
      SELECT person_id FROM public.user_profiles 
      WHERE id = auth.uid()
    )
    OR
    receiver_person_id = (
      SELECT person_id FROM public.user_profiles 
      WHERE id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can insert messages" ON public.messages;
CREATE POLICY "Users can insert messages" ON public.messages
  FOR INSERT WITH CHECK (
    -- Allow inserting if user is the sender by userID
    sender_id = auth.uid()
    OR
    -- Allow inserting if user is the sender by personID
    sender_person_id = (
      SELECT person_id FROM public.user_profiles 
      WHERE id = auth.uid()
    )
  );

-- 4. Create a function to validate message recipients
CREATE OR REPLACE FUNCTION validate_message_recipient(
  sender_user_id UUID,
  receiver_user_id UUID DEFAULT NULL,
  receiver_person_id TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
  -- If receiver_user_id is provided, check if it exists in auth.users
  IF receiver_user_id IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = receiver_user_id) THEN
      RETURN FALSE;
    END IF;
  END IF;
  
  -- If receiver_person_id is provided, check if it exists in user_profiles
  IF receiver_person_id IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM public.user_profiles WHERE person_id = receiver_person_id) THEN
      RETURN FALSE;
    END IF;
  END IF;
  
  -- At least one valid recipient must be provided
  IF receiver_user_id IS NULL AND receiver_person_id IS NULL THEN
    RETURN FALSE;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Create a trigger to validate message recipients before insertion
CREATE OR REPLACE FUNCTION validate_message_before_insert()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate the message recipient
  IF NOT validate_message_recipient(
    NEW.sender_id,
    NEW.receiver_id,
    NEW.receiver_person_id
  ) THEN
    RAISE EXCEPTION 'Invalid message recipient: receiver_id or receiver_person_id must be valid';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS validate_message_insert ON public.messages;

-- Create the trigger
CREATE TRIGGER validate_message_insert
  BEFORE INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION validate_message_before_insert();

-- 6. Create a function to get valid recipients for a user
CREATE OR REPLACE FUNCTION get_valid_message_recipients(current_user_id UUID)
RETURNS TABLE (
  user_id UUID,
  person_id TEXT,
  name TEXT,
  avatar_url TEXT,
  account_type TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    up.id as user_id,
    up.person_id,
    CONCAT(up.first_name, ' ', up.last_name) as name,
    up.avatar_url,
    up.account_type::TEXT
  FROM public.user_profiles up
  WHERE up.id != current_user_id
    AND up.id IS NOT NULL
  ORDER BY up.first_name, up.last_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Grant necessary permissions
GRANT EXECUTE ON FUNCTION validate_message_recipient(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_valid_message_recipients(UUID) TO authenticated;

-- 8. Create an index for better performance on person_id lookups
CREATE INDEX IF NOT EXISTS idx_messages_sender_person_id ON public.messages(sender_person_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_person_id ON public.messages(receiver_person_id);

-- 9. Update the existing messages to ensure they have valid data
-- This will help with existing messages that might have invalid foreign keys
UPDATE public.messages 
SET receiver_id = sender_id 
WHERE receiver_id IS NULL OR receiver_id NOT IN (SELECT id FROM auth.users);

-- 10. Final verification
-- Check if the constraints are properly set
SELECT 
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'messages';

-- Check if indexes are created
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'messages' 
  AND indexname LIKE '%person_id%'; 