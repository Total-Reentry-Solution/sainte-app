-- Create user_profiles table (this maps to your UserDto)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id uuid NOT NULL,
    first_name text,
    last_name text,
    email text,
    phone text,
    avatar_url text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT user_profiles_pkey PRIMARY KEY (id),
    CONSTRAINT user_profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);

-- Create persons table (for detailed person information)
CREATE TABLE IF NOT EXISTS public.persons (
    person_id uuid NOT NULL DEFAULT gen_random_uuid(),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    first_name text,
    last_name text,
    date_of_birth date,
    primary_language text,
    housing_status text,
    employment_status text,
    justice_status text,
    aces_score integer,
    resilience_score integer,
    deceased_on date,
    legacy_reflection text,
    organization_id bigint,
    employee_id text,
    case_status text DEFAULT 'intake'::text,
    intake_date date,
    case_manager_id uuid,
    risk_assessment_score integer,
    priority_level text DEFAULT 'standard'::text,
    gender text,
    race_ethnicity text,
    email text,
    phone_number text,
    education_status text,
    health_status text,
    account_status text DEFAULT 'active'::text,
    CONSTRAINT persons_pkey PRIMARY KEY (person_id)
);

-- Create organizations table
CREATE TABLE IF NOT EXISTS public.organizations (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    name text NOT NULL,
    address text,
    phone_number text,
    email text,
    website text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT organizations_pkey PRIMARY KEY (id)
);

-- Create conversations table
CREATE TABLE IF NOT EXISTS public.conversations (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    last_message text,
    last_message_sender_id uuid,
    seen boolean DEFAULT false,
    last_activity_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT conversations_pkey PRIMARY KEY (id),
    CONSTRAINT conversations_last_message_sender_id_fkey FOREIGN KEY (last_message_sender_id) REFERENCES auth.users(id)
);

-- Create messages table
CREATE TABLE IF NOT EXISTS public.messages (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    conversation_id uuid,
    sender_id uuid,
    receiver_id uuid,
    text text NOT NULL,
    sent_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT messages_pkey PRIMARY KEY (id),
    CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES auth.users(id),
    CONSTRAINT messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES auth.users(id),
    CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id)
);

-- Create conversation_members table
CREATE TABLE IF NOT EXISTS public.conversation_members (
    conversation_id uuid NOT NULL,
    user_id uuid NOT NULL,
    CONSTRAINT conversation_members_pkey PRIMARY KEY (conversation_id, user_id),
    CONSTRAINT conversation_members_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id),
    CONSTRAINT conversation_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- Create appointments table
CREATE TABLE IF NOT EXISTS public.appointments (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text,
    date timestamp with time zone NOT NULL,
    location text,
    creator_id uuid,
    participant_id uuid,
    state text NOT NULL DEFAULT 'scheduled',
    status text NOT NULL DEFAULT 'active',
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT appointments_pkey PRIMARY KEY (id),
    CONSTRAINT appointments_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES auth.users(id),
    CONSTRAINT appointments_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES auth.users(id)
);

-- Create appointment_attendees table
CREATE TABLE IF NOT EXISTS public.appointment_attendees (
    appointment_id uuid NOT NULL,
    user_id uuid NOT NULL,
    CONSTRAINT appointment_attendees_pkey PRIMARY KEY (appointment_id, user_id),
    CONSTRAINT appointment_attendees_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.appointments(id),
    CONSTRAINT appointment_attendees_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- Create blog_posts table
CREATE TABLE IF NOT EXISTS public.blog_posts (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    title text NOT NULL,
    content text,
    category text,
    date timestamp with time zone,
    image_url text,
    author_id uuid,
    data jsonb DEFAULT '[]'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT blog_posts_pkey PRIMARY KEY (id),
    CONSTRAINT blog_posts_author_id_fkey FOREIGN KEY (author_id) REFERENCES auth.users(id)
);

-- Create incidents table
CREATE TABLE IF NOT EXISTS public.incidents (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    date timestamp with time zone,
    description text,
    reported_by_id uuid,
    victim_id uuid,
    response_count integer,
    title text,
    extra_data jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    person_id uuid,
    CONSTRAINT incidents_pkey PRIMARY KEY (id),
    CONSTRAINT incidents_reported_by_id_fkey FOREIGN KEY (reported_by_id) REFERENCES auth.users(id),
    CONSTRAINT incidents_victim_id_fkey FOREIGN KEY (victim_id) REFERENCES auth.users(id)
);

-- Create reports table
CREATE TABLE IF NOT EXISTS public.reports (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text,
    reported_by_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    person_id uuid,
    CONSTRAINT reports_pkey PRIMARY KEY (id),
    CONSTRAINT reports_reported_by_id_fkey FOREIGN KEY (reported_by_id) REFERENCES auth.users(id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_persons_email ON public.persons(email);
CREATE INDEX IF NOT EXISTS idx_conversations_last_activity ON public.conversations(last_activity_at);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON public.appointments(date);
CREATE INDEX IF NOT EXISTS idx_blog_posts_date ON public.blog_posts(date);

-- Enable Row Level Security (RLS)
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointment_attendees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for user_profiles
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Create RLS policies for conversations
CREATE POLICY "Users can view conversations they're part of" ON public.conversations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.conversation_members 
            WHERE conversation_id = id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert conversations" ON public.conversations
    FOR INSERT WITH CHECK (true);

-- Create RLS policies for messages
CREATE POLICY "Users can view messages in their conversations" ON public.messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.conversation_members 
            WHERE conversation_id = messages.conversation_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert messages" ON public.messages
    FOR INSERT WITH CHECK (sender_id = auth.uid());

-- Create RLS policies for appointments
CREATE POLICY "Users can view their appointments" ON public.appointments
    FOR SELECT USING (creator_id = auth.uid() OR participant_id = auth.uid());

CREATE POLICY "Users can create appointments" ON public.appointments
    FOR INSERT WITH CHECK (creator_id = auth.uid());

CREATE POLICY "Users can update their appointments" ON public.appointments
    FOR UPDATE USING (creator_id = auth.uid());

-- Create RLS policies for blog_posts
CREATE POLICY "Anyone can view blog posts" ON public.blog_posts
    FOR SELECT USING (true);

CREATE POLICY "Authors can create blog posts" ON public.blog_posts
    FOR INSERT WITH CHECK (author_id = auth.uid());

CREATE POLICY "Authors can update their blog posts" ON public.blog_posts
    FOR UPDATE USING (author_id = auth.uid());

-- Function to automatically set updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON public.user_profiles 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_conversations_updated_at 
    BEFORE UPDATE ON public.conversations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_appointments_updated_at 
    BEFORE UPDATE ON public.appointments 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_blog_posts_updated_at 
    BEFORE UPDATE ON public.blog_posts 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        NOW(),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user creation
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user(); 