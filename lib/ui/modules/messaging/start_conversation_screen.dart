import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/ui/components/app_bar.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/components/user_info_component.dart';
import 'package:reentry/ui/modules/clients/bloc/client_cubit.dart';
import 'package:reentry/ui/components/error_component.dart';
import 'package:reentry/ui/components/loading_component.dart';
import 'package:reentry/ui/modules/clients/bloc/client_state.dart';
import 'package:reentry/ui/modules/messaging/bloc/conversation_cubit.dart';
import 'package:reentry/ui/modules/messaging/bloc/state.dart';
import 'package:reentry/ui/modules/messaging/components/chat_list_component.dart';
import 'package:reentry/ui/modules/messaging/messaging_screen.dart';
import 'package:reentry/data/shared/share_preference.dart';
import 'package:reentry/data/repository/auth/auth_repository.dart';

class StartConversationScreen extends HookWidget {
  final bool showBack;
  const StartConversationScreen({super.key,this.showBack=true});

  @override
  Widget build(BuildContext context) {
    final personIdController = useTextEditingController();
    final personNameController = useTextEditingController();
    
    useEffect((){
      // Initialize controllers
    },[]);
    
    return BaseScaffold(
        appBar: CustomAppbar(
          title: 'Start conversation',
          showBack: showBack,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              20.height,
              Text(
                'Enter Person Details',
                style: context.textTheme.titleMedium,
              ),
              8.height,
              Text(
                'Enter the Person ID and name to start messaging',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray2,
                ),
              ),
              20.height,
              TextField(
                controller: personIdController,
                decoration: InputDecoration(
                  labelText: 'Person ID',
                  hintText: 'Enter the Person ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.gray1.withOpacity(0.1),
                ),
                style: context.textTheme.bodyMedium,
              ),
              16.height,
              TextField(
                controller: personNameController,
                decoration: InputDecoration(
                  labelText: 'Person Name',
                  hintText: 'Enter the person\'s name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.gray1.withOpacity(0.1),
                ),
                style: context.textTheme.bodyMedium,
              ),
              32.height,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final personId = personIdController.text.trim();
                    final personName = personNameController.text.trim();
                    
                    if (personId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a Person ID'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    if (personName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a Person Name'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Debug: Check current user
                    final currentUser = await PersistentStorage.getCurrentUser();
                    print('Current user for messaging: ${currentUser?.toJson()}');
                    print('Current user personId: ${currentUser?.personId}');
                    print('Current user userId: ${currentUser?.userId}');
                    
                    // Start conversation with entered person
                    context.pushRoute(MessagingScreen(
                        entity: ConversationComponent(
                            name: personName,
                            userId: personId, // Use as fallback
                            personId: personId, // Use entered personID
                            lastMessageSenderId: null,
                            conversationId: null,
                            accountType: AccountType.citizen,
                            lastMessage: '',
                            avatar: 'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png?20150327203541',
                            lastMessageTime: '')));
                  },
                                     icon: const Icon(Icons.search),
                   label: const Text('Find and Start Conversation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              // Removed test functionality
            ],
          ),
        ));
  }
}

Widget selectableUserContainer(
    {required String name,
    String? url,
    bool selected = false,
    required Function() onTap}) {
  return InkWell(
    radius: 50,
    borderRadius: BorderRadius.circular(50),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
              side: BorderSide(
                  color: selected ? AppColors.white : Colors.transparent))),
      child: UserInfoComponent(
        name: name,
        url: url,
        size: 40,
      ),
    ),
  );
}
