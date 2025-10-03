import 'package:flutter_bloc/flutter_bloc.dart';
import 'messaging_state.dart';
import '../../../../data/repository/messaging/messaging_repository_interface.dart';

// Clean Messaging Cubit
class MessagingCubit extends Cubit<MessagingState> {
  final MessagingRepositoryInterface _messagingRepository;
  
  MessagingCubit({
    required MessagingRepositoryInterface messagingRepository,
  }) : _messagingRepository = messagingRepository,
       super(MessagingInitial());

  Future<void> loadConversations(String userId) async {
    emit(MessagingLoading());
    
    try {
      final conversations = await _messagingRepository.getUserConversations(userId);
      emit(ConversationsLoaded(conversations));
    } catch (e) {
      emit(MessagingError('Failed to load conversations: ${e.toString()}'));
    }
  }

  Future<void> loadMessages(String conversationId) async {
    emit(MessagingLoading());
    
    try {
      final messages = await _messagingRepository.getConversationMessages(conversationId);
      emit(MessagesLoaded(messages, conversationId));
    } catch (e) {
      emit(MessagingError('Failed to load messages: ${e.toString()}'));
    }
  }

  Future<void> sendMessage(String conversationId, String senderId, String content) async {
    try {
      final message = await _messagingRepository.sendMessage(conversationId, senderId, content);
      if (message != null) {
        emit(MessageSent(message));
        // Reload messages to get updated list
        await loadMessages(conversationId);
      }
    } catch (e) {
      emit(MessagingError('Failed to send message: ${e.toString()}'));
    }
  }

  Future<void> createConversation(String userId1, String userId2) async {
    try {
      final conversation = await _messagingRepository.createConversation(userId1, userId2);
      if (conversation != null) {
        emit(ConversationCreated(conversation));
      }
    } catch (e) {
      emit(MessagingError('Failed to create conversation: ${e.toString()}'));
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _messagingRepository.markMessageAsRead(messageId);
    } catch (e) {
      emit(MessagingError('Failed to mark message as read: ${e.toString()}'));
    }
  }

  Future<void> markConversationAsRead(String conversationId, String userId) async {
    try {
      await _messagingRepository.markConversationAsRead(conversationId, userId);
    } catch (e) {
      emit(MessagingError('Failed to mark conversation as read: ${e.toString()}'));
    }
  }

  Future<void> getUnreadCount(String userId) async {
    try {
      final count = await _messagingRepository.getUnreadMessageCount(userId);
      emit(UnreadCountUpdated(count));
    } catch (e) {
      emit(MessagingError('Failed to get unread count: ${e.toString()}'));
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _messagingRepository.deleteMessage(messageId);
    } catch (e) {
      emit(MessagingError('Failed to delete message: ${e.toString()}'));
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _messagingRepository.deleteConversation(conversationId);
    } catch (e) {
      emit(MessagingError('Failed to delete conversation: ${e.toString()}'));
    }
  }
}
