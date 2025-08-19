import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/ui/components/app_bar.dart';
import 'package:reentry/ui/components/container/box_container.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/components/error_component.dart';
import 'package:reentry/ui/components/loading_component.dart';
import 'package:reentry/ui/modules/careTeam/bloc/care_team_invitations_cubit.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';
import 'package:reentry/data/model/care_team_invitation_dto.dart';
import 'package:reentry/data/model/care_team_assignment_dto.dart';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/ui/modules/careTeam/dialog/invite_user_dialog.dart';

class CareTeamInvitationsScreen extends StatelessWidget {
  const CareTeamInvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AccountCubit>().state;
    if (currentUser == null) {
      return const Center(child: Text('Please log in again.'));
    }

    // Only show this screen for care team members (not citizens or admins)
    if (currentUser.accountType == AccountType.citizen || currentUser.accountType == AccountType.admin) {
      return const Center(child: Text('This feature is only available for care team members.'));
    }

    return BlocProvider(
      create: (context) => CareTeamInvitationsCubit()..fetchInvitationsForUser(currentUser.userId!),
      child: BaseScaffold(
        appBar: const CustomAppbar(
          title: 'Care Team Invitations',
        ),
        child: BlocBuilder<CareTeamInvitationsCubit, CareTeamInvitationsState>(
          builder: (context, state) {
            if (state is CareTeamInvitationsLoading) {
              return const LoadingComponent();
            }

            if (state is CareTeamInvitationsError) {
              return ErrorComponent(
                showButton: true,
                title: "Error",
                description: state.message,
                onActionButtonClick: () {
                  context.read<CareTeamInvitationsCubit>().fetchInvitationsForUser(currentUser.userId!);
                },
              );
            }

            if (state is CareTeamInvitationsSuccess) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pending Invitations Section
                    if (state.invitations.where((i) => i.status == InvitationStatus.pending && i.inviteeId == currentUser.userId).isNotEmpty) ...[
                      _buildSectionTitle('Pending Invitations'),
                      10.height,
                      ...state.invitations
                          .where((i) => i.status == InvitationStatus.pending && i.inviteeId == currentUser.userId)
                          .map((invitation) => _buildInvitationCard(context, invitation, currentUser.userId!)),
                      20.height,
                    ],

                    // Sent Invitations Section
                    if (state.invitations.where((i) => i.inviterId == currentUser.userId).isNotEmpty) ...[
                      _buildSectionTitle('Sent Invitations'),
                      10.height,
                      ...state.invitations
                          .where((i) => i.inviterId == currentUser.userId)
                          .map((invitation) => _buildSentInvitationCard(context, invitation)),
                      20.height,
                    ],

                    // Active Assignments Section
                    if (state.assignments.isNotEmpty) ...[
                      _buildSectionTitle('Active Assignments'),
                      10.height,
                      ...state.assignments
                          .map((assignment) => _buildAssignmentCard(context, assignment, currentUser.userId!)),
                      20.height,
                    ],

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showInviteUserDialog(context, currentUser.userId!),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Invite to Care Team'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return const Center(child: Text('No invitations found'));
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
    );
  }

  Widget _buildInvitationCard(BuildContext context, CareTeamInvitationDto invitation, String currentUserId) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BoxContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(invitation.inviter?.avatar ?? 'https://via.placeholder.com/40'),
                    radius: 20,
                  ),
                  10.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invitation.inviter?.name ?? 'Unknown User',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          invitation.invitationType == InvitationType.care_team_member 
                              ? 'Wants to add you to their care team'
                              : 'Wants you to be their case manager',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.gray2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (invitation.message != null && invitation.message!.isNotEmpty) ...[
                10.height,
                Text(
                  'Message: ${invitation.message}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gray2,
                  ),
                ),
              ],
              10.height,
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptInvitation(context, invitation.id, currentUserId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                  10.width,
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showRejectDialog(context, invitation.id, currentUserId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentInvitationCard(BuildContext context, CareTeamInvitationDto invitation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BoxContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(invitation.invitee?.avatar ?? 'https://via.placeholder.com/40'),
                radius: 20,
              ),
              10.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.invitee?.name ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      _getInvitationStatusText(invitation.status),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getInvitationStatusColor(invitation.status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(BuildContext context, CareTeamAssignmentDto assignment, String currentUserId) {
    final isCareTeamMember = assignment.careTeamMemberId == currentUserId;
    final otherUser = isCareTeamMember ? assignment.client : assignment.careTeamMember;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BoxContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(otherUser?.avatar ?? 'https://via.placeholder.com/40'),
                radius: 20,
              ),
              10.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser?.name ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      assignment.assignmentType == AssignmentType.care_team_member 
                          ? 'Care Team Member'
                          : 'Case Manager',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray2,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _terminateAssignment(context, assignment.id, currentUserId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Terminate'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInvitationStatusText(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.pending:
        return 'Pending';
      case InvitationStatus.accepted:
        return 'Accepted';
      case InvitationStatus.rejected:
        return 'Rejected';
    }
  }

  Color _getInvitationStatusColor(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.pending:
        return Colors.orange;
      case InvitationStatus.accepted:
        return Colors.green;
      case InvitationStatus.rejected:
        return Colors.red;
    }
  }

  void _acceptInvitation(BuildContext context, String invitationId, String userId) {
    context.read<CareTeamInvitationsCubit>().acceptInvitation(invitationId, userId);
  }

  void _showRejectDialog(BuildContext context, String invitationId, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final reasonController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppColors.greyDark,
          title: const Text('Reject Invitation', style: TextStyle(color: AppColors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Would you like to provide a reason for rejecting this invitation?',
                style: TextStyle(color: AppColors.white),
              ),
              10.height,
              TextField(
                controller: reasonController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  hintText: 'Reason (optional)',
                  hintStyle: TextStyle(color: AppColors.gray2),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.gray2)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<CareTeamInvitationsCubit>().rejectInvitation(
                  invitationId, 
                  userId, 
                  reason: reasonController.text.isEmpty ? null : reasonController.text,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject', style: TextStyle(color: AppColors.white)),
            ),
          ],
        );
      },
    );
  }

  void _terminateAssignment(BuildContext context, String assignmentId, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.greyDark,
          title: const Text('Terminate Assignment', style: TextStyle(color: AppColors.white)),
          content: const Text(
            'Are you sure you want to terminate this assignment?',
            style: TextStyle(color: AppColors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.gray2)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<CareTeamInvitationsCubit>().terminateAssignment(assignmentId, userId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Terminate', style: TextStyle(color: AppColors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showInviteUserDialog(BuildContext context, String currentUserId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return InviteUserDialog(currentUserId: currentUserId);
      },
    );
  }
}
