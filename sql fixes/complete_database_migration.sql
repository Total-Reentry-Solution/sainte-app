-- ===========================================
-- COMPLETE DATABASE MIGRATION SCRIPT
-- ===========================================
-- This script consolidates all database setup and fixes
-- Run this in your Supabase SQL Editor to set up the complete database

-- ===========================================
-- EXTENSIONS
-- ===========================================

-- Enable required extensions
DO $$
BEGIN
    -- Try to enable pgcrypto extension
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'pgcrypto extension could not be enabled. Using alternative UUID generation.';
    WHEN OTHERS THEN
        RAISE NOTICE 'pgcrypto extension could not be enabled. Using alternative UUID generation.';
END $$;

-- Create a fallback UUID generation function
CREATE OR REPLACE FUNCTION generate_uuid()
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

-- Ensure person_id column exists (in case table already exists without it)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'person_id'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN person_id uuid;
    END IF;
END $$;

-- Partial unique indexes for nullable fields
CREATE UNIQUE INDEX IF NOT EXISTS user_profiles_email_unique ON public.user_profiles(email) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS user_profiles_phone_unique ON public.user_profiles(phone) WHERE phone IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS user_profiles_person_id_unique ON public.user_profiles(person_id);

-- 2. appointments
CREATE TABLE IF NOT EXISTS public.appointments (
  id uuid PRIMARY KEY DEFAULT generate_uuid(),
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
  id uuid PRIMARY KEY DEFAULT generate_uuid(),
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
  id uuid PRIMARY KEY DEFAULT generate_uuid(),
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
  id uuid PRIMARY KEY DEFAULT generate_uuid(),
  last_message text,
  last_message_sender_id uuid,
  seen boolean DEFAULT false,
  last_activity_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Ensure last_message_sender_id column exists (in case table already exists without it)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'conversations' 
        AND column_name = 'last_message_sender_id'
    ) THEN
        ALTER TABLE public.conversations ADD COLUMN last_message_sender_id uuid;
    END IF;
END $$;

-- 6. messages
CREATE TABLE IF NOT EXISTS public.messages (
  id uuid PRIMARY KEY DEFAULT generate_uuid(),
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
  id uuid PRIMARY KEY DEFAULT generate_uuid(),
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
  id uuid PRIMARY KEY DEFAULT generate_uuid(),
  title text NOT NULL,
  description text,
  reported_by_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT now()
);

-- 9. questions
CREATE TABLE IF NOT EXISTS public.questions (
  id uuid PRIMARY KEY DEFAULT generate_uuid(),
  question text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- 10. persons table
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

-- Ensure person_id column exists (in case table already exists without it)
DO $$
BEGIN
    -- Check if person_id column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'persons' 
        AND column_name = 'person_id'
    ) THEN
        ALTER TABLE public.persons ADD COLUMN person_id TEXT UNIQUE NOT NULL;
    END IF;
    
    -- Note: We don't alter the type if it already exists to avoid conflicts with existing policies
END $$;

-- 11. person_goals
CREATE TABLE IF NOT EXISTS public.person_goals (
  goal_id uuid PRIMARY KEY DEFAULT generate_uuid(),
  person_id uuid,
  title text NOT NULL,
  description text,
  duration text,
  end_date date,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Ensure person_id column exists (in case table already exists without it)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'person_goals' 
        AND column_name = 'person_id'
    ) THEN
        ALTER TABLE public.person_goals ADD COLUMN person_id uuid;
    END IF;
END $$;

-- 12. person_activities
CREATE TABLE IF NOT EXISTS public.person_activities (
  id uuid PRIMARY KEY DEFAULT generate_uuid(),
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

-- Ensure person_id column exists (in case table already exists without it)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'person_activities' 
        AND column_name = 'person_id'
    ) THEN
        ALTER TABLE public.person_activities ADD COLUMN person_id uuid;
    END IF;
END $$;

-- Ensure goal_id column exists (in case table already exists without it)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'person_activities' 
        AND column_name = 'goal_id'
    ) THEN
        ALTER TABLE public.person_activities ADD COLUMN goal_id uuid;
    END IF;
END $$;

-- 13. moods table
CREATE TABLE IF NOT EXISTS public.moods (
  mood_id uuid PRIMARY KEY DEFAULT generate_uuid(),
  mood_name text NOT NULL UNIQUE,
  mood_icon text,
  mood_category text
);

