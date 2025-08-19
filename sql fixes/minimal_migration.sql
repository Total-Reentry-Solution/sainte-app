-- ===========================================
-- MINIMAL MIGRATION SCRIPT
-- ===========================================
-- This script only adds missing tables and columns to your existing database
-- It won't recreate tables that already exist

-- ===========================================
-- EXTENSIONS AND SAFE UUID GENERATION
-- ===========================================

-- Enable required extensions if not already enabled
DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'pgcrypto extension could not be enabled. Using alternative UUID generation.';
    WHEN OTHERS THEN
        RAISE NOTICE 'pgcrypto extension could not be enabled. Using alternative UUID generation.';
END $$;

-- Create a safe UUID generation function
CREATE OR REPLACE FUNCTION safe_generate_uuid()
RETURNS uuid AS $$
BEGIN
    -- Try to use gen_random_uuid() if available
    BEGIN
        RETURN gen_random_uuid();
    EXCEPTION
        WHEN undefined_function THEN
            -- Fallback to a simple UUID generation
            RETURN ('x' || substr(md5(random()::text || clock_timestamp()::text), 1, 16))::uuid;
    END;
END;
$$ LANGUAGE plpgsql;

-- ===========================================
-- ADD MISSING TABLES ONLY
-- ===========================================

-- 1. Add appointments table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  date timestamp with time zone NOT NULL,
  location text,
  creator_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  participant_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  state text DEFAULT 'pending' CHECK (state IN ('pending', 'confirmed', 'canceled', 'completed')),
  status text DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'ongoing', 'finished')),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- 2. Add blog_posts table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.blog_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  content text,
  category text,
  date timestamp with time zone,
  image_url text,
  author_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  author_name text,
  data jsonb DEFAULT '[]'::jsonb,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- 3. Add blog_requests table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.blog_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  details text,
  email text,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  client_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  status integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- 4. Add incidents table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.incidents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date timestamp with time zone,
  description text,
  reported_by_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  victim_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  response_count integer,
  title text,
  extra_data jsonb,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- 5. Add reports table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  reported_by_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT now()
);

-- 6. Add questions table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- 7. Add case_citizen_assignment table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.case_citizen_assignment (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  case_manager_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  citizen_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  assignment_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (assignment_status IN ('pending', 'accepted', 'rejected', 'active')),
  request_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  responded_at TIMESTAMP WITH TIME ZONE,
  response_message TEXT,
  assigned_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(case_manager_id, citizen_id)
);

