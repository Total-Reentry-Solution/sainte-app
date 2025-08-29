-- Create client_assignees table linking clients to their assignees
CREATE TABLE IF NOT EXISTS public.client_assignees (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id uuid NOT NULL REFERENCES public.persons(person_id) ON DELETE CASCADE,
    assignee_id uuid NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now()
);

-- Indexes to speed up lookups
CREATE INDEX IF NOT EXISTS client_assignees_client_id_idx
    ON public.client_assignees (client_id);
CREATE INDEX IF NOT EXISTS client_assignees_assignee_id_idx
    ON public.client_assignees (assignee_id);

-- Sample data for development/testing
-- Assigns existing users based on their emails. Adjust emails as needed.
INSERT INTO public.client_assignees (client_id, assignee_id)
SELECT p.person_id, a.id
FROM persons p
JOIN user_profiles c ON c.person_id = p.person_id
JOIN user_profiles a ON a.email = 'ahmad.citizen@example.com'
WHERE c.email = 'john.doe@example.com'
ON CONFLICT DO NOTHING;
