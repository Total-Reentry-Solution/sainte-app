-- Quick Fix: Add Love Foundation Organization
-- This is a simple script to add just the organization the user needs

-- 1. Create organizations table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.organizations (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    name text NOT NULL,
    address text,
    phone_number text,
    email text,
    website text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT organizations_pkey PRIMARY KEY (id)
);

-- 2. Enable RLS
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- 3. Add basic policies
DROP POLICY IF EXISTS "Anyone can view organizations" ON public.organizations;
CREATE POLICY "Anyone can view organizations" ON public.organizations
    FOR SELECT USING (true);

-- 4. Grant permissions
GRANT ALL ON public.organizations TO authenticated;
GRANT ALL ON public.organizations TO anon;
GRANT ALL ON public.organizations TO service_role;

-- 5. Add Love Foundation organization
INSERT INTO public.organizations (name, address, phone_number, email) VALUES
    ('Love Foundation', '1234 Elm St, Detroit, MI 48227', '(555) 123-4567', 'info@lovefoundation.org')
ON CONFLICT (name) DO NOTHING;

-- 6. Verify it was added
SELECT 
    'Love Foundation added successfully!' as status,
    id,
    name,
    address
FROM public.organizations 
WHERE name = 'Love Foundation';




