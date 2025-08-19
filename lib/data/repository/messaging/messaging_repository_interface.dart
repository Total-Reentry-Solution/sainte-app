import 'package:reentry/data/model/messaging/message_dto.dart';
import 'package:reentry/data/model/messaging/conversation_dto.dart';

abstract class MessagingRepositoryInterface {
  Future<void> sendMessage(MessageDto body);

  Stream<List<MessageDto>> fetchMessagesBetweenUsers(
      String senderPersonId, String receiverPersonId);

  Stream<List<MessageDto>> fetchAllMessagesForUser(String personId);

  Future<void> markMessageAsRead(String messageId);
  
  Stream<List<MessageDto>> onNewMessage(String personId);
  
  Stream<List<ConversationDto>> fetchConversations(String userId);
}
