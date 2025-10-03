import '../../model/messaging/conversation.dart';
import '../../model/messaging/message.dart';

// Clean Messaging Repository Interface
abstract class MessagingRepositoryInterface {
  // Conversations
  Future<List<Conversation>> getUserConversations(String userId);
  Future<Conversation?> getConversationById(String conversationId);
  Future<Conversation?> createConversation(String userId1, String userId2);
  Future<void> deleteConversation(String conversationId);
  
  // Messages
  Future<List<Message>> getConversationMessages(String conversationId);
  Future<Message?> sendMessage(String conversationId, String senderId, String content);
  Future<void> markMessageAsRead(String messageId);
  Future<void> deleteMessage(String messageId);
  
  // Real-time Updates
  Stream<List<Message>> watchConversationMessages(String conversationId);
  Stream<List<Conversation>> watchUserConversations(String userId);
  
  // Message Status
  Future<void> markConversationAsRead(String conversationId, String userId);
  Future<int> getUnreadMessageCount(String userId);
}
