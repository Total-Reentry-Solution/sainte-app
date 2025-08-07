-- Simple migration to add personID columns to messages table
-- This version is minimal to test basic functionality

-- Add new columns for personID-based messaging
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS sender_person_id TEXT,
ADD COLUMN IF NOT EXISTS receiver_person_id TEXT,
ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_messages_sender_person_id ON public.messages(sender_person_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_person_id ON public.messages(receiver_person_id);
CREATE INDEX IF NOT EXISTS idx_messages_person_conversation ON public.messages(sender_person_id, receiver_person_id);

-- Note: No RLS policies or foreign key constraints for now
-- This allows us to test basic message insertion 