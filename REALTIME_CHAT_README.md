# 🚀 Supabase Real-time Chat System

A complete real-time messaging system built with Flutter and Supabase, featuring instant message delivery, real-time updates, and a modern chat interface.

## ✨ Features

### 🔥 Real-time Messaging
- **Instant message delivery** using Supabase real-time channels
- **Live message updates** across all connected clients
- **Automatic UI refresh** when new messages arrive
- **Message status indicators** (sent, delivered, read)

### 💬 Chat Interface
- **Modern chat bubbles** with sender/receiver distinction
- **Auto-scroll to bottom** when new messages arrive
- **Date separators** for message organization
- **Avatar display** for user identification
- **Message timestamps** with relative time formatting

### 🔐 Security & Privacy
- **Row Level Security (RLS)** policies for message access
- **User authentication** required for messaging
- **Message ownership** validation
- **Secure real-time subscriptions**

### 📱 User Experience
- **Responsive design** for all screen sizes
- **Loading states** and error handling
- **Offline message queuing** (future enhancement)
- **Push notifications** support (ready for implementation)

## 🏗️ Architecture

### Components

1. **RealtimeChatComponent** - Main chat interface
2. **MessageBubble** - Individual message display
3. **MessageInput** - Message composition interface
4. **MessageRepository** - Data layer with real-time streams

### Database Schema

```sql
-- Messages table structure with dual ID support
CREATE TABLE public.messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  -- User ID fields (for backward compatibility)
  sender_id UUID REFERENCES auth.users(id),
  receiver_id UUID REFERENCES auth.users(id),
  -- Person ID fields (for new functionality)
  sender_person_id UUID REFERENCES public.persons(person_id),
  receiver_person_id UUID REFERENCES public.persons(person_id),
  text TEXT NOT NULL,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Dual ID Support

The system supports both **userID** and **personID** for maximum flexibility:

- **userID**: Traditional Supabase auth user identifier
- **personID**: Custom person identifier for enhanced functionality
- **Automatic fallback**: Uses personID if available, falls back to userID
- **Backward compatibility**: Works with existing userID-based systems

## 🚀 Setup Instructions

### 1. Database Setup

Run the complete SQL migration:

```sql
-- Execute the file: sql fixes/enable_supabase_realtime_complete.sql
```

This will:
- Enable real-time on the messages table
- Set up RLS policies
- Create performance indexes
- Add helper functions
- Configure triggers

### 2. Flutter Implementation

The system uses these key files:

- `lib/ui/modules/messaging/components/realtime_chat_component.dart` - Main chat component
- `lib/data/repository/messaging/messaging_repository.dart` - Data layer
- `lib/ui/modules/messaging/messaging_screen.dart` - Chat screen wrapper

### 3. Usage Example

```dart
// Basic usage with personID
RealtimeChatComponent(
  receiverPersonId: 'user-person-id',
  receiverUserId: 'user-id', // Optional: for backward compatibility
  receiverName: 'John Doe',
  receiverAvatar: 'https://example.com/avatar.jpg',
  receiverAccountType: AccountType.citizen,
)

// Usage with only userID (backward compatibility)
RealtimeChatComponent(
  receiverPersonId: 'user-id', // Will be used as personID
  receiverUserId: 'user-id',   // Same value for userID
  receiverName: 'John Doe',
  receiverAvatar: 'https://example.com/avatar.jpg',
  receiverAccountType: AccountType.citizen,
)

// In a screen
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: AppBar(title: Text('Chat')),
      child: RealtimeChatComponent(
        receiverPersonId: 'target-person-id',
        receiverUserId: 'target-user-id', // Optional
        receiverName: 'Target User',
        receiverAvatar: 'avatar-url',
        receiverAccountType: AccountType.citizen,
      ),
    );
  }
}
```

## 🔧 Real-time Implementation

### Supabase Channels

The system uses Supabase real-time channels for instant messaging:

```dart
// Subscribe to PostgreSQL changes
final channel = SupabaseConfig.client.channel('chat:${userId}');
final subscription = channel
    .on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeType.insert,
          filter: 'sender_id=eq.$userId OR receiver_id=eq.$userId',
        ),
      ),
      (payload, [ref]) {
        // Handle new message
        _handleNewMessage(payload);
      },
    )
    .subscribe();
