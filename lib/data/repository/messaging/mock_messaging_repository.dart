import 'messaging_repository_interface.dart';
import '../../model/messaging/conversation.dart';
import '../../model/messaging/message.dart';

// Mock Messaging Repository - Clean implementation with mock data
class MockMessagingRepository implements MessagingRepositoryInterface {
  static final List<Conversation> _conversations = [];
  static final List<Message> _messages = [];

  @override
  Future<List<Conversation>> getUserConversations(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return _conversations.where((c) => 
      c.userId1 == userId || c.userId2 == userId
    ).toList();
  }

  @override
  Future<Conversation?> getConversationById(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    try {
      return _conversations.firstWhere((c) => c.id == conversationId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Conversation?> createConversation(String userId1, String userId2) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Check if conversation already exists
    try {
      final existing = _conversations.firstWhere(
        (c) => (c.userId1 == userId1 && c.userId2 == userId2) ||
               (c.userId1 == userId2 && c.userId2 == userId1),
      );
      return existing;
    } catch (e) {
      // Conversation doesn't exist, create new one
    }
    
    // Create new conversation
    final conversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId1: userId1,
      userId2: userId2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _conversations.add(conversation);
    return conversation;
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _conversations.removeWhere((c) => c.id == conversationId);
    _messages.removeWhere((m) => m.conversationId == conversationId);
  }

  @override
  Future<List<Message>> getConversationMessages(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return _messages.where((m) => m.conversationId == conversationId)
        .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<Message?> sendMessage(String conversationId, String senderId, String content) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _messages.add(message);
    
    // Update conversation with last message
    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex != -1) {
      _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(
        lastMessageId: message.id,
        lastMessageContent: content,
        lastMessageAt: message.createdAt,
        updatedAt: DateTime.now(),
      );
    }
    
    return message;
  }

  @override
  Future<void> markMessageAsRead(String messageId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final messageIndex = _messages.indexWhere((m) => m.id == messageId);
    if (messageIndex != -1) {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        isRead: true,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _messages.removeWhere((m) => m.id == messageId);
  }

  @override
  Stream<List<Message>> watchConversationMessages(String conversationId) {
    return Stream.periodic(const Duration(seconds: 2), (_) {
      return _messages.where((m) => m.conversationId == conversationId)
          .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });
  }

  @override
  Stream<List<Conversation>> watchUserConversations(String userId) {
    return Stream.periodic(const Duration(seconds: 3), (_) {
      return _conversations.where((c) => 
        c.userId1 == userId || c.userId2 == userId
      ).toList();
    });
  }

  @override
  Future<void> markConversationAsRead(String conversationId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex != -1) {
      final conversation = _conversations[conversationIndex];
      final readStatus = Map<String, bool>.from(conversation.readStatus);
      readStatus[userId] = true;
      
      _conversations[conversationIndex] = conversation.copyWith(
        readStatus: readStatus,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<int> getUnreadMessageCount(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    int count = 0;
    for (final conversation in _conversations) {
      if (conversation.userId1 == userId || conversation.userId2 == userId) {
        if (!conversation.isReadBy(userId)) {
          count++;
        }
      }
    }
    return count;
  }

  // Helper methods for testing
  static void addMockConversation(Conversation conversation) {
    _conversations.add(conversation);
  }

  static void addMockMessage(Message message) {
    _messages.add(message);
  }

  static void clearMockData() {
    _conversations.clear();
    _messages.clear();
  }
}
