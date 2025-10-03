import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'bloc/messaging_cubit.dart';
import 'bloc/messaging_state.dart';
import '../../../../data/model/messaging/conversation.dart';
import '../../../../data/model/messaging/message.dart';
import '../../../../data/repository/messaging/mock_messaging_repository.dart';
import '../../components/input/dark_input_field.dart';

// Clean Messages Screen
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _messageController = TextEditingController();
  String? _selectedConversationId;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MessagingCubit(
        messagingRepository: MockMessagingRepository(),
      )..loadConversations('current-user-id'), // Mock user ID
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Messages',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          actions: [
            IconButton(
              onPressed: () => _showNewConversationDialog(context),
              icon: const Icon(Icons.add, color: Colors.black),
            ),
          ],
        ),
        body: BlocConsumer<MessagingCubit, MessagingState>(
          listener: (context, state) {
            if (state is MessagingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is MessageSent) {
              _messageController.clear();
            }
          },
          builder: (context, state) {
            if (state is MessagingLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3AE6BD)),
                ),
              );
            }
            
            if (state is ConversationsLoaded) {
              return Row(
                children: [
                  // Conversations List
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Search Bar
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: DarkInputField(
                              controller: TextEditingController(),
                              hint: 'Search conversations...',
                            ),
                          ),
                          
                          // Conversations List
                          Expanded(
                            child: ListView.builder(
                              itemCount: state.conversations.length,
                              itemBuilder: (context, index) {
                                final conversation = state.conversations[index];
                                return _buildConversationTile(conversation);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Messages Area
                  Expanded(
                    flex: 2,
                    child: _selectedConversationId != null
                        ? _buildMessagesArea(_selectedConversationId!)
                        : _buildEmptyMessagesArea(),
                  ),
                ],
              );
            }
            
            return const Center(
              child: Text(
                'No conversations found',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final isSelected = _selectedConversationId == conversation.id;
    
    return ListTile(
      selected: isSelected,
      selectedTileColor: const Color(0xFF3AE6BD).withOpacity(0.1),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF3AE6BD),
        child: Text(
          conversation.otherUserId.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        'User ${conversation.otherUserId}',
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        conversation.lastMessageContent ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Text(
              _formatTime(conversation.lastMessageAt),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF3AE6BD),
              ),
            ),
          if (!conversation.isReadBy('current-user-id'))
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF3AE6BD),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: () {
        setState(() {
          _selectedConversationId = conversation.id;
        });
        context.read<MessagingCubit>().loadMessages(conversation.id);
      },
    );
  }

  Widget _buildMessagesArea(String conversationId) {
    return BlocBuilder<MessagingCubit, MessagingState>(
      builder: (context, state) {
        if (state is MessagesLoaded && state.conversationId == conversationId) {
          return Column(
            children: [
              // Messages Header
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF3AE6BD),
                      child: Text(
                        'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'User Name',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Messages List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
              
              // Message Input
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DarkInputField(
                        controller: _messageController,
                        hint: 'Type a message...',
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        if (_messageController.text.trim().isNotEmpty) {
                          context.read<MessagingCubit>().sendMessage(
                            conversationId,
                            'current-user-id',
                            _messageController.text.trim(),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.send,
                        color: Color(0xFF3AE6BD),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3AE6BD)),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = message.senderId == 'current-user-id';
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF3AE6BD) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: const TextStyle(
                color: Color(0xFF3AE6BD),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMessagesArea() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Select a conversation to start messaging',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showNewConversationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Start New Conversation',
            style: TextStyle(
              color: Color(0xFF3AE6BD),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'This feature will allow you to start conversations with mentors, officers, and other users.',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF3AE6BD),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
