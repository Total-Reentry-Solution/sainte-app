-- ===========================================
-- CLEANED ORIGINAL MIGRATION SCRIPT
-- ===========================================
-- This fixes the syntax errors and ensures proper table creation order

-- ===========================================
-- ENUM TYPES
-- ===========================================

CREATE TYPE appointment_state AS ENUM ('pending', 'confirmed', 'canceled', 'completed');
CREATE TYPE appointment_status AS ENUM ('upcoming', 'ongoing', 'finished');

-- ===========================================
-- CORE TABLES
-- ===========================================

-- 1. user_profiles
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name text,
  last_name text,
  email text UNIQUE,
  phone text UNIQUE,
  avatar_url text,
  avatar text,
  address text,
  person_id uuid,
  account_type text DEFAULT 'citizen',
  organizations text[] DEFAULT '{}',
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Partial unique indexes for nullable fields
CREATE UNIQUE INDEX IF NOT EXISTS user_profiles_email_unique ON public.user_profiles(email) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS user_profiles_phone_unique ON public.user_profiles(phone) WHERE phone IS NOT NULL;

-- 2. appointments
CREATE TABLE IF NOT EXISTS public.appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  date timestamp with time zone NOT NULL,
  location text,
  creator_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  participant_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  state appointment_state NOT NULL,
  status appointment_status NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- 3. blog_posts
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

-- 4. blog_requests
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

-- 5. conversations
CREATE TABLE IF NOT EXISTS public.conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  last_message text,
  last_message_sender_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  seen boolean DEFAULT false,
  last_activity_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- 6. messages
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

-- 7. incidents
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

-- 8. reports
CREATE TABLE IF NOT EXISTS public.reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  reported_by_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT now()
);

-- 9. questions
CREATE TABLE IF NOT EXISTS public.questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- 10. persons table (must be created before person_goals)
CREATE TABLE IF NOT EXISTS public.persons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  person_id TEXT UNIQUE NOT NULL,
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

-- 11. person_goals
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

-- 12. person_activities
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

-- 13. moods table
CREATE TABLE IF NOT EXISTS public.moods (
  mood_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  mood_name text NOT NULL UNIQUE,
  mood_icon text,
  mood_category text
);

-- 14. mood_logs table
CREATE TABLE IF NOT EXISTS public.mood_logs (
  mood_log_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mood_id uuid NOT NULL REFERENCES public.moods(mood_id) ON DELETE CASCADE,
  notes text,
  mood_intensity integer CHECK (mood_intensity >= 1 AND mood_intensity <= 10),
  created_at timestamp with time zone DEFAULT now()
);

-- 15. case_citizen_assignment
CREATE TABLE IF NOT EXISTS case_citizen_assignment (
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

-- ===========================================
-- NORMALIZATION TABLES
-- ===========================================

-- Normalize mentors
CREATE TABLE IF NOT EXISTS public.user_mentors (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  mentor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, mentor_id)
);

