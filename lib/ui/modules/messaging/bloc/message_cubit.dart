import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/data/model/messaging/message_dto.dart';
import 'package:reentry/data/shared/share_preference.dart';
import 'package:reentry/ui/modules/messaging/bloc/event.dart';
import 'package:reentry/ui/modules/messaging/bloc/state.dart';

import '../../../../data/repository/messaging/messaging_repository.dart';

class MessageCubit extends Cubit<MessagingState> {
  MessageCubit() : super(MessagingState());

  final _repo = MessageRepository();

  Future<void> sendMessage(
      SendMessageEvent body, Function(String?) conversationResult) async {
    final user = await PersistentStorage.getCurrentUser();
    if (user == null) {
      return;
    }
    
    // Create message with personIDs
    final payload = MessageDto(
      senderPersonId: user.personId ?? '',
      receiverPersonId: body.receiverPersonId, // This should be personID
      text: body.text,
      receiverInfo: body.receiverInfo,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      // Send message to database
      await _repo.sendMessage(payload);
      
      // The real-time stream will automatically update the UI
      // No need to manually refresh
    } catch (e) {
      emit(MessagingError(e.toString()));
    }
  }

  Future<void> streamMessagesBetweenUsers(String senderPersonId, String receiverPersonId) async {
    emit(MessagingState());
    if (senderPersonId.isEmpty || receiverPersonId.isEmpty) {
      return;
    }
    
    emit(MessagingLoading());
    try {
      // Use the real-time stream from Supabase
      final result = _repo.fetchMessagesBetweenUsers(senderPersonId, receiverPersonId);
      result.listen((result) {
        print('MessageCubit received ${result.length} messages');
        emit(MessagesSuccessState(result));
      }, onError: (error) {
        print('Error in message stream: $error');
        emit(MessagingError(error.toString()));
      });
    } catch (e) {
      emit(MessagingError(e.toString()));
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _repo.markMessageAsRead(messageId);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> fetchAllMessagesForUser(String personId) async {
    emit(MessagingLoading());
    try {
      // Use the real-time stream from Supabase
      final result = _repo.fetchAllMessagesForUser(personId);
      result.listen((result) {
        print('MessageCubit received ${result.length} messages for user');
        emit(MessagesSuccessState(result));
      }, onError: (error) {
        print('Error in user message stream: $error');
        emit(MessagingError(error.toString()));
      });
    } catch (e) {
      emit(MessagingError(e.toString()));
    }
  }

  // Subscribe to new messages for the current user
  Future<void> subscribeToNewMessages() async {
    final user = await PersistentStorage.getCurrentUser();
    if (user == null) return;

    try {
      final newMessagesStream = _repo.onNewMessage(user.personId ?? user.userId ?? '');
      newMessagesStream.listen((messages) {
        if (messages.isNotEmpty) {
          print('New message received: ${messages.first.text}');
          // You can emit a notification state here if needed
        }
      }, onError: (error) {
        print('Error in new messages subscription: $error');
      });
    } catch (e) {
      print('Error setting up new messages subscription: $e');
    }
  }
}
