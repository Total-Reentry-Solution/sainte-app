-- Care Team Assignments and Invitations Migration
-- This migration creates the necessary tables and functionality for care team assignments

-- 1. Create care_team_invitations table
CREATE TABLE IF NOT EXISTS public.care_team_invitations (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    inviter_id uuid NOT NULL, -- Who is sending the invitation
    invitee_id uuid NOT NULL, -- Who is being invited
    invitation_type text NOT NULL CHECK (invitation_type IN ('care_team_member', 'client_assignment')),
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    message text, -- Optional message from inviter
    reason_for_rejection text, -- Optional reason if rejected
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT care_team_invitations_pkey PRIMARY KEY (id),
    CONSTRAINT care_team_invitations_inviter_id_fkey FOREIGN KEY (inviter_id) REFERENCES auth.users(id),
    CONSTRAINT care_team_invitations_invitee_id_fkey FOREIGN KEY (invitee_id) REFERENCES auth.users(id),
    CONSTRAINT care_team_invitations_unique UNIQUE (inviter_id, invitee_id, invitation_type)
);

-- 2. Create care_team_assignments table for confirmed assignments
CREATE TABLE IF NOT EXISTS public.care_team_assignments (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    care_team_member_id uuid NOT NULL, -- The care team member
    client_id uuid NOT NULL, -- The client/citizen being assigned
    assigned_by uuid NOT NULL, -- Who made the assignment
    assignment_type text NOT NULL CHECK (assignment_type IN ('care_team_member', 'client_assignment')),
    status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'terminated')),
    start_date timestamp with time zone DEFAULT now(),
    end_date timestamp with time zone, -- NULL means ongoing
    notes text, -- Optional notes about the assignment
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT care_team_assignments_pkey PRIMARY KEY (id),
    CONSTRAINT care_team_assignments_care_team_member_id_fkey FOREIGN KEY (care_team_member_id) REFERENCES auth.users(id),
    CONSTRAINT care_team_assignments_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.users(id),
    CONSTRAINT care_team_assignments_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES auth.users(id),
    CONSTRAINT care_team_assignments_unique UNIQUE (care_team_member_id, client_id, assignment_type)
);

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_care_team_invitations_inviter_id ON public.care_team_invitations(inviter_id);
CREATE INDEX IF NOT EXISTS idx_care_team_invitations_invitee_id ON public.care_team_invitations(invitee_id);
CREATE INDEX IF NOT EXISTS idx_care_team_invitations_status ON public.care_team_invitations(status);
CREATE INDEX IF NOT EXISTS idx_care_team_invitations_type ON public.care_team_invitations(invitation_type);

CREATE INDEX IF NOT EXISTS idx_care_team_assignments_care_team_member_id ON public.care_team_assignments(care_team_member_id);
CREATE INDEX IF NOT EXISTS idx_care_team_assignments_client_id ON public.care_team_assignments(client_id);
CREATE INDEX IF NOT EXISTS idx_care_team_assignments_status ON public.care_team_assignments(status);
CREATE INDEX IF NOT EXISTS idx_care_team_assignments_type ON public.care_team_assignments(assignment_type);

-- 4. Add triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_care_team_invitations_updated_at 
    BEFORE UPDATE ON public.care_team_invitations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_care_team_assignments_updated_at 
    BEFORE UPDATE ON public.care_team_assignments 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 5. Enable Row Level Security
ALTER TABLE public.care_team_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.care_team_assignments ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS policies for care_team_invitations
CREATE POLICY "Users can view invitations they're involved in" ON public.care_team_invitations
    FOR SELECT USING (inviter_id = auth.uid() OR invitee_id = auth.uid());

CREATE POLICY "Users can create invitations" ON public.care_team_invitations
    FOR INSERT WITH CHECK (inviter_id = auth.uid());

CREATE POLICY "Invitees can update their invitations" ON public.care_team_invitations
    FOR UPDATE USING (invitee_id = auth.uid());

-- 7. Create RLS policies for care_team_assignments
CREATE POLICY "Users can view assignments they're involved in" ON public.care_team_assignments
    FOR SELECT USING (care_team_member_id = auth.uid() OR client_id = auth.uid() OR assigned_by = auth.uid());

CREATE POLICY "Care team members can create assignments" ON public.care_team_assignments
    FOR INSERT WITH CHECK (assigned_by = auth.uid());

CREATE POLICY "Users can update their assignments" ON public.care_team_assignments
    FOR UPDATE USING (care_team_member_id = auth.uid() OR client_id = auth.uid() OR assigned_by = auth.uid());

-- 8. Grant necessary permissions
GRANT ALL ON public.care_team_invitations TO authenticated;
GRANT ALL ON public.care_team_assignments TO authenticated;
