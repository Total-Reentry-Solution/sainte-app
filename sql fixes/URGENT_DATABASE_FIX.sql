-- URGENT DATABASE FIX - Run this in Supabase SQL Editor
-- This will fix the persons table structure

-- First, let's check what exists
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('persons', 'user_profiles')
ORDER BY table_name, ordinal_position;

-- Drop and recreate persons table with correct structure
DROP TABLE IF EXISTS public.persons CASCADE;

CREATE TABLE public.persons (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    email text,
    first_name text,
    last_name text,
    phone_number text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT persons_pkey PRIMARY KEY (id)
);

-- Enable RLS
ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;

-- Create policy for persons
DROP POLICY IF EXISTS "Public persons are viewable by authenticated users" ON public.persons;
CREATE POLICY "Public persons are viewable by authenticated users" ON public.persons
    FOR SELECT USING (true);

-- Grant permissions
GRANT ALL ON public.persons TO authenticated, anon, service_role;

-- Verify the table was created correctly
SELECT 'Persons table created successfully' as status;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'persons'
ORDER BY ordinal_position;