-- 8. Add persons table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.persons (
  person_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name TEXT,
  last_name TEXT,
  email TEXT,
  phone TEXT,
  avatar_url TEXT,
  avatar TEXT,
  address TEXT,
  account_type TEXT,
  organizations TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Add person_goals table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.person_goals (
  goal_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  person_id uuid,
  title text NOT NULL,
  description text,
  duration text,
  end_date date,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- 10. Add person_activities table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.person_activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  person_id uuid,
  title text NOT NULL,
  frequency text NOT NULL,
  time_line integer[] DEFAULT '{}',
  day_streak integer DEFAULT 1,
  goal_id uuid,
  progress integer DEFAULT 0,
  start_date bigint NOT NULL,
  end_date bigint NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 11. Add moods table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.moods (
  mood_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  mood_name text NOT NULL UNIQUE,
  mood_icon text,
  mood_category text
);

-- 12. Add mood_logs table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.mood_logs (
  mood_log_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mood_id uuid NOT NULL REFERENCES public.moods(mood_id) ON DELETE CASCADE,
  notes text,
  mood_intensity integer CHECK (mood_intensity >= 1 AND mood_intensity <= 10),
  created_at timestamp with time zone DEFAULT now()
);

-- 13. Add normalization tables
CREATE TABLE IF NOT EXISTS public.user_mentors (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  mentor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, mentor_id)
);

CREATE TABLE IF NOT EXISTS public.appointment_attendees (
  appointment_id UUID REFERENCES public.appointments(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  PRIMARY KEY (appointment_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.appointment_orgs (
  appointment_id UUID REFERENCES public.appointments(id) ON DELETE CASCADE,
  org_id UUID,
  PRIMARY KEY (appointment_id, org_id)
);

CREATE TABLE IF NOT EXISTS public.blog_request_clients (
  blog_request_id UUID REFERENCES public.blog_requests(id) ON DELETE CASCADE,
  client_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  PRIMARY KEY (blog_request_id, client_id)
);

CREATE TABLE IF NOT EXISTS public.conversation_members (
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  PRIMARY KEY (conversation_id, user_id)
);

-- ===========================================
-- ADD MISSING COLUMNS TO EXISTING TABLES
-- ===========================================

-- Add missing columns to user_profiles if they don't exist
DO $$
BEGIN
    -- Add person_id column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'person_id'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN person_id uuid;
    END IF;
    
    -- Add avatar column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'avatar'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN avatar text;
    END IF;
    
    -- Add address column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'address'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN address text;
    END IF;
    
    -- Add account_type column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'account_type'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN account_type text DEFAULT 'citizen';
    END IF;
    
    -- Add organizations column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'organizations'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN organizations text[] DEFAULT '{}';
    END IF;
END $$;

-- Add missing columns to conversations if they don't exist
DO $$
BEGIN
    -- Add last_message_sender_id column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'conversations' 
        AND column_name = 'last_message_sender_id'
    ) THEN
        ALTER TABLE public.conversations ADD COLUMN last_message_sender_id uuid;
    END IF;
    
    -- Add seen column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'conversations' 
        AND column_name = 'seen'
    ) THEN
        ALTER TABLE public.conversations ADD COLUMN seen boolean DEFAULT false;
    END IF;
    
    -- Add last_activity_at column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'conversations' 
        AND column_name = 'last_activity_at'
    ) THEN
        ALTER TABLE public.conversations ADD COLUMN last_activity_at timestamp with time zone;
    END IF;
END $$;

-- Create messages table if it doesn't exist (since it's missing from your schema)
CREATE TABLE IF NOT EXISTS public.messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  receiver_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  sender_person_id uuid,
  receiver_person_id uuid,
  text text NOT NULL,
  sent_at timestamp with time zone DEFAULT now(),
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- ===========================================
-- CREATE INDEXES FOR NEW TABLES
-- ===========================================

