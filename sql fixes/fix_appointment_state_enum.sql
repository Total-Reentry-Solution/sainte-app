-- Fix appointment state values to match the enum values used in the code
-- The code uses: scheduled, accepted, declined, pending
-- But the database default was 'scheduled'

-- Update existing appointments with 'scheduled' state to 'pending'
UPDATE public.appointments 
SET state = 'pending' 
WHERE state = 'scheduled';

-- Update the default value for new appointments
ALTER TABLE public.appointments 
ALTER COLUMN state SET DEFAULT 'pending';

-- Add a check constraint to ensure only valid state values are used
ALTER TABLE public.appointments 
ADD CONSTRAINT appointments_state_check 
CHECK (state IN ('scheduled', 'accepted', 'declined', 'pending'));