-- 14. mood_logs table
CREATE TABLE IF NOT EXISTS public.mood_logs (
  mood_log_id uuid PRIMARY KEY DEFAULT generate_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mood_id uuid NOT NULL REFERENCES public.moods(mood_id) ON DELETE CASCADE,
  notes text,
  mood_intensity integer CHECK (mood_intensity >= 1 AND mood_intensity <= 10),
  created_at timestamp with time zone DEFAULT now()
);

-- 15. case_citizen_assignment
CREATE TABLE IF NOT EXISTS case_citizen_assignment (
  id UUID DEFAULT generate_uuid() PRIMARY KEY,
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

-- Create indexes with column existence checks
DO $$
BEGIN
    -- Appointments indexes
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'creator_id') THEN
        CREATE INDEX IF NOT EXISTS idx_appointments_creator_id ON public.appointments(creator_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'participant_id') THEN
        CREATE INDEX IF NOT EXISTS idx_appointments_participant_id ON public.appointments(participant_id);
    END IF;
    
    -- Messages indexes
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'sender_id') THEN
        CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'receiver_id') THEN
        CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages(receiver_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'conversation_id') THEN
        CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'sender_person_id') THEN
        CREATE INDEX IF NOT EXISTS idx_messages_sender_person_id ON public.messages(sender_person_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'receiver_person_id') THEN
        CREATE INDEX IF NOT EXISTS idx_messages_receiver_person_id ON public.messages(receiver_person_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'sender_person_id') 
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'receiver_person_id') THEN
        CREATE INDEX IF NOT EXISTS idx_messages_person_conversation ON public.messages(sender_person_id, receiver_person_id);
    END IF;
    
    -- Conversations indexes
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'last_message_sender_id') THEN
        CREATE INDEX IF NOT EXISTS idx_conversations_last_message_sender_id ON public.conversations(last_message_sender_id);
    END IF;
    
    -- Blog requests indexes
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'blog_requests' AND column_name = 'user_id') THEN
        CREATE INDEX IF NOT EXISTS idx_blog_requests_user_id ON public.blog_requests(user_id);
    END IF;
    
    -- User profiles indexes
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'organizations') THEN
        CREATE INDEX IF NOT EXISTS idx_user_profiles_organizations ON public.user_profiles USING GIN (organizations);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'account_type') THEN
        CREATE INDEX IF NOT EXISTS idx_user_profiles_account_type ON public.user_profiles (account_type);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'avatar_url') THEN
        CREATE INDEX IF NOT EXISTS idx_user_profiles_avatar_url ON public.user_profiles(avatar_url);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'avatar') THEN
        CREATE INDEX IF NOT EXISTS idx_user_profiles_avatar ON public.user_profiles(avatar);
    END IF;
    
    -- Persons indexes
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'persons' AND column_name = 'person_id') THEN
        CREATE INDEX IF NOT EXISTS idx_persons_person_id ON public.persons(person_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'persons' AND column_name = 'email') THEN
        CREATE INDEX IF NOT EXISTS idx_persons_email ON public.persons(email);
    END IF;
    
    -- Mood logs indexes
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'mood_logs' AND column_name = 'user_id') THEN
        CREATE INDEX IF NOT EXISTS idx_mood_logs_user_id ON public.mood_logs (user_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'mood_logs' AND column_name = 'created_at') THEN
        CREATE INDEX IF NOT EXISTS idx_mood_logs_created_at ON public.mood_logs (created_at);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'mood_logs' AND column_name = 'mood_id') THEN
        CREATE INDEX IF NOT EXISTS idx_mood_logs_mood_id ON public.mood_logs (mood_id);
    END IF;
    
    -- Case citizen assignment indexes
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'case_citizen_assignment' AND column_name = 'case_manager_id') THEN
        CREATE INDEX IF NOT EXISTS idx_case_citizen_assignment_case_manager ON case_citizen_assignment(case_manager_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'case_citizen_assignment' AND column_name = 'citizen_id') THEN
        CREATE INDEX IF NOT EXISTS idx_case_citizen_assignment_citizen ON case_citizen_assignment(citizen_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'case_citizen_assignment' AND column_name = 'assignment_status') THEN
        CREATE INDEX IF NOT EXISTS idx_case_citizen_assignment_status ON case_citizen_assignment(assignment_status);
    END IF;
