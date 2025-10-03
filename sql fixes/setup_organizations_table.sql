-- Setup Organizations Table for Dynamic Creation
-- This script ensures the organizations table exists and allows users to create new organizations

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
    CONSTRAINT organizations_pkey PRIMARY KEY (id),
    CONSTRAINT organizations_name_unique UNIQUE (name)
);

-- 2. Enable RLS on organizations table
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- 3. Create RLS policies for organizations table
DROP POLICY IF EXISTS "Anyone can view organizations" ON public.organizations;
CREATE POLICY "Anyone can view organizations" ON public.organizations
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can create organizations" ON public.organizations;
CREATE POLICY "Authenticated users can create organizations" ON public.organizations
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Service role can manage all organizations" ON public.organizations;
CREATE POLICY "Service role can manage all organizations" ON public.organizations
    FOR ALL USING (auth.role() = 'service_role');

-- 4. Grant permissions
GRANT ALL ON public.organizations TO authenticated;
GRANT ALL ON public.organizations TO anon;
GRANT ALL ON public.organizations TO service_role;

-- 5. Create index for better performance
CREATE INDEX IF NOT EXISTS idx_organizations_name ON public.organizations (name);

-- 6. Verify the table is set up correctly
SELECT 
    'Organizations table setup complete!' as status,
    COUNT(*) as existing_organizations
FROM public.organizations;




