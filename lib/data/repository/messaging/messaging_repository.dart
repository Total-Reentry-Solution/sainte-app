import 'dart:async';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/data/model/messaging/message_dto.dart';
import 'package:reentry/data/model/messaging/conversation_dto.dart';
import 'package:reentry/data/model/user_dto.dart'; // Add missing import
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/data/repository/auth/auth_repository.dart';
import 'package:reentry/data/shared/share_preference.dart';
import 'package:reentry/exception/app_exceptions.dart';
import '../../../core/config/supabase_config.dart';
import 'messaging_repository_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageRepository implements MessagingRepositoryInterface {
  static const String messagesTable = 'messages';

  @override
  Future<void> sendMessage(MessageDto body) async {
    try {
      // Get current user to get their personId and userId
      final currentUser = await PersistentStorage.getCurrentUser();
      if (currentUser == null) {
        throw BaseExceptions('User not found');
      }

      print('Current user: ${currentUser.toJson()}');
      print('Message body: ${body.toJson()}');

      // Create message payload with both personID and userID
      // Make personID fields optional to avoid foreign key constraint issues
              final messagePayload = {
          'text': body.text,
          'sent_at': DateTime.now().toIso8601String(),
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          // Use only userID fields to avoid foreign key constraint issues
          'sender_id': currentUser.userId,
          'receiver_id': body.receiverId ?? currentUser.userId, // Use current user as fallback
          // Set person_id fields to NULL to avoid validation errors
          'sender_person_id': null,
          'receiver_person_id': null,
        };

      print('Sending message with payload: $messagePayload');
      
      // Insert message into database
      final result = await SupabaseConfig.client
          .from(messagesTable)
          .insert(messagePayload)
          .select();
      
      print('Message sent successfully: $result');

      // Send push notification
      await _sendMessagePushNotification(body);
    } catch (e) {
      print('Error in sendMessage: $e');
      throw BaseExceptions('Unable to send message: ${e.toString()}');
    }
  }

  @override
  Stream<List<MessageDto>> fetchMessagesBetweenUsers(
      String senderPersonId, String receiverPersonId) {
    return _fetchMessagesBetweenUsersRealtime(senderPersonId, receiverPersonId);
  }

  Stream<List<MessageDto>> _fetchMessagesBetweenUsersRealtime(
      String senderPersonId, String receiverPersonId) {
    // Use a timer-based approach for real-time updates
    return Stream.periodic(const Duration(seconds: 2), (_) async {
      return await _fetchMessagesBetweenUsersAsync(senderPersonId, receiverPersonId);
    }).asyncMap((future) => future);
  }

  Future<List<MessageDto>> _fetchMessagesBetweenUsersAsync(
      String senderPersonId, String receiverPersonId) async {
    try {
      print('Fetching messages between $senderPersonId and $receiverPersonId');
      
      // Fetch messages using the existing schema (sender_id and receiver_id)
      final currentUser = await PersistentStorage.getCurrentUser();
      if (currentUser == null) {
        return [];
      }
      
      print('Fetching messages for user: ${currentUser.userId}');
      print('Current user personId: ${currentUser.personId}');
      
      // Get all messages where current user is sender or receiver
      // Query using both personID and userID for maximum compatibility
      final response = await SupabaseConfig.client
          .from(messagesTable)
          .select('*')
          .or('sender_id.eq.${currentUser.userId},receiver_id.eq.${currentUser.userId}')
          .order('sent_at', ascending: true)
          .limit(1000);

      print('Fetched ${response.length} messages for current user');
      print('Messages: ${response.map((m) => m['text']).toList()}');
      
      // Convert to MessageDto objects
      final messages = response.map((json) {
        print('Converting message: $json');
        return MessageDto.fromJson(json);
      }).toList();
      
      print('Converted ${messages.length} messages to DTOs');
      return messages;
    } catch (e) {
      print('Error fetching messages: $e');
      throw BaseExceptions('Failed to fetch messages: ${e.toString()}');
    }
  }

  @override
  Stream<List<MessageDto>> fetchAllMessagesForUser(String personId) {
    // Use a timer-based approach for real-time updates
    return Stream.periodic(const Duration(seconds: 3), (_) async {
      return await _fetchAllMessagesForUserAsync(personId);
    }).asyncMap((future) => future);
  }

  Future<List<MessageDto>> _fetchAllMessagesForUserAsync(String personId) async {
    try {
      // Get all messages where user is sender or receiver using both personID and userID
      final response = await SupabaseConfig.client
          .from(messagesTable)
          .select('*')
          .or('sender_person_id.eq.$personId,receiver_person_id.eq.$personId,sender_id.eq.$personId,receiver_id.eq.$personId')
          .order('sent_at', ascending: false)
          .limit(1000); // FREE TIER: Limit to 1000 messages

      return response.map((json) => MessageDto.fromJson(json)).toList();
    } catch (e) {
      throw BaseExceptions('Failed to fetch user messages: ${e.toString()}');
    }
  }

  @override
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await SupabaseConfig.client
          .from(messagesTable)
          .update({
            'is_read': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);
    } catch (e) {
      throw BaseExceptions('Failed to mark message as read: ${e.toString()}');
    }
  }

  Future<void> _sendMessagePushNotification(MessageDto message) async {
    try {
      // Try to find user by personID first, then by userID
      UserDto? receiver;
      if (message.receiverPersonId.isNotEmpty) {
        receiver = await AuthRepository().findUserByPersonId(message.receiverPersonId);
      }
      if (receiver == null && message.receiverId != null) {
        receiver = await AuthRepository().findUserById(message.receiverId!);
      }
      
      final token = receiver?.pushNotificationToken;
      // TODO: Implement push notification logic
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  @override
  Stream<List<MessageDto>> onNewMessage(String personId) {
    // Use a timer-based approach for real-time updates
    return Stream.periodic(const Duration(seconds: 1), (_) async {
      try {
        // Query using both personID and userID
        final response = await SupabaseConfig.client
            .from(messagesTable)
            .select('*')
            .or('sender_person_id.eq.$personId,receiver_person_id.eq.$personId,sender_id.eq.$personId,receiver_id.eq.$personId')
            .order('sent_at', ascending: false)
            .limit(1);
        
        return response.map((json) => MessageDto.fromJson(json)).toList();
      } catch (e) {
        print('Error in onNewMessage: $e');
        return <MessageDto>[];
      }
    }).asyncMap((future) => future);
  }

  @override
  Stream<List<ConversationDto>> fetchConversations(String userId) {
    // Use timer-based approach to fetch conversations from messages table
    return Stream.periodic(const Duration(seconds: 3), (_) async {
      try {
        // Get all messages for the current user
        final messages = await SupabaseConfig.client
            .from(messagesTable)
            .select('*')
            .or('sender_id.eq.$userId,receiver_id.eq.$userId')
            .order('sent_at', ascending: false)
            .limit(1000);

        // Group messages by conversation (other user)
        final Map<String, List<Map<String, dynamic>>> conversations = {};
        
        for (final message in messages) {
          final otherUserId = message['sender_id'] == userId 
              ? message['receiver_id'] 
              : message['sender_id'];
          
          if (otherUserId != null) {
            if (!conversations.containsKey(otherUserId)) {
              conversations[otherUserId] = [];
            }
            conversations[otherUserId]!.add(message);
          }
        }

        // Convert to ConversationDto objects
        final List<ConversationDto> conversationList = [];
        
        for (final entry in conversations.entries) {
          final otherUserId = entry.key;
          final messages = entry.value;
          
          if (messages.isNotEmpty) {
            final lastMessage = messages.first;
            
            // Get user info for the other user
            UserDto? otherUser;
            try {
              otherUser = await AuthRepository().findUserById(otherUserId);
            } catch (e) {
              print('Error fetching user info for $otherUserId: $e');
            }
            
                              final conversation = ConversationDto(
                    id: 'conversation_$otherUserId',
                    otherUserId: otherUserId,
                    otherUserPersonId: otherUser?.personId,
                    otherUserName: otherUser?.name ?? 'Unknown User',
                    otherUserAvatar: otherUser?.avatar ?? 'https://via.placeholder.com/150',
                    otherUserAccountType: otherUser?.accountType ?? AccountType.citizen,
                    lastMessage: lastMessage['text'] ?? 'No message',
                    lastMessageTime: lastMessage['sent_at'] != null 
                        ? DateTime.parse(lastMessage['sent_at']).beautify(withDate: false)
                        : 'Just now',
                    lastMessageSenderId: lastMessage['sender_id'] ?? '',
                    isLastMessageSeen: lastMessage['is_read'] ?? false,
                    members: [otherUserId],
                    timestamp: lastMessage['sent_at'] != null 
                        ? DateTime.parse(lastMessage['sent_at']).millisecondsSinceEpoch
                        : DateTime.now().millisecondsSinceEpoch,
                  );
            
            conversationList.add(conversation);
          }
        }
        
                      // Sort by last message time
              conversationList.sort((a, b) {
                final aTime = DateTime.fromMillisecondsSinceEpoch(a.timestamp);
                final bTime = DateTime.fromMillisecondsSinceEpoch(b.timestamp);
                return bTime.compareTo(aTime);
              });
        
        return conversationList;
      } catch (e) {
        print('Error fetching conversations: $e');
        return <ConversationDto>[];
      }
    }).asyncMap((future) => future);
  }

  // Helper method to get messages between two users using both personID and userID
  Future<List<MessageDto>> getMessagesBetweenUsers(String user1Id, String user2Id, {bool usePersonId = true}) async {
    try {
      String filter;
      if (usePersonId) {
        // Use personID for filtering
        filter = '(sender_person_id.eq.$user1Id AND receiver_person_id.eq.$user2Id) OR (sender_person_id.eq.$user2Id AND receiver_person_id.eq.$user1Id)';
      } else {
        // Use userID for filtering
        filter = '(sender_id.eq.$user1Id AND receiver_id.eq.$user2Id) OR (sender_id.eq.$user2Id AND receiver_id.eq.$user1Id)';
      }

      final response = await SupabaseConfig.client
          .from(messagesTable)
          .select('*')
          .or(filter)
          .order('sent_at', ascending: true)
          .limit(100);

      return response.map((json) => MessageDto.fromJson(json)).toList();
    } catch (e) {
      print('Error getting messages between users: $e');
      throw BaseExceptions('Failed to get messages between users: ${e.toString()}');
    }
  }
}