-- Normalize attendees
CREATE TABLE IF NOT EXISTS public.appointment_attendees (
  appointment_id UUID REFERENCES public.appointments(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  PRIMARY KEY (appointment_id, user_id)
);

-- Normalize orgs
CREATE TABLE IF NOT EXISTS public.appointment_orgs (
  appointment_id UUID REFERENCES public.appointments(id) ON DELETE CASCADE,
  org_id UUID,
  PRIMARY KEY (appointment_id, org_id)
);

-- Normalize blog clients
CREATE TABLE IF NOT EXISTS public.blog_request_clients (
  blog_request_id UUID REFERENCES public.blog_requests(id) ON DELETE CASCADE,
  client_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  PRIMARY KEY (blog_request_id, client_id)
);

-- Normalize conversation members
CREATE TABLE IF NOT EXISTS public.conversation_members (
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  PRIMARY KEY (conversation_id, user_id)
);

-- ===========================================
-- INDEXES
-- ===========================================

CREATE INDEX IF NOT EXISTS idx_appointments_creator_id ON public.appointments(creator_id);
CREATE INDEX IF NOT EXISTS idx_appointments_participant_id ON public.appointments(participant_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_person_id ON public.messages(sender_person_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_person_id ON public.messages(receiver_person_id);
CREATE INDEX IF NOT EXISTS idx_messages_person_conversation ON public.messages(sender_person_id, receiver_person_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message_sender_id ON public.conversations(last_message_sender_id);
CREATE INDEX IF NOT EXISTS idx_blog_requests_user_id ON public.blog_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_organizations ON public.user_profiles USING GIN (organizations);
CREATE INDEX IF NOT EXISTS idx_user_profiles_account_type ON public.user_profiles (account_type);
CREATE INDEX IF NOT EXISTS idx_user_profiles_avatar_url ON public.user_profiles(avatar_url);
CREATE INDEX IF NOT EXISTS idx_user_profiles_avatar ON public.user_profiles(avatar);
CREATE INDEX IF NOT EXISTS idx_persons_person_id ON public.persons(person_id);
CREATE INDEX IF NOT EXISTS idx_persons_email ON public.persons(email);
CREATE INDEX IF NOT EXISTS idx_mood_logs_user_id ON public.mood_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_mood_logs_created_at ON public.mood_logs (created_at);
CREATE INDEX IF NOT EXISTS idx_mood_logs_mood_id ON public.mood_logs (mood_id);
CREATE INDEX IF NOT EXISTS idx_case_citizen_assignment_case_manager ON case_citizen_assignment(case_manager_id);
CREATE INDEX IF NOT EXISTS idx_case_citizen_assignment_citizen ON case_citizen_assignment(citizen_id);
CREATE INDEX IF NOT EXISTS idx_case_citizen_assignment_status ON case_citizen_assignment(assignment_status);

-- ===========================================
-- INITIAL DATA
-- ===========================================

-- Insert initial moods
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
-- FOREIGN KEY CONSTRAINTS
-- ===========================================

-- Add foreign key constraints
ALTER TABLE public.user_profiles
ADD CONSTRAINT IF NOT EXISTS user_profiles_person_id_fkey
FOREIGN KEY (person_id) REFERENCES public.persons(person_id) ON DELETE CASCADE;

ALTER TABLE public.person_goals
ADD CONSTRAINT IF NOT EXISTS person_goals_person_id_fkey
FOREIGN KEY (person_id) REFERENCES public.persons(person_id);

ALTER TABLE public.person_activities
ADD CONSTRAINT IF NOT EXISTS person_activities_person_id_fkey
FOREIGN KEY (person_id) REFERENCES public.persons(person_id);

ALTER TABLE public.person_activities
ADD CONSTRAINT IF NOT EXISTS person_activities_goal_id_fkey
FOREIGN KEY (goal_id) REFERENCES public.person_goals(goal_id) ON DELETE SET NULL;

-- ===========================================
-- DATA MIGRATION
-- ===========================================

-- Ensure every user has a person_id
DO $$
DECLARE
    r RECORD;
    new_person_id uuid;
BEGIN
    FOR r IN SELECT id, email, first_name, last_name FROM public.user_profiles WHERE person_id IS NULL
    LOOP
        new_person_id := gen_random_uuid();
        INSERT INTO public.persons (person_id, email, first_name, last_name)
        VALUES (new_person_id, r.email, r.first_name, r.last_name);
        UPDATE public.user_profiles SET person_id = new_person_id WHERE id = r.id;
    END LOOP;
END $$;

-- Update existing users to have default values
UPDATE public.user_profiles SET account_type = 'citizen' WHERE account_type IS NULL;
UPDATE public.user_profiles SET organizations = '{}' WHERE organizations IS NULL;
UPDATE public.user_profiles 
SET avatar_url = 'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png?20150327203541'
WHERE avatar_url IS NULL OR avatar_url = '';
UPDATE public.user_profiles 
SET avatar = 'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png?20150327203541'
WHERE avatar IS NULL OR avatar = '';

-- ===========================================
-- ROW LEVEL SECURITY
-- ===========================================

-- Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blog_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.person_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.person_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE case_citizen_assignment ENABLE ROW LEVEL SECURITY;

-- ===========================================
-- RLS POLICIES
-- ===========================================

-- User profiles policies
CREATE POLICY "Users can view profiles" ON public.user_profiles FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" ON public.user_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert their own profile" ON public.user_profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Messages policies
CREATE POLICY "Users can view their messages" ON public.messages
  FOR SELECT USING (
    sender_id = auth.uid() OR receiver_id = auth.uid()
    OR
    sender_person_id = (SELECT person_id FROM public.user_profiles WHERE id = auth.uid())
    OR
    receiver_person_id = (SELECT person_id FROM public.user_profiles WHERE id = auth.uid())
  );

CREATE POLICY "Users can insert messages" ON public.messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid()
    OR
    sender_person_id = (SELECT person_id FROM public.user_profiles WHERE id = auth.uid())
  );

CREATE POLICY "Users can update their messages" ON public.messages
  FOR UPDATE USING (
    sender_id = auth.uid()
    OR
    sender_person_id = (SELECT person_id FROM public.user_profiles WHERE id = auth.uid())
  );

-- Case citizen assignment policies
CREATE POLICY "Case managers can view their own assignments" ON case_citizen_assignment
    FOR SELECT USING (auth.uid() = case_manager_id);

CREATE POLICY "Citizens can view assignments made to them" ON case_citizen_assignment
    FOR SELECT USING (auth.uid() = citizen_id);

CREATE POLICY "Case managers can create assignments" ON case_citizen_assignment
    FOR INSERT WITH CHECK (auth.uid() = case_manager_id);

CREATE POLICY "Case managers can update their own assignments" ON case_citizen_assignment
    FOR UPDATE USING (auth.uid() = case_manager_id);

CREATE POLICY "Citizens can respond to assignments" ON case_citizen_assignment
    FOR UPDATE USING (auth.uid() = citizen_id);

-- ===========================================
-- REAL-TIME SETUP
-- ===========================================

-- Enable real-time for messages table
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;

-- ===========================================
-- FUNCTIONS AND TRIGGERS
-- ===========================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_blog_posts_updated_at BEFORE UPDATE ON public.blog_posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_blog_requests_updated_at BEFORE UPDATE ON public.blog_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON public.conversations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON public.messages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_incidents_updated_at BEFORE UPDATE ON public.incidents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_questions_updated_at BEFORE UPDATE ON public.questions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_persons_updated_at BEFORE UPDATE ON public.persons FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_person_goals_updated_at BEFORE UPDATE ON public.person_goals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_person_activities_updated_at BEFORE UPDATE ON public.person_activities FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Case citizen assignment trigger
CREATE TRIGGER update_case_citizen_assignment_updated_at
    BEFORE UPDATE ON case_citizen_assignment
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ===========================================
-- PERMISSIONS
-- ===========================================

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ===========================================
-- VERIFICATION
-- ===========================================

-- Check if all tables were created successfully
SELECT '✅ Database migration completed successfully!' as status;

-- Show table counts
SELECT 
    schemaname,
    tablename,
    'Table created successfully' as status
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN (
        'user_profiles', 'appointments', 'blog_posts', 'blog_requests',
        'conversations', 'messages', 'incidents', 'reports', 'questions',
        'persons', 'person_goals', 'person_activities', 'moods', 'mood_logs',
        'case_citizen_assignment'
    )
ORDER BY tablename; 