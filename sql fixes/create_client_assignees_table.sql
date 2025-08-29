-- Create client_assignees table linking clients (persons) to assignees (user profiles)
CREATE TABLE IF NOT EXISTS public.client_assignees (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    client_id uuid NOT NULL REFERENCES public.persons(person_id) ON DELETE CASCADE,
    assignee_id uuid NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    CONSTRAINT client_assignees_pkey PRIMARY KEY (id),
    CONSTRAINT client_assignees_unique UNIQUE (client_id, assignee_id)
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_client_assignees_client_id ON public.client_assignees(client_id);
CREATE INDEX IF NOT EXISTS idx_client_assignees_assignee_id ON public.client_assignees(assignee_id);

-- Trigger to update updated_at column
CREATE TRIGGER update_client_assignees_updated_at
    BEFORE UPDATE ON public.client_assignees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE public.client_assignees ENABLE ROW LEVEL SECURITY;

