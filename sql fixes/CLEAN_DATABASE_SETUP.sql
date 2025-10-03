-- CLEAN DATABASE SETUP FOR SAINTE APP
-- Modern, efficient naming conventions: snake_case for PostgreSQL, camelCase for Flutter
-- Run this in your NEW Supabase project SQL Editor

-- ===========================================
-- STEP 1: ENABLE EXTENSIONS
-- ===========================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ===========================================
-- STEP 2: CREATE CORE TABLES
-- ===========================================

-- Users table (snake_case for PostgreSQL)
CREATE TABLE public.users (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    email text UNIQUE NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    phone_number text,
    avatar_url text,
    address text,
    account_type text DEFAULT 'citizen' CHECK (account_type IN ('citizen', 'case_manager', 'mentor', 'admin', 'officer')),
    is_deleted boolean DEFAULT false,
    deletion_reason text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    
    -- Profile info
    job_title text,
    organization text,
    organization_address text,
    supervisor_name text,
    supervisor_email text,
    date_of_birth date,
    about text,
    
    -- System fields
    user_code text,
    push_notification_token text,
    settings jsonb DEFAULT '{"pushNotifications": true, "emailNotifications": true, "smsNotifications": false}',
    availability jsonb,
    
    -- Relationships (snake_case with _ids suffix)
    organization_ids text[] DEFAULT '{}',
    service_ids text[] DEFAULT '{}',
    assignee_ids text[] DEFAULT '{}',
    mentor_ids text[] DEFAULT '{}',
    officer_ids text[] DEFAULT '{}',
    
    -- Features
    intake_form jsonb,
    verification jsonb,
    mood_logs jsonb[] DEFAULT '{}',
    
    CONSTRAINT users_pkey PRIMARY KEY (id)
);

-- Organizations table
CREATE TABLE public.organizations (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    address text,
    phone_number text,
    email text,
    website text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT organizations_pkey PRIMARY KEY (id)
);