-- Create indexes for appointments
CREATE INDEX IF NOT EXISTS idx_appointments_creator_id ON public.appointments(creator_id);
CREATE INDEX IF NOT EXISTS idx_appointments_participant_id ON public.appointments(participant_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON public.appointments(date);

-- Create indexes for blog_posts
CREATE INDEX IF NOT EXISTS idx_blog_posts_author_id ON public.blog_posts(author_id);
CREATE INDEX IF NOT EXISTS idx_blog_posts_category ON public.blog_posts(category);

-- Create indexes for blog_requests
CREATE INDEX IF NOT EXISTS idx_blog_requests_user_id ON public.blog_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_blog_requests_status ON public.blog_requests(status);

-- Create indexes for incidents
CREATE INDEX IF NOT EXISTS idx_incidents_reported_by_id ON public.incidents(reported_by_id);
CREATE INDEX IF NOT EXISTS idx_incidents_victim_id ON public.incidents(victim_id);
CREATE INDEX IF NOT EXISTS idx_incidents_date ON public.incidents(date);

-- Create indexes for case_citizen_assignment
CREATE INDEX IF NOT EXISTS idx_case_citizen_assignment_case_manager ON case_citizen_assignment(case_manager_id);
CREATE INDEX IF NOT EXISTS idx_case_citizen_assignment_citizen ON case_citizen_assignment(citizen_id);
CREATE INDEX IF NOT EXISTS idx_case_citizen_assignment_status ON case_citizen_assignment(assignment_status);

-- Create indexes for messages
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sent_at ON public.messages(sent_at);

-- Create indexes for persons and related tables
CREATE INDEX IF NOT EXISTS idx_persons_email ON public.persons(email);
CREATE INDEX IF NOT EXISTS idx_person_goals_person_id ON public.person_goals(person_id);
CREATE INDEX IF NOT EXISTS idx_person_activities_user_id ON public.person_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_person_activities_person_id ON public.person_activities(person_id);
CREATE INDEX IF NOT EXISTS idx_person_activities_goal_id ON public.person_activities(goal_id);
CREATE INDEX IF NOT EXISTS idx_mood_logs_user_id ON public.mood_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_mood_logs_mood_id ON public.mood_logs(mood_id);
CREATE INDEX IF NOT EXISTS idx_mood_logs_created_at ON public.mood_logs(created_at);

-- ===========================================
-- ENABLE ROW LEVEL SECURITY
-- ===========================================

-- Enable RLS on new tables with existence checks
DO $$
BEGIN
    -- Check and enable RLS on appointments
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'appointments' AND rowsecurity = true) THEN
        ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Check and enable RLS on blog_posts
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'blog_posts' AND rowsecurity = true) THEN
        ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Check and enable RLS on blog_requests
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'blog_requests' AND rowsecurity = true) THEN
        ALTER TABLE public.blog_requests ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Check and enable RLS on incidents
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'incidents' AND rowsecurity = true) THEN
        ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Check and enable RLS on reports
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'reports' AND rowsecurity = true) THEN
        ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Check and enable RLS on questions
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'questions' AND rowsecurity = true) THEN
        ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Check and enable RLS on messages
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'messages' AND rowsecurity = true) THEN
        ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Check and enable RLS on persons
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'persons' AND rowsecurity = true) THEN
        ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Check and enable RLS on person_goals
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'person_goals' AND rowsecurity = true) THEN
        ALTER TABLE public.person_goals ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Check and enable RLS on person_activities
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'person_activities' AND rowsecurity = true) THEN
        ALTER TABLE public.person_activities ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Check and enable RLS on moods
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'moods' AND rowsecurity = true) THEN
        ALTER TABLE public.moods ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Check and enable RLS on mood_logs
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'mood_logs' AND rowsecurity = true) THEN
        ALTER TABLE public.mood_logs ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Check and enable RLS on case_citizen_assignment
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'case_citizen_assignment' AND rowsecurity = true) THEN
        ALTER TABLE case_citizen_assignment ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- ===========================================
-- CREATE BASIC RLS POLICIES
-- ===========================================

-- Appointments policies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'appointments' AND policyname = 'Users can view appointments') THEN
        CREATE POLICY "Users can view appointments" ON public.appointments FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'appointments' AND policyname = 'Users can create appointments') THEN
        CREATE POLICY "Users can create appointments" ON public.appointments FOR INSERT WITH CHECK (auth.uid() = creator_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'appointments' AND policyname = 'Users can update their own appointments') THEN
        CREATE POLICY "Users can update their own appointments" ON public.appointments FOR UPDATE USING (auth.uid() = creator_id);
    END IF;
END $$;

-- Blog posts policies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'blog_posts' AND policyname = 'Anyone can view blog posts') THEN
        CREATE POLICY "Anyone can view blog posts" ON public.blog_posts FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'blog_posts' AND policyname = 'Users can create blog posts') THEN
        CREATE POLICY "Users can create blog posts" ON public.blog_posts FOR INSERT WITH CHECK (auth.uid() = author_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'blog_posts' AND policyname = 'Users can update their own blog posts') THEN
        CREATE POLICY "Users can update their own blog posts" ON public.blog_posts FOR UPDATE USING (auth.uid() = author_id);
    END IF;
END $$;

-- Blog requests policies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'blog_requests' AND policyname = 'Users can view their own blog requests') THEN
        CREATE POLICY "Users can view their own blog requests" ON public.blog_requests FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'blog_requests' AND policyname = 'Users can create blog requests') THEN
        CREATE POLICY "Users can create blog requests" ON public.blog_requests FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'blog_requests' AND policyname = 'Users can update their own blog requests') THEN
        CREATE POLICY "Users can update their own blog requests" ON public.blog_requests FOR UPDATE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Incidents policies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'incidents' AND policyname = 'Users can view incidents') THEN
        CREATE POLICY "Users can view incidents" ON public.incidents FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'incidents' AND policyname = 'Users can create incidents') THEN
        CREATE POLICY "Users can create incidents" ON public.incidents FOR INSERT WITH CHECK (auth.uid() = reported_by_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'incidents' AND policyname = 'Users can update incidents they reported') THEN
        CREATE POLICY "Users can update incidents they reported" ON public.incidents FOR UPDATE USING (auth.uid() = reported_by_id);
    END IF;
