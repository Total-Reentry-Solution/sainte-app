-- Migration to update messages table to use personID instead of userID
-- This migration adds new columns and updates the table structure

-- Step 1: Add new columns for personID-based messaging
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS sender_person_id UUID,
ADD COLUMN IF NOT EXISTS receiver_person_id UUID,
ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false;

-- Step 1.5: Add foreign key constraints to link to persons table
-- Drop existing constraints if they exist to avoid conflicts
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_messages_sender_person_id') THEN
        ALTER TABLE public.messages DROP CONSTRAINT fk_messages_sender_person_id;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_messages_receiver_person_id') THEN
        ALTER TABLE public.messages DROP CONSTRAINT fk_messages_receiver_person_id;
    END IF;
END $$;

ALTER TABLE public.messages 
ADD CONSTRAINT fk_messages_sender_person_id 
FOREIGN KEY (sender_person_id) REFERENCES public.persons(person_id) ON DELETE CASCADE;

ALTER TABLE public.messages 
ADD CONSTRAINT fk_messages_receiver_person_id 
FOREIGN KEY (receiver_person_id) REFERENCES public.persons(person_id) ON DELETE CASCADE;

-- Step 2: Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_messages_sender_person_id ON public.messages(sender_person_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_person_id ON public.messages(receiver_person_id);
CREATE INDEX IF NOT EXISTS idx_messages_person_conversation ON public.messages(sender_person_id, receiver_person_id);

-- Step 3: Add RLS policies for personID-based access
-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can view messages by personID" ON public.messages;
DROP POLICY IF EXISTS "Users can insert messages by personID" ON public.messages;
DROP POLICY IF EXISTS "Users can update their messages by personID" ON public.messages;

-- Policy for users to see messages where they are sender or receiver by personID
CREATE POLICY "Users can view messages by personID" ON public.messages
    FOR SELECT USING (
        sender_person_id IN (
            SELECT person_id FROM public.user_profiles 
            WHERE id = auth.uid()
        ) OR 
        receiver_person_id IN (
            SELECT person_id FROM public.user_profiles 
            WHERE id = auth.uid()
        )
    );

-- Policy for users to insert messages using personID
CREATE POLICY "Users can insert messages by personID" ON public.messages
    FOR INSERT WITH CHECK (
        sender_person_id IN (
            SELECT person_id FROM public.user_profiles 
            WHERE id = auth.uid()
        )
    );

-- Policy for users to update their own messages
CREATE POLICY "Users can update their messages by personID" ON public.messages
    FOR UPDATE USING (
        sender_person_id IN (
            SELECT person_id FROM public.user_profiles 
            WHERE id = auth.uid()
        )
    );

-- Step 4: Enable RLS on messages table
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Note: The old sender_id and receiver_id columns are kept for backward compatibility
-- You can remove them later after ensuring all code uses the new personID columns 