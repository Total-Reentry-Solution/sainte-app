-- Complete Supabase Real-time Setup for Messaging - FREE TIER OPTIMIZED
-- This script enables real-time functionality for the messages table
-- Optimized for Supabase free tier: 500MB database, 2GB bandwidth, 50,000 monthly active users

-- 1. Enable real-time on the messages table (FREE TIER FEATURE)
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;

-- 2. Enable Row Level Security (FREE TIER FEATURE)
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their messages" ON public.messages;
DROP POLICY IF EXISTS "Users can insert messages" ON public.messages;
DROP POLICY IF EXISTS "Users can update their messages" ON public.messages;
DROP POLICY IF EXISTS "Users can delete their messages" ON public.messages;

-- 4. Create comprehensive RLS policies (FREE TIER FEATURE)
-- Policy for viewing messages (users can see messages they sent or received)
CREATE POLICY "Users can view their messages" ON public.messages
  FOR SELECT USING (
    sender_id = auth.uid() OR receiver_id = auth.uid()
  );

-- Policy for inserting messages (users can only insert messages as themselves)
CREATE POLICY "Users can insert messages" ON public.messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid()
  );

-- Policy for updating messages (users can only update their own messages)
CREATE POLICY "Users can update their messages" ON public.messages
  FOR UPDATE USING (
    sender_id = auth.uid()
  );

-- Policy for deleting messages (users can only delete their own messages)
CREATE POLICY "Users can delete their messages" ON public.messages
  FOR DELETE USING (
    sender_id = auth.uid()
  );

-- 5. Create indexes for better performance (FREE TIER OPTIMIZED)
-- Only essential indexes to stay within free tier limits
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_sent_at ON public.messages(sent_at);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(sender_id, receiver_id, sent_at);

-- 6. Create a function to handle real-time notifications (FREE TIER FEATURE)
CREATE OR REPLACE FUNCTION handle_message_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- This function can be extended to send push notifications
  -- or perform other actions when messages are inserted/updated
  -- FREE TIER: Basic notification handling
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Create triggers for real-time notifications (FREE TIER FEATURE)
DROP TRIGGER IF EXISTS on_message_insert ON public.messages;
CREATE TRIGGER on_message_insert
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION handle_message_notification();

DROP TRIGGER IF EXISTS on_message_update ON public.messages;
CREATE TRIGGER on_message_update
  AFTER UPDATE ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION handle_message_notification();

-- 8. Create a function to get conversation messages (FREE TIER OPTIMIZED)
CREATE OR REPLACE FUNCTION get_conversation_messages(
  user1_id UUID,
  user2_id UUID,
  limit_count INTEGER DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  sender_id UUID,
  receiver_id UUID,
  text TEXT,
  sent_at TIMESTAMPTZ,
  is_read BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.id,
    m.sender_id,
    m.receiver_id,
    m.text,
    m.sent_at,
    m.is_read,
    m.created_at,
    m.updated_at
  FROM public.messages m
  WHERE (m.sender_id = user1_id AND m.receiver_id = user2_id)
     OR (m.sender_id = user2_id AND m.receiver_id = user1_id)
  ORDER BY m.sent_at ASC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Create a function to mark messages as read (FREE TIER OPTIMIZED)
CREATE OR REPLACE FUNCTION mark_messages_as_read(
  conversation_user_id UUID,
  current_user_id UUID
)
RETURNS INTEGER AS $$
DECLARE
  updated_count INTEGER;
BEGIN
  UPDATE public.messages
  SET is_read = true, updated_at = NOW()
  WHERE receiver_id = current_user_id 
    AND sender_id = conversation_user_id
    AND is_read = false;
  
  GET DIAGNOSTICS updated_count = ROW_COUNT;
  RETURN updated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Create a view for unread message counts (FREE TIER OPTIMIZED)
CREATE OR REPLACE VIEW unread_message_counts AS
SELECT 
  sender_id,
  COUNT(*) as unread_count
FROM public.messages
WHERE is_read = false
GROUP BY sender_id;

-- Enable real-time on the view (FREE TIER FEATURE)
ALTER PUBLICATION supabase_realtime ADD TABLE unread_message_counts;

-- 11. Create a function to get recent conversations (FREE TIER OPTIMIZED)
CREATE OR REPLACE FUNCTION get_recent_conversations(current_user_id UUID)
RETURNS TABLE (
  conversation_user_id UUID,
  conversation_user_name TEXT,
  last_message TEXT,
  last_message_time TIMESTAMPTZ,
  unread_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  WITH conversation_summaries AS (
    SELECT 
      CASE 
        WHEN m.sender_id = current_user_id THEN m.receiver_id
        ELSE m.sender_id
      END as conversation_user_id,
      m.text as last_message,
      m.sent_at as last_message_time,
      ROW_NUMBER() OVER (
        PARTITION BY 
          CASE 
            WHEN m.sender_id = current_user_id THEN m.receiver_id
            ELSE m.sender_id
          END
        ORDER BY m.sent_at DESC
      ) as rn
    FROM public.messages m
    WHERE m.sender_id = current_user_id OR m.receiver_id = current_user_id
  ),
  unread_counts AS (
    SELECT 
      sender_id as conversation_user_id,
      COUNT(*) as unread_count
    FROM public.messages
    WHERE receiver_id = current_user_id AND is_read = false
    GROUP BY sender_id
  )
  SELECT 
    cs.conversation_user_id,
    COALESCE(up.name, 'Unknown User') as conversation_user_name,
    cs.last_message,
    cs.last_message_time,
    COALESCE(uc.unread_count, 0) as unread_count
  FROM conversation_summaries cs
  LEFT JOIN public.user_profiles up ON up.id = cs.conversation_user_id
  LEFT JOIN unread_counts uc ON uc.conversation_user_id = cs.conversation_user_id
  WHERE cs.rn = 1
  ORDER BY cs.last_message_time DESC
  LIMIT 50; -- FREE TIER: Limit to 50 recent conversations
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. Create a function to cleanup old messages (OPTIONAL - FREE TIER OPTIMIZED)
-- This helps stay within the 500MB database limit
CREATE OR REPLACE FUNCTION cleanup_old_messages(days_to_keep INTEGER DEFAULT 365)
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM public.messages
  WHERE sent_at < NOW() - INTERVAL '1 day' * days_to_keep
    AND is_read = true; -- Only delete read messages
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. Grant necessary permissions to authenticated users (FREE TIER FEATURE)
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.messages TO authenticated;
GRANT EXECUTE ON FUNCTION get_conversation_messages(UUID, UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION mark_messages_as_read(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_recent_conversations(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_old_messages(INTEGER) TO authenticated;
GRANT SELECT ON unread_message_counts TO authenticated;

-- 14. Final verification queries (FREE TIER COMPATIBLE)
-- Check if real-time is enabled
SELECT schemaname, tablename, hasreplica 
FROM pg_stat_user_tables 
WHERE tablename = 'messages';

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'messages';

-- Check indexes
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'messages';

-- FREE TIER USAGE MONITORING
-- You can run these queries to monitor your free tier usage:
-- SELECT pg_size_pretty(pg_database_size(current_database())); -- Check database size
-- SELECT count(*) FROM public.messages; -- Check message count
-- SELECT count(*) FROM auth.users; -- Check user count 