END $$;

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
DO $$ 
BEGIN
    -- Verify all required columns exist before creating constraints
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'person_id'
    ) THEN
        RAISE EXCEPTION 'Column person_id does not exist in user_profiles table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'persons' 
        AND column_name = 'person_id'
    ) THEN
        RAISE EXCEPTION 'Column person_id does not exist in persons table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'person_goals' 
        AND column_name = 'person_id'
    ) THEN
        RAISE EXCEPTION 'Column person_id does not exist in person_goals table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'person_activities' 
        AND column_name = 'person_id'
    ) THEN
        RAISE EXCEPTION 'Column person_id does not exist in person_activities table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'person_activities' 
        AND column_name = 'goal_id'
    ) THEN
        RAISE EXCEPTION 'Column goal_id does not exist in person_activities table';
    END IF;
    
    -- Add user_profiles person_id foreign key
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'user_profiles_person_id_fkey' 
        AND table_name = 'user_profiles'
    ) THEN
        -- Check if we can create the constraint based on data types
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'user_profiles' 
            AND column_name = 'person_id'
            AND data_type = 'uuid'
        ) AND EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'persons' 
            AND column_name = 'person_id'
            AND data_type = 'uuid'
        ) THEN
            ALTER TABLE public.user_profiles
            ADD CONSTRAINT user_profiles_person_id_fkey
            FOREIGN KEY (person_id) REFERENCES public.persons(person_id) ON DELETE CASCADE;
        ELSE
            RAISE NOTICE 'Cannot create foreign key constraint: data type mismatch between user_profiles.person_id and persons.person_id';
        END IF;
    END IF;

    -- Add person_goals person_id foreign key
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'person_goals_person_id_fkey' 
        AND table_name = 'person_goals'
    ) THEN
        -- Check if we can create the constraint based on data types
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'person_goals' 
            AND column_name = 'person_id'
            AND data_type = 'uuid'
        ) AND EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'persons' 
            AND column_name = 'person_id'
            AND data_type = 'uuid'
        ) THEN
            ALTER TABLE public.person_goals
            ADD CONSTRAINT person_goals_person_id_fkey
            FOREIGN KEY (person_id) REFERENCES public.persons(person_id);
        ELSE
            RAISE NOTICE 'Cannot create foreign key constraint: data type mismatch between person_goals.person_id and persons.person_id';
        END IF;
    END IF;

    -- Add person_activities person_id foreign key
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'person_activities_person_id_fkey' 
        AND table_name = 'person_activities'
    ) THEN
        -- Check if we can create the constraint based on data types
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'person_activities' 
            AND column_name = 'person_id'
            AND data_type = 'uuid'
        ) AND EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'persons' 
            AND column_name = 'person_id'
            AND data_type = 'uuid'
        ) THEN
            ALTER TABLE public.person_activities
            ADD CONSTRAINT person_activities_person_id_fkey
            FOREIGN KEY (person_id) REFERENCES public.persons(person_id);
        ELSE
            RAISE NOTICE 'Cannot create foreign key constraint: data type mismatch between person_activities.person_id and persons.person_id';
        END IF;
    END IF;

    -- Add person_activities goal_id foreign key
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'person_activities_goal_id_fkey' 
        AND table_name = 'person_activities'
    ) THEN
        ALTER TABLE public.person_activities
        ADD CONSTRAINT person_activities_goal_id_fkey
        FOREIGN KEY (goal_id) REFERENCES public.person_goals(goal_id) ON DELETE SET NULL;
    END IF;
END $$;

-- ===========================================
-- DATA MIGRATION
-- ===========================================

-- Ensure every user has a person_id
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
            -- Create new person record with UUID
            INSERT INTO public.persons (person_id, email, first_name, last_name)
            VALUES (gen_random_uuid(), r.email, r.first_name, r.last_name)
            RETURNING person_id INTO new_person_id;
            
            -- Link user_profile to new person
            UPDATE public.user_profiles SET person_id = new_person_id WHERE id = r.id;
        END IF;
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

-- Ensure conversations table has required columns before creating trigger
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'conversations' 
        AND column_name = 'updated_at'
    ) THEN
        CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON public.conversations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

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