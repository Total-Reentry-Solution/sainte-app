-- Simple migration to ensure persons table has necessary fields
-- Run this in your Supabase SQL Editor

-- 1. Ensure persons table has all necessary fields
ALTER TABLE public.persons ADD COLUMN IF NOT EXISTS case_status text DEFAULT 'intake';
ALTER TABLE public.persons ADD COLUMN IF NOT EXISTS account_status text DEFAULT 'active';
ALTER TABLE public.persons ADD COLUMN IF NOT EXISTS case_manager_id uuid;

-- 2. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_persons_case_status ON public.persons(case_status);
CREATE INDEX IF NOT EXISTS idx_persons_account_status ON public.persons(account_status);
CREATE INDEX IF NOT EXISTS idx_persons_case_manager_id ON public.persons(case_manager_id);

-- 3. Grant necessary permissions
GRANT ALL ON public.persons TO authenticated;

-- 4. Insert sample data for testing (optional)
INSERT INTO public.persons (first_name, last_name, email, case_status, account_status) VALUES
('John', 'Doe', 'john.doe@example.com', 'intake', 'active'),
('Jane', 'Smith', 'jane.smith@example.com', 'active', 'active'),
('Mike', 'Johnson', 'mike.johnson@example.com', 'intake', 'active')
ON CONFLICT DO NOTHING; 