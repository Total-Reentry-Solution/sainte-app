-- Migration to add person_id to user_profiles and create person records for existing users

-- First, add the person_id column to user_profiles table
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS person_id uuid;

-- Create person records for existing users who don't have one
INSERT INTO public.persons (person_id, email, created_at, updated_at)
SELECT 
    gen_random_uuid(),
    up.email,
    up.created_at,
    up.updated_at
FROM public.user_profiles up
WHERE up.person_id IS NULL
ON CONFLICT DO NOTHING;

-- Update user_profiles to link to the newly created person records
UPDATE public.user_profiles 
SET person_id = p.person_id
FROM public.persons p
WHERE public.user_profiles.email = p.email 
AND public.user_profiles.person_id IS NULL;

-- Add the foreign key constraint
ALTER TABLE public.user_profiles 
ADD CONSTRAINT IF NOT EXISTS user_profiles_person_id_fkey 
FOREIGN KEY (person_id) REFERENCES public.persons(person_id); 