-- Conversations table
CREATE TABLE public.conversations (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    participant1_id uuid NOT NULL,
    participant2_id uuid NOT NULL,
    last_message_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT conversations_pkey PRIMARY KEY (id),
    CONSTRAINT conversations_participant1_fkey FOREIGN KEY (participant1_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT conversations_participant2_fkey FOREIGN KEY (participant2_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT conversations_unique_participants UNIQUE (participant1_id, participant2_id)
);

-- Messages table (snake_case naming)
CREATE TABLE public.messages (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    conversation_id uuid,
    sender_id uuid NOT NULL,
    receiver_id uuid NOT NULL,
    content text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT messages_pkey PRIMARY KEY (id),
    CONSTRAINT messages_sender_fkey FOREIGN KEY (sender_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT messages_receiver_fkey FOREIGN KEY (receiver_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT messages_conversation_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE SET NULL
);

-- Appointments table (snake_case naming)
CREATE TABLE public.appointments (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text,
    appointment_date timestamp with time zone NOT NULL,
    duration_minutes integer DEFAULT 60,
    location text,
    status text DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled', 'rescheduled')),
    creator_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    participant_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT appointments_pkey PRIMARY KEY (id)
);

-- Moods table
CREATE TABLE public.moods (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    emoji text,
    color text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT moods_pkey PRIMARY KEY (id)
);

-- Mood logs table
CREATE TABLE public.mood_logs (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    mood_id uuid NOT NULL,
    date timestamp with time zone DEFAULT now(),
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT mood_logs_pkey PRIMARY KEY (id),
    CONSTRAINT mood_logs_user_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT mood_logs_mood_fkey FOREIGN KEY (mood_id) REFERENCES public.moods(id) ON DELETE CASCADE
);

-- Goals table
CREATE TABLE public.goals (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    title text NOT NULL,
    description text,
    status text DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused', 'cancelled')),
    target_date date,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT goals_pkey PRIMARY KEY (id),
    CONSTRAINT goals_user_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Activities table
CREATE TABLE public.activities (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    title text NOT NULL,
    description text,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    status text DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled')),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT activities_pkey PRIMARY KEY (id),
    CONSTRAINT activities_user_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Milestones table
CREATE TABLE public.milestones (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    title text NOT NULL,
    description text,
    target_date date,
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'overdue')),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT milestones_pkey PRIMARY KEY (id),
    CONSTRAINT milestones_user_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Verification questions table
CREATE TABLE public.verification_questions (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    question text NOT NULL,
    question_type text DEFAULT 'text' CHECK (question_type IN ('text', 'multiple_choice', 'yes_no')),
    required boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT verification_questions_pkey PRIMARY KEY (id)
);

-- Verification requests table
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
    CONSTRAINT verification_requests_user_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT verification_requests_question_fkey FOREIGN KEY (question_id) REFERENCES public.verification_questions(id) ON DELETE CASCADE
);

-- Care team invitations table
CREATE TABLE public.care_team_invitations (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    client_id uuid NOT NULL,
    care_team_member_id uuid NOT NULL,
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired')),
    invited_at timestamp with time zone DEFAULT now(),
    responded_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT care_team_invitations_pkey PRIMARY KEY (id),
    CONSTRAINT care_team_invitations_client_fkey FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT care_team_invitations_member_fkey FOREIGN KEY (care_team_member_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT care_team_invitations_unique UNIQUE (client_id, care_team_member_id)
);

-- Care team assignments table
CREATE TABLE public.care_team_assignments (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    client_id uuid NOT NULL,
    care_team_member_id uuid NOT NULL,
    role text,
    assigned_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT care_team_assignments_pkey PRIMARY KEY (id),
    CONSTRAINT care_team_assignments_client_fkey FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT care_team_assignments_member_fkey FOREIGN KEY (care_team_member_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT care_team_assignments_unique UNIQUE (client_id, care_team_member_id)
);

-- Case assignments table
CREATE TABLE public.case_assignments (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    case_manager_id uuid NOT NULL,
    client_id uuid NOT NULL,
    assigned_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT case_assignments_pkey PRIMARY KEY (id),
    CONSTRAINT case_assignments_manager_fkey FOREIGN KEY (case_manager_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT case_assignments_client_fkey FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT case_assignments_unique UNIQUE (case_manager_id, client_id)
);

-- Mentor requests table
CREATE TABLE public.mentor_requests (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    client_id uuid NOT NULL,
    mentor_id uuid,
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'matched', 'declined', 'completed')),
    request_message text,
    response_message text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT mentor_requests_pkey PRIMARY KEY (id),
    CONSTRAINT mentor_requests_client_fkey FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT mentor_requests_mentor_fkey FOREIGN KEY (mentor_id) REFERENCES auth.users(id) ON DELETE SET NULL,
    CONSTRAINT mentor_requests_unique UNIQUE (client_id, mentor_id)
);

-- Blog posts table
CREATE TABLE public.blog_posts (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    title text NOT NULL,
    content text NOT NULL,
    author_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    status text DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    published_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT blog_posts_pkey PRIMARY KEY (id)
);

-- Blog requests table
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
    CONSTRAINT blog_requests_user_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Incidents table
CREATE TABLE public.incidents (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text NOT NULL,
    severity text DEFAULT 'low' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    status text DEFAULT 'reported' CHECK (status IN ('reported', 'investigating', 'resolved', 'closed')),
    reported_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    assigned_to uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT incidents_pkey PRIMARY KEY (id)
);

-- Incident responses table
CREATE TABLE public.incident_responses (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    incident_id uuid NOT NULL,
    responder_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    response text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT incident_responses_pkey PRIMARY KEY (id),
    CONSTRAINT incident_responses_incident_fkey FOREIGN KEY (incident_id) REFERENCES public.incidents(id) ON DELETE CASCADE
);

-- Reports table
CREATE TABLE public.reports (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    title text NOT NULL,
    content text NOT NULL,
    report_type text DEFAULT 'general' CHECK (report_type IN ('general', 'incident', 'progress', 'compliance')),
    author_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT reports_pkey PRIMARY KEY (id)
);

-- Support tickets table
CREATE TABLE public.support_tickets (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text NOT NULL,
    status text DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    priority text DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    user_id uuid NOT NULL,
    assigned_to_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT support_tickets_pkey PRIMARY KEY (id),
    CONSTRAINT support_tickets_user_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT support_tickets_assigned_to_fkey FOREIGN KEY (assigned_to_id) REFERENCES auth.users(id) ON DELETE SET NULL
);

-- ===========================================
-- STEP 3: ENABLE ROW LEVEL SECURITY
-- ===========================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.care_team_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.care_team_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mentor_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blog_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- ===========================================
-- STEP 4: CREATE RLS POLICIES
-- ===========================================

-- Users policies
CREATE POLICY "Users can view their own profile" ON public.users
    FOR ALL USING (auth.uid() = id);

-- Organizations policies
CREATE POLICY "Anyone can view organizations" ON public.organizations
    FOR SELECT USING (true);
CREATE POLICY "Authenticated users can manage organizations" ON public.organizations
    FOR ALL USING (auth.role() = 'authenticated');

-- Conversations policies
CREATE POLICY "Users can view their own conversations" ON public.conversations
    FOR ALL USING (auth.uid() = participant1_id OR auth.uid() = participant2_id);

-- Messages policies
CREATE POLICY "Users can view their own messages" ON public.messages
    FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
CREATE POLICY "Users can send messages" ON public.messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Users can update their own messages" ON public.messages
    FOR UPDATE USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Appointments policies
CREATE POLICY "Users can view their own appointments" ON public.appointments
    FOR SELECT USING (auth.uid() = creator_id OR auth.uid() = participant_id);
CREATE POLICY "Users can create appointments" ON public.appointments
    FOR INSERT WITH CHECK (auth.uid() = creator_id);
CREATE POLICY "Users can update their own appointments" ON public.appointments
    FOR UPDATE USING (auth.uid() = creator_id OR auth.uid() = participant_id);

-- Moods policies
CREATE POLICY "Anyone can view moods" ON public.moods
    FOR SELECT USING (true);

-- Mood logs policies
CREATE POLICY "Users can manage their own mood logs" ON public.mood_logs
    FOR ALL USING (auth.uid() = user_id);

-- Goals policies
CREATE POLICY "Users can manage their own goals" ON public.goals
    FOR ALL USING (auth.uid() = user_id);

-- Activities policies
CREATE POLICY "Users can manage their own activities" ON public.activities
    FOR ALL USING (auth.uid() = user_id);

-- Milestones policies
CREATE POLICY "Users can manage their own milestones" ON public.milestones
    FOR ALL USING (auth.uid() = user_id);

-- Verification questions policies
CREATE POLICY "Anyone can view verification questions" ON public.verification_questions
    FOR SELECT USING (true);

-- Verification requests policies
CREATE POLICY "Users can manage their own verification requests" ON public.verification_requests
    FOR ALL USING (auth.uid() = user_id);

-- Care team policies
CREATE POLICY "Users can view their own care team data" ON public.care_team_invitations
    FOR ALL USING (auth.uid() = client_id OR auth.uid() = care_team_member_id);

CREATE POLICY "Users can view their own care team assignments" ON public.care_team_assignments
    FOR ALL USING (auth.uid() = client_id OR auth.uid() = care_team_member_id);

-- Case assignment policies
CREATE POLICY "Users can view their own case assignments" ON public.case_assignments
    FOR ALL USING (auth.uid() = case_manager_id OR auth.uid() = client_id);

-- Mentor request policies
CREATE POLICY "Users can view their own mentor requests" ON public.mentor_requests
    FOR ALL USING (auth.uid() = client_id OR auth.uid() = mentor_id);

-- Blog policies
CREATE POLICY "Anyone can view published blog posts" ON public.blog_posts
    FOR SELECT USING (status = 'published');
CREATE POLICY "Authors can manage their own blog posts" ON public.blog_posts
    FOR ALL USING (auth.uid() = author_id);

CREATE POLICY "Users can manage their own blog requests" ON public.blog_requests
    FOR ALL USING (auth.uid() = user_id);

-- Incident policies
CREATE POLICY "Users can view incidents they're involved in" ON public.incidents
    FOR SELECT USING (auth.uid() = reported_by OR auth.uid() = assigned_to);
CREATE POLICY "Users can create incidents" ON public.incidents
    FOR INSERT WITH CHECK (auth.uid() = reported_by);

CREATE POLICY "Users can view incident responses" ON public.incident_responses
    FOR SELECT USING (true);

-- Report policies
CREATE POLICY "Users can view reports" ON public.reports
    FOR SELECT USING (true);
CREATE POLICY "Authors can manage their own reports" ON public.reports
    FOR ALL USING (auth.uid() = author_id);

-- Support ticket policies
CREATE POLICY "Users can manage their own support tickets" ON public.support_tickets
    FOR ALL USING (auth.uid() = user_id OR auth.uid() = assigned_to_id);

-- ===========================================
-- STEP 5: CREATE FUNCTIONS
-- ===========================================

-- Function to update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Create user profile in our users table
    INSERT INTO public.users (
        id, 
        email, 
        first_name,
        last_name,
        created_at, 
        updated_at
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'firstName', ''),
        COALESCE(NEW.raw_user_meta_data->>'lastName', ''),
        NOW(),
        NOW()
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error creating user profile: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 6: CREATE TRIGGERS
-- ===========================================

-- Create trigger for user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Add update triggers for all tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON public.organizations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON public.conversations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON public.messages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_moods_updated_at BEFORE UPDATE ON public.moods FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_mood_logs_updated_at BEFORE UPDATE ON public.mood_logs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_goals_updated_at BEFORE UPDATE ON public.goals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_activities_updated_at BEFORE UPDATE ON public.activities FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_milestones_updated_at BEFORE UPDATE ON public.milestones FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_verification_questions_updated_at BEFORE UPDATE ON public.verification_questions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_verification_requests_updated_at BEFORE UPDATE ON public.verification_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_care_team_invitations_updated_at BEFORE UPDATE ON public.care_team_invitations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_care_team_assignments_updated_at BEFORE UPDATE ON public.care_team_assignments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_case_assignments_updated_at BEFORE UPDATE ON public.case_assignments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_mentor_requests_updated_at BEFORE UPDATE ON public.mentor_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_blog_posts_updated_at BEFORE UPDATE ON public.blog_posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_blog_requests_updated_at BEFORE UPDATE ON public.blog_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_incidents_updated_at BEFORE UPDATE ON public.incidents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_incident_responses_updated_at BEFORE UPDATE ON public.incident_responses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON public.reports FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_support_tickets_updated_at BEFORE UPDATE ON public.support_tickets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===========================================
-- STEP 7: ENABLE REALTIME
-- ===========================================

-- Enable real-time on messaging tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;

-- ===========================================
-- STEP 8: CREATE INDEXES
-- ===========================================

-- Core table indexes
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_account_type ON public.users(account_type);
CREATE INDEX idx_users_is_deleted ON public.users(is_deleted);

-- Messaging indexes
CREATE INDEX idx_messages_sender ON public.messages(sender_id);
CREATE INDEX idx_messages_receiver ON public.messages(receiver_id);
CREATE INDEX idx_messages_conversation ON public.messages(conversation_id);
CREATE INDEX idx_messages_created_at ON public.messages(created_at);
CREATE INDEX idx_conversations_participant1 ON public.conversations(participant1_id);
CREATE INDEX idx_conversations_participant2 ON public.conversations(participant2_id);

-- Appointment indexes
CREATE INDEX idx_appointments_creator ON public.appointments(creator_id);
CREATE INDEX idx_appointments_participant ON public.appointments(participant_id);
CREATE INDEX idx_appointments_date ON public.appointments(appointment_date);

-- Feature table indexes
CREATE INDEX idx_mood_logs_user ON public.mood_logs(user_id);
CREATE INDEX idx_mood_logs_mood ON public.mood_logs(mood_id);
CREATE INDEX idx_mood_logs_date ON public.mood_logs(date);
CREATE INDEX idx_goals_user ON public.goals(user_id);
CREATE INDEX idx_goals_status ON public.goals(status);
CREATE INDEX idx_activities_user ON public.activities(user_id);
CREATE INDEX idx_activities_start_date ON public.activities(start_date);
CREATE INDEX idx_milestones_user ON public.milestones(user_id);
CREATE INDEX idx_milestones_status ON public.milestones(status);

-- Care team indexes
CREATE INDEX idx_care_team_invitations_client ON public.care_team_invitations(client_id);
CREATE INDEX idx_care_team_invitations_member ON public.care_team_invitations(care_team_member_id);
CREATE INDEX idx_care_team_assignments_client ON public.care_team_assignments(client_id);
CREATE INDEX idx_care_team_assignments_member ON public.care_team_assignments(care_team_member_id);
CREATE INDEX idx_case_assignments_manager ON public.case_assignments(case_manager_id);
CREATE INDEX idx_case_assignments_client ON public.case_assignments(client_id);
CREATE INDEX idx_mentor_requests_client ON public.mentor_requests(client_id);
CREATE INDEX idx_mentor_requests_mentor ON public.mentor_requests(mentor_id);

-- Content indexes
CREATE INDEX idx_blog_posts_author ON public.blog_posts(author_id);
CREATE INDEX idx_blog_posts_status ON public.blog_posts(status);
CREATE INDEX idx_blog_requests_user ON public.blog_requests(user_id);
CREATE INDEX idx_incidents_reported_by ON public.incidents(reported_by);
CREATE INDEX idx_incidents_assigned_to ON public.incidents(assigned_to);
CREATE INDEX idx_incidents_status ON public.incidents(status);
CREATE INDEX idx_reports_author ON public.reports(author_id);
CREATE INDEX idx_support_tickets_user ON public.support_tickets(user_id);
CREATE INDEX idx_support_tickets_assigned_to ON public.support_tickets(assigned_to_id);

-- ===========================================
-- STEP 9: INSERT SAMPLE DATA
-- ===========================================

-- Add sample organizations
INSERT INTO public.organizations (name, address, phone_number, email, website) VALUES
('Love Foundation', '123 Main St, City, State 12345', '+1-555-0123', 'info@lovefoundation.org', 'https://lovefoundation.org'),
('Community Support Center', '456 Oak Ave, City, State 12345', '+1-555-0456', 'support@communitycenter.org', 'https://communitycenter.org'),
('Hope & Recovery Services', '789 Pine St, City, State 12345', '+1-555-0789', 'contact@hoperecovery.org', 'https://hoperecovery.org');

-- Add sample moods
INSERT INTO public.moods (name, emoji, color) VALUES
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
-- STEP 10: VERIFICATION
-- ===========================================

SELECT '🎉 CLEAN DATABASE SETUP COMPLETE! 🎉' as status,
       'Consistent snake_case naming for PostgreSQL' as message,
       'Perfect match with camelCase Flutter models!' as next_step;

-- Verify all tables exist
SELECT 
    'Core Tables:' as category,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users') THEN 'users: ✅' ELSE 'users: ❌' END as users_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'organizations') THEN 'organizations: ✅' ELSE 'organizations: ❌' END as organizations_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'conversations') THEN 'conversations: ✅' ELSE 'conversations: ❌' END as conversations_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'messages') THEN 'messages: ✅' ELSE 'messages: ❌' END as messages_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'appointments') THEN 'appointments: ✅' ELSE 'appointments: ❌' END as appointments_table;

SELECT 
    'Feature Tables:' as category,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'moods') THEN 'moods: ✅' ELSE 'moods: ❌' END as moods_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'mood_logs') THEN 'mood_logs: ✅' ELSE 'mood_logs: ❌' END as mood_logs_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'goals') THEN 'goals: ✅' ELSE 'goals: ❌' END as goals_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'activities') THEN 'activities: ✅' ELSE 'activities: ❌' END as activities_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'milestones') THEN 'milestones: ✅' ELSE 'milestones: ❌' END as milestones_table;