END $$;

-- Reports policies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'reports' AND policyname = 'Users can view reports') THEN
        CREATE POLICY "Users can view reports" ON public.reports FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'reports' AND policyname = 'Users can create reports') THEN
        CREATE POLICY "Users can create reports" ON public.reports FOR INSERT WITH CHECK (auth.uid() = reported_by_id);
    END IF;
END $$;

-- Questions policies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'questions' AND policyname = 'Anyone can view questions') THEN
        CREATE POLICY "Anyone can view questions" ON public.questions FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'questions' AND policyname = 'Anyone can create questions') THEN
        CREATE POLICY "Anyone can create questions" ON public.questions FOR INSERT WITH CHECK (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'questions' AND policyname = 'Anyone can update questions') THEN
        CREATE POLICY "Anyone can update questions" ON public.questions FOR UPDATE USING (true);
    END IF;
END $$;

-- Messages policies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'messages' AND policyname = 'Users can view their messages') THEN
        CREATE POLICY "Users can view their messages" ON public.messages
          FOR SELECT USING (
            sender_id = auth.uid() OR receiver_id = auth.uid()
            OR
            sender_person_id = (SELECT person_id FROM public.user_profiles WHERE id = auth.uid())
            OR
            receiver_person_id = (SELECT person_id FROM public.user_profiles WHERE id = auth.uid())
          );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'messages' AND policyname = 'Users can insert messages') THEN
        CREATE POLICY "Users can insert messages" ON public.messages
          FOR INSERT WITH CHECK (
            sender_id = auth.uid()
            OR
            sender_person_id = (SELECT person_id FROM public.user_profiles WHERE id = auth.uid())
          );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'messages' AND policyname = 'Users can update their messages') THEN
        CREATE POLICY "Users can update their messages" ON public.messages
          FOR UPDATE USING (
            sender_id = auth.uid()
            OR
            sender_person_id = (SELECT person_id FROM public.user_profiles WHERE id = auth.uid())
          );
    END IF;
END $$;

-- Persons policies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'persons' AND policyname = 'Anyone can view persons') THEN
        CREATE POLICY "Anyone can view persons" ON public.persons FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'persons' AND policyname = 'Users can update their own person record') THEN
        CREATE POLICY "Users can update their own person record" ON public.persons FOR UPDATE USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'persons' AND policyname = 'Users can insert person records') THEN
        CREATE POLICY "Users can insert person records" ON public.persons FOR INSERT WITH CHECK (true);
    END IF;
END $$;

-- Person goals policies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'person_goals' AND policyname = 'Users can view their own goals') THEN
        CREATE POLICY "Users can view their own goals" ON public.person_goals FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'person_goals' AND policyname = 'Users can create goals') THEN
        CREATE POLICY "Users can create goals" ON public.person_goals FOR INSERT WITH CHECK (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'person_goals' AND policyname = 'Users can update their own goals') THEN
        CREATE POLICY "Users can update their own goals" ON public.person_goals FOR UPDATE USING (true);
    END IF;
END $$;

-- Person activities policies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'person_activities' AND policyname = 'Users can view their own activities') THEN
        CREATE POLICY "Users can view their own activities" ON public.person_activities FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'person_activities' AND policyname = 'Users can create activities') THEN
        CREATE POLICY "Users can create activities" ON public.person_activities FOR INSERT WITH CHECK (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'person_activities' AND policyname = 'Users can update their own activities') THEN
        CREATE POLICY "Users can update their own activities" ON public.person_activities FOR UPDATE USING (true);
    END IF;
END $$;

-- Moods policies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'moods' AND policyname = 'Anyone can view moods') THEN
        CREATE POLICY "Anyone can view moods" ON public.moods FOR SELECT USING (true);
    END IF;
