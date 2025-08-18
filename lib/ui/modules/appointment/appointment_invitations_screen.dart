import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/data/model/appointment_dto.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/ui/components/app_bar.dart';
import 'package:reentry/ui/components/container/box_container.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/modules/appointment/bloc/appointment_cubit.dart';
import 'package:reentry/ui/modules/appointment/bloc/appointment_state.dart';
import 'package:reentry/ui/modules/appointment/component/appointment_component.dart';
import 'package:reentry/ui/modules/shared/cubit_state.dart';
import '../authentication/bloc/account_cubit.dart';

class AppointmentInvitationsScreen extends StatefulWidget {
  const AppointmentInvitationsScreen({super.key});

  @override
  State<AppointmentInvitationsScreen> createState() => _AppointmentInvitationsScreenState();
}

class _AppointmentInvitationsScreenState extends State<AppointmentInvitationsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch invitations when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = context.read<AccountCubit>().state;
      if (currentUser?.userId != null) {
        context.read<AppointmentCubit>().fetchAppointmentsForResponse(currentUser!.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AccountCubit>().state;
    
    if (currentUser == null) {
      return const Center(child: Text('Please log in again.'));
    }

    return BaseScaffold(
      appBar: CustomAppbar(
        title: 'Appointment Invitations',
        onBackPress: () {
          Navigator.of(context).pop();
        },
      ),
      child: BlocBuilder<AppointmentCubit, AppointmentCubitState>(
        builder: (context, state) {
          if (state.state is CubitStateLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (state.state is CubitStateError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.red,
                    size: 64,
                  ),
                  16.height,
                  Text(
                    'Error loading invitations',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  8.height,
                  Text(
                    state.state is CubitStateError 
                        ? (state.state as CubitStateError).message 
                        : 'Unknown error occurred',
                    style: const TextStyle(
                      color: AppColors.gray2,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  24.height,
                  ElevatedButton(
                    onPressed: () {
                      context.read<AppointmentCubit>().fetchAppointmentsForResponse(currentUser.userId!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final invitations = state.invitations;
          
          if (invitations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    color: AppColors.gray2,
                    size: 64,
                  ),
                  16.height,
                  Text(
                    'No pending invitations',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  8.height,
                  Text(
                    'You don\'t have any appointment invitations waiting for your response.',
                    style: const TextStyle(
                      color: AppColors.gray2,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.mail_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    12.width,
                    Text(
                      'Appointment Invitations',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                8.height,
                Text(
                  'You have ${invitations.length} appointment${invitations.length == 1 ? '' : 's'} waiting for your response',
                  style: const TextStyle(
                    color: AppColors.gray2,
                    fontSize: 14,
                  ),
                ),
                24.height,
                
                // Invitations list
                ...invitations.map((invitation) => _buildInvitationCard(
                  context, 
                  invitation, 
                  currentUser
                )).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvitationCard(BuildContext context, NewAppointmentDto invitation, UserDto currentUser) {
    final isPending = invitation.state == EventState.pending;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.greyDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending ? AppColors.orange : AppColors.gray2,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  invitation.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? AppColors.orange : AppColors.gray2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  invitation.state.name.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          // Description
          if (invitation.description.isNotEmpty) ...[
            12.height,
            Text(
              invitation.description,
              style: const TextStyle(
                color: AppColors.gray2,
                fontSize: 14,
              ),
            ),
          ],
          
          // Date and time
          16.height,
          Row(
            children: [
              Icon(Icons.calendar_today, color: AppColors.primary, size: 16),
              8.width,
              Text(
                invitation.date.formatDate(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              16.width,
              Icon(Icons.access_time, color: AppColors.primary, size: 16),
              8.width,
              Text(
                invitation.date.beautify(withDate: false),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          // Location
          if (invitation.location != null && invitation.location!.isNotEmpty) ...[
            12.height,
            Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primary, size: 16),
                8.width,
                Text(
                  invitation.location!,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          
          // Creator info
          16.height,
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: invitation.creatorAvatar.isNotEmpty 
                    ? NetworkImage(invitation.creatorAvatar) 
                    : null,
                backgroundColor: AppColors.gray2,
                child: invitation.creatorAvatar.isEmpty 
                    ? Icon(Icons.person, color: AppColors.white, size: 20)
                    : null,
              ),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invited by',
                      style: const TextStyle(
                        color: AppColors.gray2,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      invitation.creatorName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Action buttons for pending invitations
          if (isPending) ...[
            20.height,
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AppointmentCubit>().acceptAppointment(
                        invitation.id ?? '', 
                        currentUser.userId ?? ''
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                12.width,
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showRejectDialog(context, invitation);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, NewAppointmentDto invitation) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.greyDark,
        title: const Text(
          'Decline Appointment',
          style: TextStyle(color: AppColors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you sure you want to decline this appointment?',
              style: TextStyle(color: AppColors.white),
            ),
            16.height,
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for declining (optional)',
                labelStyle: TextStyle(color: AppColors.gray2),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.gray2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              style: const TextStyle(color: AppColors.white),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.gray2),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final currentUser = context.read<AccountCubit>().state;
                if (currentUser?.userId != null) {
                  await context.read<AppointmentCubit>().rejectAppointment(
                    invitation.id!, 
                    currentUser!.userId!,
                    reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                  );
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment declined successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to decline appointment: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }
}
