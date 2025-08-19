import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/data/model/messaging/message_dto.dart';
import 'package:reentry/ui/components/error_component.dart';
import 'package:reentry/ui/components/loading_component.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';
import 'package:reentry/ui/modules/messaging/bloc/event.dart';
import 'package:reentry/ui/modules/messaging/bloc/message_cubit.dart';
import 'package:reentry/ui/modules/messaging/bloc/state.dart';
import 'package:reentry/data/shared/share_preference.dart';
import '../../../../core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chat_bubbles/date_chips/date_chip.dart';

class RealtimeChatComponent extends HookWidget {
  final String receiverPersonId;
  final String? receiverUserId; // Add support for userID
  final String receiverName;
  final String receiverAvatar;
  final AccountType receiverAccountType;

  const RealtimeChatComponent({
    super.key,
    required this.receiverPersonId,
    this.receiverUserId, // Optional userID
    required this.receiverName,
    required this.receiverAvatar,
    required this.receiverAccountType,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final scrollController = useScrollController();
    final messages = useState<List<MessageDto>>([]);
    final isLoading = useState<bool>(true);
    final error = useState<String?>(null);
    final currentUser = context.read<AccountCubit>().state;

    // Real-time subscription using timer-based approach
    useEffect(() {
      if (currentUser == null) return null;

      // Use personID if available, otherwise fallback to userID
      final currentUserId = currentUser.personId ?? currentUser.userId ?? '';
      
      print('Setting up real-time chat for user: $currentUserId');
      print('Current user - personId: ${currentUser.personId}, userId: ${currentUser.userId}');
      print('Receiver - personId: $receiverPersonId, userId: $receiverUserId');

      // Load initial messages
      _loadInitialMessages(currentUser, messages, isLoading, error);

      // Set up timer-based polling for real-time updates
      final timer = Timer.periodic(const Duration(seconds: 2), (_) {
        _loadInitialMessages(currentUser, messages, isLoading, error);
      });

      return () {
        print('Cleaning up real-time subscription');
        timer.cancel();
      };
    }, [currentUser?.userId, currentUser?.personId]);

    // Auto-scroll to bottom when new messages arrive
    useEffect(() {
      if (messages.value.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
      return null;
    }, [messages.value.length]);

    if (currentUser == null) {
      return const ErrorComponent(
        title: "User not authenticated",
        showButton: false,
      );
    }

    if (isLoading.value) {
      return const LoadingComponent();
    }

    if (error.value != null) {
      return ErrorComponent(
        title: error.value!,
        showButton: true,
        onActionButtonClick: () => _loadInitialMessages(currentUser, messages, isLoading, error),
      );
    }

    return Column(
      children: [
        // Messages List
        Expanded(
          child: messages.value.isEmpty
              ? const Center(
                  child: Text(
                    "No messages yet. Start the conversation!",
                    style: TextStyle(color: AppColors.gray2),
                  ),
                )
              : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.value.length,
                  separatorBuilder: (context, index) {
                    if (index == 0 || index == messages.value.length - 1) {
                      return const SizedBox(height: 8);
                    }
                    
                    final previous = messages.value[index];
                    final current = messages.value[index + 1];
                    final previousDate = DateTime.fromMillisecondsSinceEpoch(
                        previous.timestamp ?? DateTime.now().millisecondsSinceEpoch);
                    final currentDate = DateTime.fromMillisecondsSinceEpoch(
                        current.timestamp ?? DateTime.now().millisecondsSinceEpoch);

                    if (previousDate.formatDate() != currentDate.formatDate()) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: DateChip(
                          date: previousDate,
                          color: AppColors.gray1,
                        ),
                      );
                    }
                    return const SizedBox(height: 8);
                  },
                  itemBuilder: (context, index) {
                    final message = messages.value[index];
                    
                    // Check if message is sent by current user using both personID and userID
                    final isSentByCurrentUser = 
                        message.senderPersonId == currentUser.personId ||
                        message.senderPersonId == currentUser.userId ||
                        message.senderId == currentUser.userId;

                    return _MessageBubble(
                      message: message,
                      isSentByCurrentUser: isSentByCurrentUser,
                      currentUser: currentUser,
                    );
                  },
                ),
        ),

        // Message Input
        _MessageInput(
          controller: controller,
          onSend: (text) => _sendMessage(
            context,
            text,
            controller,
            currentUser,
            messages,
            scrollController,
          ),
        ),
      ],
    );
  }

  void _handleNewMessage(
    Map<String, dynamic> payload,
    ValueNotifier<List<MessageDto>> messages,
    dynamic currentUser,
  ) {
    try {
      final newMessage = MessageDto.fromJson(payload['new']);
      
      // Only add if it's not already in the list
      if (!messages.value.any((m) => m.id == newMessage.id)) {
        print('Adding new message to UI: ${newMessage.text}');
        messages.value = [...messages.value, newMessage];
      }
    } catch (e) {
      print('Error handling new message: $e');
    }
  }

  void _handleMessageUpdate(
    Map<String, dynamic> payload,
    ValueNotifier<List<MessageDto>> messages,
  ) {
    try {
      final updatedMessage = MessageDto.fromJson(payload['new']);
      final index = messages.value.indexWhere((m) => m.id == updatedMessage.id);
      
      if (index != -1) {
        final newMessages = List<MessageDto>.from(messages.value);
        newMessages[index] = updatedMessage;
        messages.value = newMessages;
      }
    } catch (e) {
      print('Error handling message update: $e');
    }
  }

  Future<void> _loadInitialMessages(
    dynamic currentUser,
    ValueNotifier<List<MessageDto>> messages,
    ValueNotifier<bool> isLoading,
    ValueNotifier<String?> error,
  ) async {
    try {
      if (isLoading.value) {
        isLoading.value = true;
        error.value = null;
      }

      print('Loading initial messages for user: ${currentUser.userId}');
      print('Receiver personId: $receiverPersonId, userId: $receiverUserId');

      // Query messages between current user and receiver only
      final response = await SupabaseConfig.client
          .from('messages')
          .select('*')
          .or('and(sender_id.eq.${currentUser.userId},receiver_id.eq.${receiverUserId}),and(sender_id.eq.${receiverUserId},receiver_id.eq.${currentUser.userId})')
          .order('sent_at', ascending: true)
          .limit(100);

      print('Loaded ${response.length} initial messages');

      final loadedMessages = response.map((json) {
        print('Converting message: $json');
        return MessageDto.fromJson(json);
      }).toList();
      
      messages.value = loadedMessages;
    } catch (e) {
      error.value = 'Failed to load messages: ${e.toString()}';
      print('Error loading messages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _sendMessage(
    BuildContext context,
    String text,
    TextEditingController controller,
    dynamic currentUser,
    ValueNotifier<List<MessageDto>> messages,
    ScrollController scrollController,
  ) async {
    if (text.trim().isEmpty) return;

    try {
      print('Sending message to receiver - personId: $receiverPersonId, userId: $receiverUserId');
      
                     // Validate receiver ID before sending
        if (receiverUserId == null || receiverUserId?.isEmpty == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid receiver. Please select a valid user.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Create message payload with only userID fields to avoid person_id validation issues
        final messagePayload = {
          'text': text.trim(),
          'sent_at': DateTime.now().toUtc().toIso8601String(), // Use UTC time
          'is_read': false,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          // Use only userID fields to avoid foreign key constraint issues
          'sender_id': currentUser.userId,
          'receiver_id': receiverUserId, // Use the provided receiver ID
          // Set person_id fields to NULL to avoid validation errors
          'sender_person_id': null,
          'receiver_person_id': null,
        };

      print('Message payload: $messagePayload');

      final result = await SupabaseConfig.client
          .from('messages')
          .insert(messagePayload)
          .select()
          .single();

      // Add message to local state immediately for instant feedback
      final newMessage = MessageDto.fromJson(result);
      print('Message sent successfully: ${newMessage.text}');
      messages.value = [...messages.value, newMessage];

      // Clear input
      controller.clear();

      // Scroll to bottom
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageDto message;
  final bool isSentByCurrentUser;
  final dynamic currentUser;

  const _MessageBubble({
    required this.message,
    required this.isSentByCurrentUser,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isSentByCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isSentByCurrentUser) ...[
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(currentUser?.avatar ?? ''),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSentByCurrentUser ? AppColors.primary : AppColors.gray1,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: isSentByCurrentUser ? AppColors.black : AppColors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateTime.fromMillisecondsSinceEpoch(
                    message.timestamp ?? DateTime.now().millisecondsSinceEpoch,
                  ).beautify(withDate: false),
                  style: TextStyle(
                    color: isSentByCurrentUser 
                        ? AppColors.black.withOpacity(0.7)
                        : AppColors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isSentByCurrentUser) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(currentUser?.avatar ?? ''),
          ),
        ],
      ],
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;

  const _MessageInput({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.black,
        border: Border(
          top: BorderSide(color: AppColors.gray2, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.white),
              cursorColor: AppColors.primary,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: AppColors.gray2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: AppColors.gray2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: AppColors.gray2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: onSend,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => onSend(controller.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: AppColors.black,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 