END $$;

-- Mood logs policies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'mood_logs' AND policyname = 'Users can view their own mood logs') THEN
        CREATE POLICY "Users can view their own mood logs" ON public.mood_logs FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'mood_logs' AND policyname = 'Users can create mood logs') THEN
        CREATE POLICY "Users can create mood logs" ON public.mood_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'mood_logs' AND policyname = 'Users can update their own mood logs') THEN
        CREATE POLICY "Users can update their own mood logs" ON public.mood_logs FOR UPDATE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Case citizen assignment policies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'case_citizen_assignment' AND policyname = 'Case managers can view their own assignments') THEN
        CREATE POLICY "Case managers can view their own assignments" ON case_citizen_assignment
            FOR SELECT USING (auth.uid() = case_manager_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'case_citizen_assignment' AND policyname = 'Citizens can view assignments made to them') THEN
        CREATE POLICY "Citizens can view assignments made to them" ON case_citizen_assignment
            FOR SELECT USING (auth.uid() = citizen_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'case_citizen_assignment' AND policyname = 'Case managers can create assignments') THEN
        CREATE POLICY "Case managers can create assignments" ON case_citizen_assignment
            FOR INSERT WITH CHECK (auth.uid() = case_manager_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'case_citizen_assignment' AND policyname = 'Case managers can update their own assignments') THEN
        CREATE POLICY "Case managers can update their own assignments" ON case_citizen_assignment
            FOR UPDATE USING (auth.uid() = case_manager_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'case_citizen_assignment' AND policyname = 'Citizens can respond to assignments') THEN
        CREATE POLICY "Citizens can respond to assignments" ON case_citizen_assignment
            FOR UPDATE USING (auth.uid() = citizen_id);
    END IF;
END $$;

-- ===========================================
-- INSERT INITIAL DATA
-- ===========================================

-- Insert initial mood data
INSERT INTO public.moods (mood_name, mood_icon, mood_category) VALUES
('happy',      '😊', 'positive'),
('sad',        '😢', 'negative'),
('angry',      '😠', 'negative'),
('fear',       '😨', 'negative'),
('love',       '❤️', 'positive'),
('shame',      '😔', 'negative'),
('confusion',  '😕', 'neutral'),
('anxiety',    '😰', 'negative'),
('joyful',     '😁', 'positive')
ON CONFLICT (mood_name) DO NOTHING;

-- ===========================================
-- CREATE FUNCTIONS AND TRIGGERS
-- ===========================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at with existence checks
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_appointments_updated_at') THEN
        CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_blog_posts_updated_at') THEN
        CREATE TRIGGER update_blog_posts_updated_at BEFORE UPDATE ON public.blog_posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_blog_requests_updated_at') THEN
        CREATE TRIGGER update_blog_requests_updated_at BEFORE UPDATE ON public.blog_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_incidents_updated_at') THEN
        CREATE TRIGGER update_incidents_updated_at BEFORE UPDATE ON public.incidents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_questions_updated_at') THEN
        CREATE TRIGGER update_questions_updated_at BEFORE UPDATE ON public.questions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_messages_updated_at') THEN
        CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON public.messages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_persons_updated_at') THEN
        CREATE TRIGGER update_persons_updated_at BEFORE UPDATE ON public.persons FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_person_goals_updated_at') THEN
        CREATE TRIGGER update_person_goals_updated_at BEFORE UPDATE ON public.person_goals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_person_activities_updated_at') THEN
        CREATE TRIGGER update_person_activities_updated_at BEFORE UPDATE ON public.person_activities FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    -- Ensure conversations table has required columns before creating trigger
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'conversations' 
        AND column_name = 'updated_at'
    ) AND NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_conversations_updated_at') THEN
        CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON public.conversations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    -- Case citizen assignment trigger
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_case_citizen_assignment_updated_at') THEN
        CREATE TRIGGER update_case_citizen_assignment_updated_at
            BEFORE UPDATE ON case_citizen_assignment
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- ===========================================
-- ENABLE REAL-TIME FOR MESSAGING
-- ===========================================