```

### Message Flow

1. **User types message** → Message input component
2. **Message sent** → Inserted into Supabase database
3. **Real-time trigger** → PostgreSQL change event fired
4. **Channel notification** → All subscribed clients notified
5. **UI update** → Message appears instantly on all devices

## 📊 Performance Features

### Database Optimizations

- **Indexed queries** for fast message retrieval
- **RLS policies** for secure data access
- **Connection pooling** for efficient database usage
- **Message pagination** for large conversations

### Real-time Optimizations

- **Efficient subscriptions** with targeted filters
- **Message deduplication** to prevent duplicates
- **Connection management** with automatic reconnection
- **Memory management** with proper cleanup

## 🔒 Security Features

### Row Level Security (RLS)

```sql
-- Users can only see messages they sent or received
CREATE POLICY "Users can view their messages" ON public.messages
  FOR SELECT USING (
    sender_id = auth.uid() OR receiver_id = auth.uid()
  );

-- Users can only insert messages as themselves
CREATE POLICY "Users can insert messages" ON public.messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid()
  );
```

### Authentication

- **Supabase Auth** integration
- **User session management**
- **Secure API endpoints**
- **Token-based authentication**

## 🎨 UI/UX Features

### Message Bubbles

- **Different colors** for sent vs received messages
- **Avatar display** for user identification
- **Timestamp formatting** with relative time
- **Message status** indicators

### Input Interface

- **Multi-line support** for long messages
- **Send button** with visual feedback
- **Enter key** support for quick sending
- **Input validation** and error handling

### Responsive Design

- **Mobile-first** approach
- **Adaptive layouts** for different screen sizes
- **Touch-friendly** interface
- **Accessibility** support

## 🧪 Testing

### Test Screen

Use the test screen to verify functionality:

```dart
// Navigate to test screen
context.go('/realtime-chat-test');
```

### Manual Testing

1. **Send messages** between different users
2. **Verify real-time updates** across devices
3. **Test offline behavior** and reconnection
4. **Check message persistence** after app restart

## 🔮 Future Enhancements

### Planned Features

- **Push notifications** for new messages
- **Message reactions** and emoji support
- **File attachments** and media sharing
- **Voice messages** and audio support
- **Message search** and filtering
- **Conversation archiving**

### Technical Improvements

- **Message encryption** for enhanced privacy
- **Offline message queuing** for reliability
- **Message delivery receipts** for confirmation
- **Typing indicators** for real-time feedback
- **Message editing** and deletion
- **Conversation management** tools

## 🐛 Troubleshooting

### Common Issues

1. **Messages not appearing**
   - Check real-time subscription
   - Verify RLS policies
   - Check network connectivity

2. **Real-time not working**
   - Ensure Supabase real-time is enabled
   - Check channel subscription
   - Verify database triggers

3. **Performance issues**
   - Check database indexes
   - Monitor connection limits
   - Optimize query patterns

### Debug Information

Enable debug logging:

```dart
// In your app initialization
SupabaseConfig.client.realtime.setLogLevel(LogLevel.debug);
```

## 📚 API Reference

### RealtimeChatComponent

```dart
class RealtimeChatComponent extends HookWidget {
  final String receiverPersonId;    // Required: person identifier
  final String? receiverUserId;     // Optional: user identifier for backward compatibility
  final String receiverName;
  final String receiverAvatar;
  final AccountType receiverAccountType;
}
```

### MessageRepository

```dart
class MessageRepository {
  Future<void> sendMessage(MessageDto body);
  Stream<List<MessageDto>> fetchMessagesBetweenUsers(String senderId, String receiverId);
  Stream<List<MessageDto>> onNewMessage(String personId);
  Future<void> markMessageAsRead(String messageId);
}
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Implement your changes
4. Add tests and documentation
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Built with ❤️ using Flutter and Supabase** 