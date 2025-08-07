-- Fix appointment status values to match the enum values used in the code
-- The code uses: all, upcoming, missed, done, canceled
-- But the database default was 'active'

-- Update existing appointments with 'active' status to 'upcoming'
UPDATE public.appointments 
SET status = 'upcoming' 
WHERE status = 'active';

-- Update the default value for new appointments
ALTER TABLE public.appointments 
ALTER COLUMN status SET DEFAULT 'upcoming';

-- Add a check constraint to ensure only valid status values are used
ALTER TABLE public.appointments 
ADD CONSTRAINT appointments_status_check 
CHECK (status IN ('all', 'upcoming', 'missed', 'done', 'canceled'));
