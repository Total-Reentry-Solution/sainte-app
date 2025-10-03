import '../../../../data/model/messaging/conversation.dart';
import '../../../../data/model/messaging/message.dart';

// Clean Messaging State
abstract class MessagingState {}

class MessagingInitial extends MessagingState {}

class MessagingLoading extends MessagingState {}

class ConversationsLoaded extends MessagingState {
  final List<Conversation> conversations;
  
  ConversationsLoaded(this.conversations);
}

class MessagesLoaded extends MessagingState {
  final List<Message> messages;
  final String conversationId;
  
  MessagesLoaded(this.messages, this.conversationId);
}

class MessageSent extends MessagingState {
  final Message message;
  
  MessageSent(this.message);
}

class MessagingError extends MessagingState {
  final String message;
  
  MessagingError(this.message);
}

class ConversationCreated extends MessagingState {
  final Conversation conversation;
  
  ConversationCreated(this.conversation);
}

class UnreadCountUpdated extends MessagingState {
  final int unreadCount;
  
  UnreadCountUpdated(this.unreadCount);
}
