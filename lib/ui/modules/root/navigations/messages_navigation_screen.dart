import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/ui/components/error_component.dart';
import 'package:reentry/ui/components/loading_component.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';
import 'package:reentry/ui/modules/clients/bloc/client_state.dart';
import 'package:reentry/ui/modules/messaging/bloc/conversation_cubit.dart';
import 'package:reentry/ui/modules/messaging/bloc/state.dart';
import 'package:reentry/ui/modules/messaging/components/chat_list_component.dart';
import 'package:reentry/ui/modules/messaging/start_conversation_screen.dart';
// Removed import for deleted test component

import '../../../components/scaffold/base_scaffold.dart';
import '../../clients/bloc/client_cubit.dart';

class ConversationNavigation extends HookWidget {
  const ConversationNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      context.read<AccountCubit>().readFromLocalStorage();
      // Fetch conversations when screen loads
      final user = context.read<AccountCubit>().state;
      if (user != null) {
        context.read<ConversationCubit>().listenForConversationsUpdate();
      }
      return null;
    }, []);
    
    final user = context.watch<AccountCubit>().state;
    final conversationState = context.watch<ConversationCubit>().state;
    
    if (user == null) {
      return const Center(child: Text('Please log in again.'));
    }
    
    return BaseScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          20.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Messages', style: context.textTheme.titleSmall),
              Row(
                children: [
                  // Removed test button
                  // Start conversation button
                  InkWell(
                    onTap: () {
                      context.pushRoute(const StartConversationScreen());
                    },
                    child: const Icon(
                      Icons.add_circle_sharp,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ],
          ),
          20.height,
          Expanded(
            child: _buildConversationsList(context, conversationState),
          ),
        ],
      ),
    );
  }

          Widget _buildConversationsList(BuildContext context, MessagingState state) {
          if (state is ConversationLoading) {
            return const LoadingComponent();
          }
          
          if (state is ConversationError) {
            return ErrorComponent(
              title: state.error,
              showButton: true,
              onActionButtonClick: () {
                final user = context.read<AccountCubit>().state;
                if (user != null) {
                  context.read<ConversationCubit>().listenForConversationsUpdate();
                }
              },
            );
          }
    
    if (state is ConversationSuccessState) {
      final conversations = state.data;
      
      if (conversations.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: AppColors.gray2,
              ),
              16.height,
              Text(
                'No conversations yet',
                style: context.textTheme.titleMedium?.copyWith(
                  color: AppColors.gray2,
                ),
              ),
              8.height,
              Text(
                'Start a conversation by tapping the + button',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray2,
                ),
                textAlign: TextAlign.center,
              ),
              20.height,
              ElevatedButton.icon(
                onPressed: () {
                  context.pushRoute(const StartConversationScreen());
                },
                icon: const Icon(Icons.add),
                label: const Text('Start Conversation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.black,
                ),
              ),
            ],
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          
                          // Convert ConversationDto to ConversationComponent
                final conversationComponent = ConversationComponent(
                  name: conversation.otherUserName ?? conversation.name ?? 'Unknown User',
                  userId: conversation.otherUserId ?? '',
                  personId: conversation.otherUserPersonId,
                  conversationId: conversation.id,
                  lastMessage: conversation.lastMessage ?? 'No messages yet',
                  lastMessageTime: conversation.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(conversation.timestamp).beautify(withDate: false),
                  accountType: conversation.otherUserAccountType ?? AccountType.citizen,
                  avatar: conversation.otherUserAvatar ?? conversation.avatar ?? 'https://via.placeholder.com/150',
                  seen: conversation.isLastMessageSeen ?? conversation.seen ?? false,
                  lastMessageSenderId: conversation.lastMessageSenderId ?? '',
                );
          
          return ChatListComponent(entity: conversationComponent);
        },
      );
    }
    
    // Default empty state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.gray2,
          ),
          16.height,
          Text(
            'No conversations yet',
            style: context.textTheme.titleMedium?.copyWith(
              color: AppColors.gray2,
            ),
          ),
          8.height,
          Text(
            'Start a conversation by tapping the + button',
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColors.gray2,
            ),
            textAlign: TextAlign.center,
          ),
          20.height,
          ElevatedButton.icon(
            onPressed: () {
              context.pushRoute(const StartConversationScreen());
            },
            icon: const Icon(Icons.add),
            label: const Text('Start Conversation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
