import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';
import 'package:reentry/ui/modules/messaging/modal/chat_option_modal.dart';
import 'components/chat_list_component.dart';
import 'components/realtime_chat_component.dart';

class MessagingScreen extends StatelessWidget {
  final ConversationComponent entity;

  const MessagingScreen({super.key, required this.entity});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AccountCubit>().state;
    
    if (user == null) {
      return const Center(
        child: Text("Messaging not available"),
      );
    }

    return BaseScaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () => context.popRoute(),
          child: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.white,
          ),
        ),
        title: Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CircleAvatar(
                backgroundImage: NetworkImage(entity.avatar),
              ),
            ),
            10.width,
            Text(
              entity.name,
              style: context.textTheme.bodyLarge,
            )
          ],
        ),
        actions: [
          InkWell(
            onTap: () {
              context.showModal(ChatOptionModal(
                entity: entity,
                onBlock: () {
                  //todo perform block operation to update channel.
                  context.popRoute();
                },
              ));
            },
            child: const Icon(
              Icons.more_vert,
              color: AppColors.white,
            ),
          )
        ],
      ),
      child: RealtimeChatComponent(
        receiverPersonId: entity.personId ?? entity.userId,
        receiverUserId: entity.userId, // Pass the userID as well
        receiverName: entity.name,
        receiverAvatar: entity.avatar,
        receiverAccountType: entity.accountType,
      ),
    );
  }
}
