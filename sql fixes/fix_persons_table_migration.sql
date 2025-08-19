-- Fix for using persons table for clients/citizens
-- Run this in your Supabase SQL Editor

-- 1. Ensure persons table has all necessary fields
ALTER TABLE public.persons ADD COLUMN IF NOT EXISTS case_status text DEFAULT 'intake';
ALTER TABLE public.persons ADD COLUMN IF NOT EXISTS account_status text DEFAULT 'active';
ALTER TABLE public.persons ADD COLUMN IF NOT EXISTS case_manager_id uuid;

-- 2. Create client_assignees table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.client_assignees (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    client_id uuid NOT NULL,
    assignee_id uuid NOT NULL,
    status text DEFAULT 'active',
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT client_assignees_pkey PRIMARY KEY (id),
    CONSTRAINT client_assignees_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.persons(person_id),
    CONSTRAINT client_assignees_assignee_id_fkey FOREIGN KEY (assignee_id) REFERENCES auth.users(id)
);

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_persons_case_status ON public.persons(case_status);
CREATE INDEX IF NOT EXISTS idx_persons_account_status ON public.persons(account_status);
CREATE INDEX IF NOT EXISTS idx_client_assignees_client_id ON public.client_assignees(client_id);
CREATE INDEX IF NOT EXISTS idx_client_assignees_assignee_id ON public.client_assignees(assignee_id);
CREATE INDEX IF NOT EXISTS idx_client_assignees_status ON public.client_assignees(status);

-- 4. Add trigger for updated_at on client_assignees table
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_client_assignees_updated_at 
    BEFORE UPDATE ON public.client_assignees 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 5. Grant necessary permissions
GRANT ALL ON public.persons TO authenticated;
GRANT ALL ON public.client_assignees TO authenticated;

-- 6. Insert sample data for testing (optional)
INSERT INTO public.persons (first_name, last_name, email, case_status, account_status) VALUES
('John', 'Doe', 'john.doe@example.com', 'intake', 'active'),
('Jane', 'Smith', 'jane.smith@example.com', 'active', 'active'),
('Mike', 'Johnson', 'mike.johnson@example.com', 'intake', 'active')
ON CONFLICT DO NOTHING; 