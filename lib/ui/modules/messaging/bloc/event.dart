import 'package:reentry/data/model/messaging/message_dto.dart';

class MessagingEvent {}

class SendMessageEvent extends MessagingEvent {
  final String text;
  final String receiverPersonId;
  final ReceiverInfo receiverInfo;

  SendMessageEvent({
    required this.receiverPersonId, 
    required this.text, 
    required this.receiverInfo
  });
}

class NewMessageEvent extends MessagingEvent {
  final List<MessageDto> data;

  NewMessageEvent(this.data);
}

class FetchMessagesEvent extends MessagingEvent {
  final String senderPersonId;
  final String receiverPersonId;

  FetchMessagesEvent({
    required this.senderPersonId,
    required this.receiverPersonId,
  });
}

class MarkMessageAsReadEvent extends MessagingEvent {
  final String messageId;

  MarkMessageAsReadEvent(this.messageId);
}
