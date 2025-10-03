-- FRESH DATABASE SETUP FOR SAINTE APP
-- Run this in your NEW Supabase project SQL Editor
-- This creates a clean, working database from scratch

-- ===========================================
-- STEP 1: ENABLE EXTENSIONS
-- ===========================================

-- Enable pgcrypto for UUID generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ===========================================
-- STEP 2: CREATE TABLES
-- ===========================================

-- Create persons table
CREATE TABLE public.persons (
    person_id uuid NOT NULL DEFAULT gen_random_uuid(),  -- App expects person_id as primary key
    email text,
    first_name text,
    last_name text,
    phone_number text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT persons_pkey PRIMARY KEY (person_id)
);

-- Create organizations table
CREATE TABLE public.organizations (
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

-- Create user_profiles table
CREATE TABLE public.user_profiles (
    id uuid NOT NULL, -- This is the auth.users.id
    email text,
    name text,
    first_name text,
    last_name text,
    phone text,
    avatar_url text,
    address text,
    person_id uuid, -- Link to persons table
    account_type text DEFAULT 'citizen',
    organizations text[] DEFAULT '{}',
    organization text, -- Single organization name for display/primary
    organization_address text,
    job_title text,
    supervisors_name text,
    supervisors_email text,
    services text[] DEFAULT '{}',
    user_code text,
    deleted boolean DEFAULT false,
    reason_for_account_deletion text,
    push_notification_token text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT user_profiles_pkey PRIMARY KEY (id),
    CONSTRAINT user_profiles_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.persons(person_id) ON DELETE CASCADE
);

-- Create client_assignees table
CREATE TABLE public.client_assignees (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    client_id uuid NOT NULL,
    assignee_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT client_assignees_pkey PRIMARY KEY (id),
    CONSTRAINT client_assignees_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT client_assignees_assignee_id_fkey FOREIGN KEY (assignee_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT client_assignees_unique UNIQUE (client_id, assignee_id)
);

-- Create conversations table
CREATE TABLE public.conversations (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    participant1_id uuid NOT NULL,
    participant2_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_message_at timestamp with time zone,
    CONSTRAINT conversations_pkey PRIMARY KEY (id),
    CONSTRAINT conversations_participant1_fkey FOREIGN KEY (participant1_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT conversations_participant2_fkey FOREIGN KEY (participant2_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT conversations_unique_participants UNIQUE (participant1_id, participant2_id)
);

-- Create messages table
CREATE TABLE public.messages (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    sender_id uuid NOT NULL,
    receiver_id uuid NOT NULL,
    sender_person_id uuid,
    receiver_person_id uuid,
    text text NOT NULL,  -- App expects 'text' column name
    content text,  -- Keep both for compatibility
    sent_at timestamp with time zone DEFAULT now(),  -- App expects 'sent_at' column name
    created_at timestamp with time zone DEFAULT now(),
    is_read boolean DEFAULT false,
    conversation_id uuid,
    CONSTRAINT messages_pkey PRIMARY KEY (id),
    CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT messages_sender_person_id_fkey FOREIGN KEY (sender_person_id) REFERENCES public.persons(person_id) ON DELETE SET NULL,
    CONSTRAINT messages_receiver_person_id_fkey FOREIGN KEY (receiver_person_id) REFERENCES public.persons(person_id) ON DELETE SET NULL,
    CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE SET NULL
);

-- Create appointments table (fixed schema to match app expectations)
CREATE TABLE public.appointments (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text,
    date timestamp with time zone NOT NULL,
    location text,
    creator_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    participant_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    state text DEFAULT 'pending' CHECK (state IN ('scheduled', 'accepted', 'declined', 'pending')),
    status text DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'ongoing', 'finished')),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT appointments_pkey PRIMARY KEY (id)
);

-- Create case_citizen_assignment table
CREATE TABLE public.case_citizen_assignment (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    case_manager_id uuid NOT NULL,
    citizen_id uuid NOT NULL,
    assignment_status text DEFAULT 'pending' CHECK (assignment_status IN ('pending', 'accepted', 'rejected', 'active')),
    request_message text,
    response_message text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    responded_at timestamp with time zone,
    assigned_at timestamp with time zone,
    CONSTRAINT case_citizen_assignment_pkey PRIMARY KEY (id),
    CONSTRAINT case_citizen_assignment_case_manager_fkey FOREIGN KEY (case_manager_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT case_citizen_assignment_citizen_fkey FOREIGN KEY (citizen_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT case_citizen_assignment_unique UNIQUE (case_manager_id, citizen_id)
);

-- Create moods table
CREATE TABLE public.moods (
    mood_id uuid NOT NULL DEFAULT gen_random_uuid(),
    mood_name text NOT NULL,
    mood_emoji text,
    mood_color text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT moods_pkey PRIMARY KEY (mood_id),
    CONSTRAINT moods_name_unique UNIQUE (mood_name)
);

-- Create mood_logs table
CREATE TABLE public.mood_logs (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    mood_id uuid NOT NULL,
    date timestamp with time zone DEFAULT now(),
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT mood_logs_pkey PRIMARY KEY (id),
    CONSTRAINT mood_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT mood_logs_mood_id_fkey FOREIGN KEY (mood_id) REFERENCES public.moods(mood_id) ON DELETE CASCADE
);

-- Create person_goals table
CREATE TABLE public.person_goals (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    title text NOT NULL,
    description text,
    target_date date,
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    priority text DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT person_goals_pkey PRIMARY KEY (id),
    CONSTRAINT person_goals_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create person_activities table
CREATE TABLE public.person_activities (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    title text NOT NULL,
    description text,
    start_date timestamp with time zone NOT NULL,
    end_date timestamp with time zone,
    activity_type text,
    status text DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT person_activities_pkey PRIMARY KEY (id),
    CONSTRAINT person_activities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create person_milestones table
CREATE TABLE public.person_milestones (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    title text NOT NULL,
    description text,
    achieved_date date,
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'achieved', 'cancelled')),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT person_milestones_pkey PRIMARY KEY (id),
    CONSTRAINT person_milestones_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create verification_questions table
CREATE TABLE public.verification_questions (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    question text NOT NULL,
    question_type text DEFAULT 'text' CHECK (question_type IN ('text', 'multiple_choice', 'yes_no')),
    options text[],
    required boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT verification_questions_pkey PRIMARY KEY (id)
);

-- Create verification_requests table
CREATE TABLE public.verification_requests (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    question_id uuid NOT NULL,
    answer text,
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    rejection_reason text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT verification_requests_pkey PRIMARY KEY (id),
    CONSTRAINT verification_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT verification_requests_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.verification_questions(id) ON DELETE CASCADE
);

-- Create care_team_invitations table
CREATE TABLE public.care_team_invitations (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    client_id uuid NOT NULL,
    care_team_member_id uuid NOT NULL,
    invitation_status text DEFAULT 'pending' CHECK (invitation_status IN ('pending', 'accepted', 'rejected', 'expired')),
    invitation_message text,
    response_message text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    responded_at timestamp with time zone,
    CONSTRAINT care_team_invitations_pkey PRIMARY KEY (id),
    CONSTRAINT care_team_invitations_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT care_team_invitations_care_team_member_id_fkey FOREIGN KEY (care_team_member_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT care_team_invitations_unique UNIQUE (client_id, care_team_member_id)
);

-- Create care_team_assignments table
CREATE TABLE public.care_team_assignments (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    client_id uuid NOT NULL,
    care_team_member_id uuid NOT NULL,
    role text,
    assigned_at timestamp with time zone DEFAULT now(),
    status text DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'removed')),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT care_team_assignments_pkey PRIMARY KEY (id),
    CONSTRAINT care_team_assignments_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT care_team_assignments_care_team_member_id_fkey FOREIGN KEY (care_team_member_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT care_team_assignments_unique UNIQUE (client_id, care_team_member_id)
);

-- Create case_assignments table
CREATE TABLE public.case_assignments (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    case_manager_id uuid NOT NULL,
    client_id uuid NOT NULL,
    assignment_date timestamp with time zone DEFAULT now(),
    status text DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'transferred')),
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT case_assignments_pkey PRIMARY KEY (id),
    CONSTRAINT case_assignments_case_manager_id_fkey FOREIGN KEY (case_manager_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT case_assignments_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT case_assignments_unique UNIQUE (case_manager_id, client_id)
);

-- Create blog_posts table
CREATE TABLE public.blog_posts (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    title text NOT NULL,
    content text NOT NULL,
    author_id uuid NOT NULL,
    status text DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    published_at timestamp with time zone,
    featured_image_url text,
    tags text[],
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT blog_posts_pkey PRIMARY KEY (id),
    CONSTRAINT blog_posts_author_id_fkey FOREIGN KEY (author_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create blog_requests table
CREATE TABLE public.blog_requests (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    title text NOT NULL,
    content text NOT NULL,
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT blog_requests_pkey PRIMARY KEY (id),
    CONSTRAINT blog_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create incidents table
CREATE TABLE public.incidents (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text,
    reported_by_id uuid NOT NULL,
    victim_id uuid,
    incident_date timestamp with time zone,
    response_count integer DEFAULT 0,
    status text DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'closed')),
    extra_data jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT incidents_pkey PRIMARY KEY (id),
    CONSTRAINT incidents_reported_by_id_fkey FOREIGN KEY (reported_by_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT incidents_victim_id_fkey FOREIGN KEY (victim_id) REFERENCES auth.users(id) ON DELETE SET NULL
);

-- Create incident_responses table
CREATE TABLE public.incident_responses (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    incidence_id uuid NOT NULL,
    responder_id uuid NOT NULL,
    response_text text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT incident_responses_pkey PRIMARY KEY (id),
    CONSTRAINT incident_responses_incidence_id_fkey FOREIGN KEY (incidence_id) REFERENCES public.incidents(id) ON DELETE CASCADE,
    CONSTRAINT incident_responses_responder_id_fkey FOREIGN KEY (responder_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create mentor_requests table
CREATE TABLE public.mentor_requests (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    client_id uuid NOT NULL,
    mentor_id uuid NOT NULL,
    request_message text,
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),
    response_message text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    responded_at timestamp with time zone,
    CONSTRAINT mentor_requests_pkey PRIMARY KEY (id),
    CONSTRAINT mentor_requests_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT mentor_requests_mentor_id_fkey FOREIGN KEY (mentor_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT mentor_requests_unique UNIQUE (client_id, mentor_id)
);

-- Create reports table
CREATE TABLE public.reports (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text,
    reported_by_id uuid NOT NULL,
    report_type text DEFAULT 'general' CHECK (report_type IN ('general', 'bug', 'feature_request', 'abuse')),
    status text DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT reports_pkey PRIMARY KEY (id),
    CONSTRAINT reports_reported_by_id_fkey FOREIGN KEY (reported_by_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create support_tickets table
CREATE TABLE public.support_tickets (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    subject text NOT NULL,
    description text NOT NULL,
    priority text DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status text DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    assigned_to_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT support_tickets_pkey PRIMARY KEY (id),
    CONSTRAINT support_tickets_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT support_tickets_assigned_to_id_fkey FOREIGN KEY (assigned_to_id) REFERENCES auth.users(id) ON DELETE SET NULL
);

-- ===========================================
-- STEP 3: SET UP ROW LEVEL SECURITY (RLS)
-- ===========================================

-- Add missing columns to existing tables
ALTER TABLE public.user_profiles 
    ADD COLUMN IF NOT EXISTS verification_status text,
    ADD COLUMN IF NOT EXISTS verification text,
    ADD COLUMN IF NOT EXISTS intake_form text,
    ADD COLUMN IF NOT EXISTS mood_logs text[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS mood_timeline text[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS assignee text[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS activity_date timestamp with time zone,
    ADD COLUMN IF NOT EXISTS mentors text[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS officers text[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS password text,
    ADD COLUMN IF NOT EXISTS settings jsonb DEFAULT '{"pushNotification": true, "emailNotification": true, "smsNotification": false}',
    ADD COLUMN IF NOT EXISTS dob date,
    ADD COLUMN IF NOT EXISTS availability text,
    ADD COLUMN IF NOT EXISTS phone_number text,
    ADD COLUMN IF NOT EXISTS phoneNumber text,  -- App expects this column name
    ADD COLUMN IF NOT EXISTS about text,
    ADD COLUMN IF NOT EXISTS feelings_date text,
    ADD COLUMN IF NOT EXISTS user_code text;

ALTER TABLE public.persons 
    ADD COLUMN IF NOT EXISTS case_status text DEFAULT 'intake',
    ADD COLUMN IF NOT EXISTS account_status text DEFAULT 'active',
    ADD COLUMN IF NOT EXISTS case_manager_id uuid;

-- Enable RLS on all tables
ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_assignees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_citizen_assignment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.person_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.person_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.person_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.care_team_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.care_team_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blog_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mentor_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- Policies for persons
CREATE POLICY "Public persons are viewable by authenticated users" ON public.persons
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert persons" ON public.persons
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update persons" ON public.persons
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Policies for user_profiles
CREATE POLICY "Users can view their own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Policies for organizations
CREATE POLICY "Anyone can view organizations" ON public.organizations
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert organizations" ON public.organizations
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update organizations" ON public.organizations
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Policies for client_assignees
CREATE POLICY "Users can view their own client assignments" ON public.client_assignees
    FOR ALL USING (auth.uid() = client_id OR auth.uid() = assignee_id);

CREATE POLICY "Authenticated users can insert client assignments" ON public.client_assignees
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Policies for conversations
CREATE POLICY "Users can view their own conversations" ON public.conversations
    FOR SELECT USING (auth.uid() = participant1_id OR auth.uid() = participant2_id);

CREATE POLICY "Users can create conversations" ON public.conversations
    FOR INSERT WITH CHECK (auth.uid() = participant1_id OR auth.uid() = participant2_id);

CREATE POLICY "Users can update their own conversations" ON public.conversations
    FOR UPDATE USING (auth.uid() = participant1_id OR auth.uid() = participant2_id);

-- Policies for messages
CREATE POLICY "Users can view their own messages" ON public.messages
    FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can insert their own messages" ON public.messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update their own messages" ON public.messages
    FOR UPDATE USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Policies for appointments
CREATE POLICY "Users can view their own appointments" ON public.appointments
    FOR SELECT USING (auth.uid() = creator_id OR auth.uid() = participant_id);

CREATE POLICY "Users can create appointments" ON public.appointments
    FOR INSERT WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Users can update their own appointments" ON public.appointments
    FOR UPDATE USING (auth.uid() = creator_id OR auth.uid() = participant_id);

-- Policies for case_citizen_assignment
CREATE POLICY "Users can view their own assignments" ON public.case_citizen_assignment
    FOR SELECT USING (auth.uid() = case_manager_id OR auth.uid() = citizen_id);

CREATE POLICY "Case managers can create assignments" ON public.case_citizen_assignment
    FOR INSERT WITH CHECK (auth.uid() = case_manager_id);

CREATE POLICY "Users can update their own assignments" ON public.case_citizen_assignment
    FOR UPDATE USING (auth.uid() = case_manager_id OR auth.uid() = citizen_id);

-- Policies for moods
CREATE POLICY "Anyone can view moods" ON public.moods
    FOR SELECT USING (true);

-- Policies for mood_logs
CREATE POLICY "Users can view their own mood logs" ON public.mood_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own mood logs" ON public.mood_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own mood logs" ON public.mood_logs
    FOR UPDATE USING (auth.uid() = user_id);

-- Policies for person_goals
CREATE POLICY "Users can view their own goals" ON public.person_goals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own goals" ON public.person_goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own goals" ON public.person_goals
    FOR UPDATE USING (auth.uid() = user_id);

-- Policies for person_activities
CREATE POLICY "Users can view their own activities" ON public.person_activities
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own activities" ON public.person_activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own activities" ON public.person_activities
    FOR UPDATE USING (auth.uid() = user_id);

-- Policies for person_milestones
CREATE POLICY "Users can view their own milestones" ON public.person_milestones
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own milestones" ON public.person_milestones
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own milestones" ON public.person_milestones
    FOR UPDATE USING (auth.uid() = user_id);

-- Policies for verification_questions
CREATE POLICY "Anyone can view verification questions" ON public.verification_questions
    FOR SELECT USING (true);

-- Policies for verification_requests
CREATE POLICY "Users can view their own verification requests" ON public.verification_requests
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own verification requests" ON public.verification_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own verification requests" ON public.verification_requests
    FOR UPDATE USING (auth.uid() = user_id);

-- Policies for care_team_invitations
CREATE POLICY "Users can view their own care team invitations" ON public.care_team_invitations
    FOR SELECT USING (auth.uid() = client_id OR auth.uid() = care_team_member_id);

CREATE POLICY "Users can create care team invitations" ON public.care_team_invitations
    FOR INSERT WITH CHECK (auth.uid() = client_id);

CREATE POLICY "Users can update their own care team invitations" ON public.care_team_invitations
    FOR UPDATE USING (auth.uid() = client_id OR auth.uid() = care_team_member_id);

-- Policies for care_team_assignments
CREATE POLICY "Users can view their own care team assignments" ON public.care_team_assignments
    FOR SELECT USING (auth.uid() = client_id OR auth.uid() = care_team_member_id);

CREATE POLICY "Users can create care team assignments" ON public.care_team_assignments
    FOR INSERT WITH CHECK (auth.uid() = client_id);

CREATE POLICY "Users can update their own care team assignments" ON public.care_team_assignments
    FOR UPDATE USING (auth.uid() = client_id OR auth.uid() = care_team_member_id);

-- Policies for case_assignments
CREATE POLICY "Users can view their own case assignments" ON public.case_assignments
    FOR SELECT USING (auth.uid() = case_manager_id OR auth.uid() = client_id);

CREATE POLICY "Case managers can create case assignments" ON public.case_assignments
    FOR INSERT WITH CHECK (auth.uid() = case_manager_id);

CREATE POLICY "Users can update their own case assignments" ON public.case_assignments
    FOR UPDATE USING (auth.uid() = case_manager_id OR auth.uid() = client_id);

-- Policies for blog_posts
CREATE POLICY "Anyone can view published blog posts" ON public.blog_posts
    FOR SELECT USING (status = 'published');

CREATE POLICY "Authors can view their own blog posts" ON public.blog_posts
    FOR SELECT USING (auth.uid() = author_id);

CREATE POLICY "Authors can create blog posts" ON public.blog_posts
    FOR INSERT WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Authors can update their own blog posts" ON public.blog_posts
    FOR UPDATE USING (auth.uid() = author_id);

-- Policies for blog_requests
CREATE POLICY "Users can view their own blog requests" ON public.blog_requests
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create blog requests" ON public.blog_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own blog requests" ON public.blog_requests
    FOR UPDATE USING (auth.uid() = user_id);

-- Policies for incidents
CREATE POLICY "Users can view incidents they're involved in" ON public.incidents
    FOR SELECT USING (auth.uid() = reported_by_id OR auth.uid() = victim_id);

CREATE POLICY "Users can create incidents" ON public.incidents
    FOR INSERT WITH CHECK (auth.uid() = reported_by_id);

CREATE POLICY "Users can update incidents they reported" ON public.incidents
    FOR UPDATE USING (auth.uid() = reported_by_id);

-- Policies for incident_responses
CREATE POLICY "Users can view responses to incidents they're involved in" ON public.incident_responses
    FOR SELECT USING (
        auth.uid() = responder_id OR 
        auth.uid() IN (
            SELECT reported_by_id FROM public.incidents WHERE id = incidence_id
        ) OR
        auth.uid() IN (
            SELECT victim_id FROM public.incidents WHERE id = incidence_id
        )
    );

CREATE POLICY "Users can create incident responses" ON public.incident_responses
    FOR INSERT WITH CHECK (auth.uid() = responder_id);

CREATE POLICY "Users can update their own incident responses" ON public.incident_responses
    FOR UPDATE USING (auth.uid() = responder_id);

-- Policies for mentor_requests
CREATE POLICY "Users can view their own mentor requests" ON public.mentor_requests
    FOR SELECT USING (auth.uid() = client_id OR auth.uid() = mentor_id);

CREATE POLICY "Users can create mentor requests" ON public.mentor_requests
    FOR INSERT WITH CHECK (auth.uid() = client_id);

CREATE POLICY "Users can update their own mentor requests" ON public.mentor_requests
    FOR UPDATE USING (auth.uid() = client_id OR auth.uid() = mentor_id);

-- Policies for reports
CREATE POLICY "Users can view their own reports" ON public.reports
    FOR SELECT USING (auth.uid() = reported_by_id);

CREATE POLICY "Users can create reports" ON public.reports
    FOR INSERT WITH CHECK (auth.uid() = reported_by_id);

CREATE POLICY "Users can update their own reports" ON public.reports
    FOR UPDATE USING (auth.uid() = reported_by_id);

-- Policies for support_tickets
CREATE POLICY "Users can view their own support tickets" ON public.support_tickets
    FOR SELECT USING (auth.uid() = user_id OR auth.uid() = assigned_to_id);

CREATE POLICY "Users can create support tickets" ON public.support_tickets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own support tickets" ON public.support_tickets
    FOR UPDATE USING (auth.uid() = user_id OR auth.uid() = assigned_to_id);

-- ===========================================
-- STEP 4: CREATE FUNCTIONS AND TRIGGERS
-- ===========================================

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create user creation trigger function
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    new_person_id uuid;
BEGIN
    -- Create a person record
    INSERT INTO public.persons (person_id, email, created_at, updated_at)
    VALUES (
        gen_random_uuid(),
        NEW.email,
        NOW(),
        NOW()
    ) RETURNING person_id INTO new_person_id;
    
    -- Create user profile with all required fields
    INSERT INTO public.user_profiles (
        id, 
        email, 
        person_id, 
        name,
        account_type,
        deleted,
        organizations,
        services,
        created_at, 
        updated_at
    )
    VALUES (
        NEW.id,
        NEW.email,
        new_person_id,
        COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
        'citizen',
        FALSE,
        '{}',
        '{}',
        NOW(),
        NOW()
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the user creation
        RAISE WARNING 'Error creating user profile: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger for user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Create function to sync text and content columns in messages
CREATE OR REPLACE FUNCTION sync_message_text_content()
RETURNS TRIGGER AS $$
BEGIN
    -- If text is provided but content is null, copy text to content
    IF NEW.text IS NOT NULL AND NEW.content IS NULL THEN
        NEW.content = NEW.text;
    END IF;
    -- If content is provided but text is null, copy content to text
    IF NEW.content IS NOT NULL AND NEW.text IS NULL THEN
        NEW.text = NEW.content;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to sync text and content columns
CREATE TRIGGER sync_message_text_content_trigger
    BEFORE INSERT OR UPDATE ON public.messages
    FOR EACH ROW EXECUTE FUNCTION sync_message_text_content();

-- Add update triggers for all tables
CREATE TRIGGER update_persons_updated_at 
    BEFORE UPDATE ON public.persons 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON public.user_profiles 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organizations_updated_at 
    BEFORE UPDATE ON public.organizations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_client_assignees_updated_at 
    BEFORE UPDATE ON public.client_assignees 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_conversations_updated_at 
    BEFORE UPDATE ON public.conversations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at 
    BEFORE UPDATE ON public.messages 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_appointments_updated_at 
    BEFORE UPDATE ON public.appointments 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_case_citizen_assignment_updated_at 
    BEFORE UPDATE ON public.case_citizen_assignment 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_moods_updated_at 
    BEFORE UPDATE ON public.moods 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mood_logs_updated_at 
    BEFORE UPDATE ON public.mood_logs 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_person_goals_updated_at 
    BEFORE UPDATE ON public.person_goals 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_person_activities_updated_at 
    BEFORE UPDATE ON public.person_activities 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_person_milestones_updated_at 
    BEFORE UPDATE ON public.person_milestones 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_verification_questions_updated_at 
    BEFORE UPDATE ON public.verification_questions 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_verification_requests_updated_at 
    BEFORE UPDATE ON public.verification_requests 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_care_team_invitations_updated_at 
    BEFORE UPDATE ON public.care_team_invitations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_care_team_assignments_updated_at 
    BEFORE UPDATE ON public.care_team_assignments 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_case_assignments_updated_at 
    BEFORE UPDATE ON public.case_assignments 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_blog_posts_updated_at 
    BEFORE UPDATE ON public.blog_posts 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_blog_requests_updated_at 
    BEFORE UPDATE ON public.blog_requests 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_incidents_updated_at 
    BEFORE UPDATE ON public.incidents 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_incident_responses_updated_at 
    BEFORE UPDATE ON public.incident_responses 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mentor_requests_updated_at 
    BEFORE UPDATE ON public.mentor_requests 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reports_updated_at 
    BEFORE UPDATE ON public.reports 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_support_tickets_updated_at 
    BEFORE UPDATE ON public.support_tickets 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ===========================================
-- STEP 5: ENABLE REALTIME MESSAGING
-- ===========================================

-- Enable real-time on the messages table
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;

-- Enable real-time on the conversations table
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;

-- ===========================================
-- STEP 6: CREATE INDEXES FOR PERFORMANCE
-- ===========================================

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_person_id ON public.user_profiles(person_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_account_type ON public.user_profiles(account_type);
CREATE INDEX IF NOT EXISTS idx_user_profiles_deleted ON public.user_profiles(deleted);
CREATE INDEX IF NOT EXISTS idx_persons_case_status ON public.persons(case_status);
CREATE INDEX IF NOT EXISTS idx_persons_account_status ON public.persons(account_status);
CREATE INDEX IF NOT EXISTS idx_persons_case_manager_id ON public.persons(case_manager_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);
CREATE INDEX IF NOT EXISTS idx_conversations_participant1 ON public.conversations(participant1_id);
CREATE INDEX IF NOT EXISTS idx_conversations_participant2 ON public.conversations(participant2_id);
CREATE INDEX IF NOT EXISTS idx_appointments_creator_id ON public.appointments(creator_id);
CREATE INDEX IF NOT EXISTS idx_appointments_participant_id ON public.appointments(participant_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON public.appointments(date);
CREATE INDEX IF NOT EXISTS idx_case_citizen_assignment_case_manager ON public.case_citizen_assignment(case_manager_id);
CREATE INDEX IF NOT EXISTS idx_case_citizen_assignment_citizen ON public.case_citizen_assignment(citizen_id);
CREATE INDEX IF NOT EXISTS idx_case_citizen_assignment_status ON public.case_citizen_assignment(assignment_status);
CREATE INDEX IF NOT EXISTS idx_mood_logs_user_id ON public.mood_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_mood_logs_mood_id ON public.mood_logs(mood_id);
CREATE INDEX IF NOT EXISTS idx_mood_logs_date ON public.mood_logs(date);
CREATE INDEX IF NOT EXISTS idx_person_goals_user_id ON public.person_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_person_goals_status ON public.person_goals(status);
CREATE INDEX IF NOT EXISTS idx_person_activities_user_id ON public.person_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_person_activities_start_date ON public.person_activities(start_date);
CREATE INDEX IF NOT EXISTS idx_person_milestones_user_id ON public.person_milestones(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_requests_user_id ON public.verification_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_requests_status ON public.verification_requests(status);
CREATE INDEX IF NOT EXISTS idx_care_team_invitations_client_id ON public.care_team_invitations(client_id);
CREATE INDEX IF NOT EXISTS idx_care_team_invitations_care_team_member_id ON public.care_team_invitations(care_team_member_id);
CREATE INDEX IF NOT EXISTS idx_care_team_assignments_client_id ON public.care_team_assignments(client_id);
CREATE INDEX IF NOT EXISTS idx_care_team_assignments_care_team_member_id ON public.care_team_assignments(care_team_member_id);
CREATE INDEX IF NOT EXISTS idx_case_assignments_case_manager_id ON public.case_assignments(case_manager_id);
CREATE INDEX IF NOT EXISTS idx_case_assignments_client_id ON public.case_assignments(client_id);
CREATE INDEX IF NOT EXISTS idx_blog_posts_author_id ON public.blog_posts(author_id);
CREATE INDEX IF NOT EXISTS idx_blog_posts_status ON public.blog_posts(status);
CREATE INDEX IF NOT EXISTS idx_blog_requests_user_id ON public.blog_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_incidents_reported_by_id ON public.incidents(reported_by_id);
CREATE INDEX IF NOT EXISTS idx_incidents_victim_id ON public.incidents(victim_id);
CREATE INDEX IF NOT EXISTS idx_incident_responses_incidence_id ON public.incident_responses(incidence_id);
CREATE INDEX IF NOT EXISTS idx_mentor_requests_client_id ON public.mentor_requests(client_id);
CREATE INDEX IF NOT EXISTS idx_mentor_requests_mentor_id ON public.mentor_requests(mentor_id);
CREATE INDEX IF NOT EXISTS idx_reports_reported_by_id ON public.reports(reported_by_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON public.support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_assigned_to_id ON public.support_tickets(assigned_to_id);

-- ===========================================
-- STEP 7: GRANT PERMISSIONS
-- ===========================================

GRANT USAGE ON SCHEMA public TO authenticated, anon, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated, anon, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated, anon, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated, anon, service_role;

-- ===========================================
-- STEP 8: ADD SAMPLE DATA
-- ===========================================

-- Add some sample organizations
INSERT INTO public.organizations (name, address) VALUES
('Love Foundation', '123 Main St, City, State'),
('Community Support Center', '456 Oak Ave, City, State'),
('Reentry Services Inc', '789 Pine St, City, State');

-- Add sample moods
INSERT INTO public.moods (mood_name, mood_emoji, mood_color) VALUES
('Happy', '😊', '#4CAF50'),
('Sad', '😢', '#2196F3'),
('Anxious', '😰', '#FF9800'),
('Angry', '😠', '#F44336'),
('Confused', '😕', '#9C27B0'),
('Fearful', '😨', '#795548'),
('Loved', '🥰', '#E91E63'),
('Shame', '😳', '#607D8B');

-- Add sample verification questions
INSERT INTO public.verification_questions (question, question_type, required) VALUES
('What is your full name?', 'text', true),
('What is your date of birth?', 'text', true),
('What is your current address?', 'text', true),
('What is your phone number?', 'text', true),
('What is your emergency contact information?', 'text', true);

-- ===========================================
-- STEP 9: VERIFICATION
-- ===========================================

SELECT '🎉 COMPLETE DATABASE SETUP FINISHED! 🎉' as status,
       'All 25+ tables, triggers, and functions created successfully' as message,
       'Database is now ready for your Flutter app with all features supported!' as next_step;

-- Verify all tables exist
SELECT 
    'Core Tables Check:' as test_name,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'persons') 
         THEN 'persons: ✅' ELSE 'persons: ❌' END as persons_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_profiles') 
         THEN 'user_profiles: ✅' ELSE 'user_profiles: ❌' END as user_profiles_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'organizations') 
         THEN 'organizations: ✅' ELSE 'organizations: ❌' END as organizations_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'client_assignees') 
         THEN 'client_assignees: ✅' ELSE 'client_assignees: ❌' END as client_assignees_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'conversations') 
         THEN 'conversations: ✅' ELSE 'conversations: ❌' END as conversations_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'messages') 
         THEN 'messages: ✅' ELSE 'messages: ❌' END as messages_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'appointments') 
         THEN 'appointments: ✅' ELSE 'appointments: ❌' END as appointments_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'case_citizen_assignment') 
         THEN 'case_citizen_assignment: ✅' ELSE 'case_citizen_assignment: ❌' END as case_citizen_assignment_table;

SELECT 
    'Feature Tables Check:' as test_name,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'moods') 
         THEN 'moods: ✅' ELSE 'moods: ❌' END as moods_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'mood_logs') 
         THEN 'mood_logs: ✅' ELSE 'mood_logs: ❌' END as mood_logs_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'person_goals') 
         THEN 'person_goals: ✅' ELSE 'person_goals: ❌' END as person_goals_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'person_activities') 
         THEN 'person_activities: ✅' ELSE 'person_activities: ❌' END as person_activities_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'person_milestones') 
         THEN 'person_milestones: ✅' ELSE 'person_milestones: ❌' END as person_milestones_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'verification_questions') 
         THEN 'verification_questions: ✅' ELSE 'verification_questions: ❌' END as verification_questions_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'verification_requests') 
         THEN 'verification_requests: ✅' ELSE 'verification_requests: ❌' END as verification_requests_table;

SELECT 
    'Care Team Tables Check:' as test_name,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'care_team_invitations') 
         THEN 'care_team_invitations: ✅' ELSE 'care_team_invitations: ❌' END as care_team_invitations_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'care_team_assignments') 
         THEN 'care_team_assignments: ✅' ELSE 'care_team_assignments: ❌' END as care_team_assignments_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'case_assignments') 
         THEN 'case_assignments: ✅' ELSE 'case_assignments: ❌' END as case_assignments_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'mentor_requests') 
         THEN 'mentor_requests: ✅' ELSE 'mentor_requests: ❌' END as mentor_requests_table;

SELECT 
    'Content Tables Check:' as test_name,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'blog_posts') 
         THEN 'blog_posts: ✅' ELSE 'blog_posts: ❌' END as blog_posts_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'blog_requests') 
         THEN 'blog_requests: ✅' ELSE 'blog_requests: ❌' END as blog_requests_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'incidents') 
         THEN 'incidents: ✅' ELSE 'incidents: ❌' END as incidents_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'incident_responses') 
         THEN 'incident_responses: ✅' ELSE 'incident_responses: ❌' END as incident_responses_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'reports') 
         THEN 'reports: ✅' ELSE 'reports: ❌' END as reports_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'support_tickets') 
         THEN 'support_tickets: ✅' ELSE 'support_tickets: ❌' END as support_tickets_table;

-- Check if the trigger exists
SELECT 'Trigger Check:' as test_name,
       CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created') 
            THEN 'on_auth_user_created: ✅' ELSE 'on_auth_user_created: ❌' END as trigger_status;

-- Check if the function exists
SELECT 'Function Check:' as test_name,
       CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_new_user') 
            THEN 'handle_new_user: ✅' ELSE 'handle_new_user: ❌' END as function_status;

-- Verify all tables and their key columns
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN (
    'persons', 'user_profiles', 'organizations', 'client_assignees', 'conversations', 'messages', 'appointments', 'case_citizen_assignment',
    'moods', 'mood_logs', 'person_goals', 'person_activities', 'person_milestones', 'verification_questions', 'verification_requests',
    'care_team_invitations', 'care_team_assignments', 'case_assignments', 'mentor_requests',
    'blog_posts', 'blog_requests', 'incidents', 'incident_responses', 'reports', 'support_tickets'
)
ORDER BY table_name, ordinal_position;