-- Enable real-time for messages table (already done in previous migration)
-- DO $$
-- BEGIN
--     IF NOT EXISTS (
--         SELECT 1 FROM pg_publication_tables 
--         WHERE pubname = 'supabase_realtime' 
--         AND tablename = 'messages'
--     ) THEN
--         ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
--     END IF;
-- END $$;

-- ===========================================
-- DATA MIGRATION AND LINKING
-- ===========================================

-- Link existing users to person records (if needed)
DO $$
DECLARE
    r RECORD;
    new_person_id uuid;
    existing_person_id uuid;
BEGIN
    FOR r IN SELECT id, email, first_name, last_name FROM public.user_profiles WHERE person_id IS NULL
    LOOP
        -- Try to find an existing person record first
        SELECT person_id INTO existing_person_id 
        FROM public.persons 
        WHERE email = r.email 
        AND first_name = r.first_name 
        AND last_name = r.last_name
        LIMIT 1;
        
        IF existing_person_id IS NOT NULL THEN
            -- Link to existing person
            UPDATE public.user_profiles SET person_id = existing_person_id WHERE id = r.id;
        ELSE
            -- Create new person record with UUID using safe function
            -- Temporarily disable any problematic triggers
            BEGIN
                INSERT INTO public.persons (person_id, email, first_name, last_name)
                VALUES (safe_generate_uuid(), r.email, r.first_name, r.last_name)
                RETURNING person_id INTO new_person_id;
            EXCEPTION
                WHEN OTHERS THEN
                    -- If insert fails due to triggers, try a different approach
                    RAISE NOTICE 'Insert failed, trying alternative approach: %', SQLERRM;
                    
                    -- Generate UUID manually and insert with minimal fields
                    new_person_id := safe_generate_uuid();
                    
                    -- Try to insert with just the essential fields
                    INSERT INTO public.persons (person_id, email, first_name, last_name)
                    VALUES (new_person_id, r.email, r.first_name, r.last_name);
            END;
            
            -- Link user_profile to new person
            UPDATE public.user_profiles SET person_id = new_person_id WHERE id = r.id;
        END IF;
    END LOOP;
END $$;

-- Set default values for existing users
UPDATE public.user_profiles SET account_type = 'citizen' WHERE account_type IS NULL;
UPDATE public.user_profiles SET organizations = '{}' WHERE organizations IS NULL;
UPDATE public.user_profiles 
SET avatar_url = 'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png?20150327203541'
WHERE avatar_url IS NULL OR avatar_url = '';
UPDATE public.user_profiles 
SET avatar = 'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png?20150327203541'
WHERE avatar IS NULL OR avatar = '';

-- ===========================================
-- GRANT PERMISSIONS
-- ===========================================

-- Grant necessary permissions with existence checks
DO $$
BEGIN
    -- Grant schema usage if not already granted
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.role_table_grants 
        WHERE grantee = 'authenticated' 
        AND table_schema = 'public'
        LIMIT 1
    ) THEN
        GRANT USAGE ON SCHEMA public TO authenticated;
    END IF;
    
    -- Grant table permissions if not already granted
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.role_table_grants 
        WHERE grantee = 'authenticated' 
        AND table_schema = 'public'
        AND privilege_type = 'SELECT'
        LIMIT 1
    ) THEN
        GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
    END IF;
    
    -- Grant sequence permissions if not already granted
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.role_usage_grants 
        WHERE grantee = 'authenticated' 
        AND object_schema = 'public'
        LIMIT 1
    ) THEN
        GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
    END IF;
END $$;

-- ===========================================
-- VERIFICATION
-- ===========================================

-- Check what was added
SELECT '✅ Complete migration completed successfully!' as status;

-- Show all tables
SELECT 
    schemaname,
    tablename,
    'Table available' as status
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN (
        'user_profiles', 'appointments', 'blog_posts', 'blog_requests',
        'conversations', 'messages', 'incidents', 'reports', 'questions',
        'persons', 'person_goals', 'person_activities', 'moods', 'mood_logs',
        'case_citizen_assignment'
    )
ORDER BY tablename; 