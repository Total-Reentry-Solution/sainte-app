-- Enable real-time for the messages table
-- This allows Supabase to send real-time updates when messages are inserted/updated

-- Enable real-time on the messages table
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;

-- Create a function to handle real-time message notifications
CREATE OR REPLACE FUNCTION handle_new_message()
RETURNS TRIGGER AS $$
BEGIN
  -- This function can be used to send additional notifications
  -- or perform other actions when a new message is inserted
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to call the function when a new message is inserted
CREATE TRIGGER on_new_message
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_message();

-- Enable Row Level Security for real-time to work properly
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows users to see messages they're involved in
CREATE POLICY "Users can view their messages" ON public.messages
  FOR SELECT USING (
    sender_id = auth.uid() OR receiver_id = auth.uid()
  );

-- Create a policy that allows users to insert messages
CREATE POLICY "Users can insert messages" ON public.messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid()
  );

-- Create a policy that allows users to update their own messages
CREATE POLICY "Users can update their messages" ON public.messages
  FOR UPDATE USING (
    sender_id = auth.uid()
  ); 