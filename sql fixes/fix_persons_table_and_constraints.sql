-- Fix Persons Table and Foreign Key Constraints
-- This migration addresses the "fk_messages_sender_person_id" error

-- 1. First, let's check if the persons table exists and what it contains
-- If it doesn't exist, we'll create it based on user_profiles data

-- Check if persons table exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'persons') THEN
        -- Create persons table based on user_profiles data
        CREATE TABLE public.persons (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            person_id TEXT UNIQUE NOT NULL,
            first_name TEXT,
            last_name TEXT,
            email TEXT,
            phone TEXT,
            avatar_url TEXT,
            address TEXT,
            account_type TEXT,
            organizations TEXT[],
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        
        -- Insert data from user_profiles into persons table
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
        WHERE person_id IS NOT NULL;
        
        -- Create indexes for better performance
        CREATE INDEX idx_persons_person_id ON public.persons(person_id);
        CREATE INDEX idx_persons_email ON public.persons(email);
        
        -- Enable RLS
        ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;
        
        -- Create RLS policies
        CREATE POLICY "Users can view persons" ON public.persons
            FOR SELECT USING (true);
            
        CREATE POLICY "Users can insert persons" ON public.persons
            FOR INSERT WITH CHECK (true);
            
        CREATE POLICY "Users can update their own person record" ON public.persons
            FOR UPDATE USING (person_id IN (
                SELECT person_id FROM public.user_profiles WHERE id = auth.uid()
            ));
    END IF;
END $$;

-- 2. Update existing messages to populate person_id fields
-- First, let's update sender_person_id based on sender_id
UPDATE public.messages 
SET sender_person_id = (
    SELECT person_id 
    FROM public.user_profiles 
    WHERE id = messages.sender_id
)
WHERE sender_person_id IS NULL 
AND sender_id IS NOT NULL;

-- Update receiver_person_id based on receiver_id
UPDATE public.messages 
SET receiver_person_id = (
    SELECT person_id 
    FROM public.user_profiles 
    WHERE id = messages.receiver_id
)
WHERE receiver_person_id IS NULL 
AND receiver_id IS NOT NULL;

-- 3. Drop existing foreign key constraints that are causing issues
ALTER TABLE public.messages 
DROP CONSTRAINT IF EXISTS fk_messages_sender_person_id;

ALTER TABLE public.messages 
DROP CONSTRAINT IF EXISTS fk_messages_receiver_person_id;

-- 4. Add new foreign key constraints that reference the correct tables
-- For sender_person_id - reference persons table
ALTER TABLE public.messages 
ADD CONSTRAINT fk_messages_sender_person_id 
FOREIGN KEY (sender_person_id) 
REFERENCES public.persons(person_id) 
ON DELETE CASCADE;

-- For receiver_person_id - reference persons table  
ALTER TABLE public.messages 
ADD CONSTRAINT fk_messages_receiver_person_id 
FOREIGN KEY (receiver_person_id) 
REFERENCES public.persons(person_id) 
ON DELETE CASCADE;

-- 5. Update RLS policies to handle both personID and userID scenarios
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

-- 6. Create a function to ensure person_id exists before inserting messages
CREATE OR REPLACE FUNCTION ensure_person_exists(person_id_text TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if person exists in persons table
    IF EXISTS (SELECT 1 FROM public.persons WHERE person_id = person_id_text) THEN
        RETURN TRUE;
    END IF;
    
    -- If not in persons table, check if exists in user_profiles and insert
    IF EXISTS (SELECT 1 FROM public.user_profiles WHERE person_id = person_id_text) THEN
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
        WHERE person_id = person_id_text;
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Create a trigger to ensure person_id exists before message insertion
CREATE OR REPLACE FUNCTION validate_person_before_message_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate sender_person_id if provided
    IF NEW.sender_person_id IS NOT NULL THEN
        IF NOT ensure_person_exists(NEW.sender_person_id) THEN
            RAISE EXCEPTION 'Sender person_id does not exist: %', NEW.sender_person_id;
        END IF;
    END IF;
    
    -- Validate receiver_person_id if provided
    IF NEW.receiver_person_id IS NOT NULL THEN
        IF NOT ensure_person_exists(NEW.receiver_person_id) THEN
            RAISE EXCEPTION 'Receiver person_id does not exist: %', NEW.receiver_person_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS validate_person_message_insert ON public.messages;

-- Create the trigger
CREATE TRIGGER validate_person_message_insert
  BEFORE INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION validate_person_before_message_insert();

-- 8. Grant necessary permissions
GRANT EXECUTE ON FUNCTION ensure_person_exists(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION validate_person_before_message_insert() TO authenticated;

-- 9. Final verification queries
-- Check if persons table exists and has data
SELECT 'Persons table exists' as status, COUNT(*) as count FROM public.persons;

-- Check messages with person_id fields
SELECT 
    'Messages with sender_person_id' as type,
    COUNT(*) as count 
FROM public.messages 
WHERE sender_person_id IS NOT NULL
UNION ALL
SELECT 
    'Messages with receiver_person_id' as type,
    COUNT(*) as count 
FROM public.messages 
WHERE receiver_person_id IS NOT NULL;

-- Check foreign key constraints
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
  AND tc.table_name = 'messages'
  AND kcu.column_name LIKE '%person_id%'; 