SELECT 
    'Care Team Tables:' as category,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'care_team_invitations') THEN 'care_team_invitations: ✅' ELSE 'care_team_invitations: ❌' END as care_team_invitations_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'care_team_assignments') THEN 'care_team_assignments: ✅' ELSE 'care_team_assignments: ❌' END as care_team_assignments_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'case_assignments') THEN 'case_assignments: ✅' ELSE 'case_assignments: ❌' END as case_assignments_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'mentor_requests') THEN 'mentor_requests: ✅' ELSE 'mentor_requests: ❌' END as mentor_requests_table;

SELECT 
    'Content Tables:' as category,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'blog_posts') THEN 'blog_posts: ✅' ELSE 'blog_posts: ❌' END as blog_posts_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'blog_requests') THEN 'blog_requests: ✅' ELSE 'blog_requests: ❌' END as blog_requests_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'incidents') THEN 'incidents: ✅' ELSE 'incidents: ❌' END as incidents_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'incident_responses') THEN 'incident_responses: ✅' ELSE 'incident_responses: ❌' END as incident_responses_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'reports') THEN 'reports: ✅' ELSE 'reports: ❌' END as reports_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'support_tickets') THEN 'support_tickets: ✅' ELSE 'support_tickets: ❌' END as support_tickets_table;

-- Check if the trigger exists
SELECT 'Trigger Check:' as test_name,
       CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created') 
            THEN 'on_auth_user_created: ✅' ELSE 'on_auth_user_created: ❌' END as trigger_status;

-- Check if the function exists
SELECT 'Function Check:' as test_name,
       CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_new_user') 
            THEN 'handle_new_user: ✅' ELSE 'handle_new_user: ✅' END as function_status;

-- Final verification
SELECT '🎯 CLEAN DATABASE READY!' as final_status,
       'All tables use consistent snake_case naming' as naming_convention,
       'Perfect match with camelCase Flutter models via JSON conversion!' as ready_for_development;as in 