import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:reentry/core/const/app_constants.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/data/model/appointment_dto.dart';
import 'package:reentry/ui/components/add_button.dart';
import 'package:reentry/ui/components/error_component.dart';
import 'package:reentry/ui/components/loading_component.dart';
import 'package:reentry/ui/modules/appointment/bloc/appointment_cubit.dart';
import 'package:reentry/ui/modules/shared/cubit_state.dart';
import '../../../../core/theme/colors.dart';
import '../../../components/container/box_container.dart';
import '../../authentication/bloc/account_cubit.dart';
import '../bloc/appointment_state.dart';
import '../create_appointment_screen.dart';
import '../view_single_appointment_screen.dart';

class AppointmentComponent extends HookWidget {
  final bool showAll;
  final bool invitation;
  final bool showCreate;

  const AppointmentComponent(
      {super.key,
      this.showAll = true,
      this.invitation = false,
      this.showCreate = true});

  @override
  Widget build(BuildContext context) {
    final accountCubit = context.watch<AccountCubit>().state;
    if (accountCubit == null) {
      return const Center(child: Text('Please log in again.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        BoxContainer(
            verticalPadding: 10,
            horizontalPadding: 10,
            filled: false,
            constraints:
                const BoxConstraints(minHeight: 150, minWidth: double.infinity),
            radius: 10,
            child: Column(
              children: [
                BlocBuilder<AppointmentCubit, AppointmentCubitState>(
                    builder: (context, state) {
                  if (state.state is CubitStateLoading) {
                    return const LoadingComponent();
                  }
                  
                  if (state.state is CubitStateError) {
                    return ErrorComponent(
                      showButton: true,
                      onActionButtonClick: () {
                        context.read<AppointmentCubit>().fetchAppointments();
                      },
                    );
                  }
                  final appointments = state.data;
                  
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          label(invitation ? "Invitations" : 'Upcoming Appointments (${appointments.length})'),
                          if (showCreate)
                            AddButton(onTap: () {
                              if (kIsWeb) {
                                context.displayDialog(const CreateAppointmentScreen());
                              } else {
                                context.pushRoute(const CreateAppointmentScreen());
                              }
                            })
                        ],
                      ),
                      5.height,
                      
                      if (appointments.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 48,
                                color: AppColors.gray2,
                              ),
                              16.height,
                              Text(
                                'No upcoming appointments',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              8.height,
                              Text(
                                'You have no upcoming appointments. Create a new one to get started!',
                                style: TextStyle(
                                  color: AppColors.gray2,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Separate pending requests from confirmed appointments
                        _buildAppointmentsList(context, appointments),
                      ],
                    ],
                  );
                })
              ],
            )),
      ],
    );
  }

  Widget _buildAppointmentsList(BuildContext context, List<NewAppointmentDto> appointments) {
    // Separate pending requests from confirmed appointments
    final pendingRequests = appointments.where((a) => a.state == EventState.pending).toList();
    final confirmedAppointments = appointments.where((a) => a.state != EventState.pending).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show pending requests first
        if (pendingRequests.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.pending_actions, color: AppColors.primary, size: 20),
                8.width,
                Text(
                  'Appointment Requests (${pendingRequests.length})',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...pendingRequests.map((appointment) => _buildAppointmentCard(context, appointment, true)),
          const SizedBox(height: 20),
        ],
        
        // Show confirmed appointments
        if (confirmedAppointments.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.green, size: 20),
                8.width,
                Text(
                  'Confirmed Appointments (${confirmedAppointments.length})',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...confirmedAppointments.map((appointment) => _buildAppointmentCard(context, appointment, false)),
        ],
      ],
    );
  }

  Widget _buildAppointmentCard(BuildContext context, NewAppointmentDto appointment, bool isPendingRequest) {
    final currentUser = context.read<AccountCubit>().state;
    final isParticipant = currentUser?.userId == appointment.participantId;
    
    return InkWell(
      onTap: () => _showAppointmentStatusDialog(context, appointment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.greyDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPendingRequest ? AppColors.primary.withOpacity(0.5) : AppColors.gray2.withOpacity(0.3),
            width: isPendingRequest ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    appointment.title ?? 'No title',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isPendingRequest) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PENDING',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment.status?.name.toUpperCase() ?? 'UNKNOWN',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            8.height,
            if (appointment.location != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: AppColors.gray2, size: 16),
                  8.width,
                  Expanded(
                    child: Text(
                      appointment.location!,
                      style: const TextStyle(
                        color: AppColors.gray2,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              8.height,
            ],
            Row(
              children: [
                Icon(Icons.person_outline, color: AppColors.gray2, size: 16),
                8.width,
                Text(
                  appointment.participantName ?? 'No participant',
                  style: const TextStyle(
                    color: AppColors.gray2,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            8.height,
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, color: AppColors.gray2, size:16),
                8.width,
                Text(
                  appointment.date?.formatDate() ?? 'No date',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                ),
                16.width,
                Text(
                  appointment.date?.beautify(withDate: false) ?? 'No time',
                  style: const TextStyle(
                    color: AppColors.gray2,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            // Show accept/reject buttons for pending requests if user is the participant
            if (isPendingRequest && isParticipant) ...[
              16.height,
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AppointmentCubit>().acceptAppointment(appointment.id ?? '', currentUser?.userId ?? '');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                  8.width,
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _showRejectDialog(context, appointment);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, NewAppointmentDto appointment) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.greyDark,
          title: const Text(
            'Decline Appointment',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please provide a reason for declining:',
                style: TextStyle(color: AppColors.white, fontSize: 14),
              ),
              16.height,
              TextField(
                controller: reasonController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  hintText: 'Reason for declining...',
                  hintStyle: TextStyle(color: AppColors.gray2),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.gray2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
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
              onPressed: () {
                final currentUser = context.read<AccountCubit>().state;
                if (currentUser != null) {
                  context.read<AppointmentCubit>().rejectAppointment(
                    appointment.id ?? '', 
                    currentUser.userId ?? '',
                    reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Decline'),
            ),
          ],
        );
      },
    );
  }

  void _showAppointmentStatusDialog(BuildContext context, NewAppointmentDto appointment) {
    final currentUser = context.read<AccountCubit>().state;
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.greyDark,
          title: Text(
            'Appointment Details',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${appointment.title}',
                style: TextStyle(color: AppColors.white, fontSize: 16),
              ),
              16.height,
              Text(
                '${appointment.date?.formatDate()} at ${appointment.date?.beautify(withDate: false)}',
                style: TextStyle(color: AppColors.gray2, fontSize: 14),
              ),
              8.height,
              if (appointment.location != null) ...[
                Text(
                  'Location: ${appointment.location}',
                  style: TextStyle(color: AppColors.gray2, fontSize: 14),
                ),
                8.height,
              ],
              Text(
                'With: ${appointment.participantName ?? 'No participant'}',
                style: TextStyle(color: AppColors.gray2, fontSize: 14),
              ),
              20.height,
              // Show accept/reject buttons if appointment is pending and user is the participant
              if (appointment.state == EventState.pending && 
                  appointment.participantId == currentUser.userId) ...[
                Text(
                  'This appointment is waiting for your response',
                  style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                16.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await context.read<AppointmentCubit>().acceptAppointment(appointment.id!, currentUser.userId!);
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Appointment accepted successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to accept appointment: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: AppColors.white,
                      ),
                      child: Text('Accept'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Show reason dialog for rejection
                        final reason = await _showRejectionReasonDialog(context);
                        if (reason != null) {
                          try {
                            await context.read<AppointmentCubit>().rejectAppointment(appointment.id!, currentUser.userId!, reason: reason);
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Appointment rejected'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          } catch (e) {
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to reject appointment: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: AppColors.white,
                      ),
                      child: Text('Reject'),
                    ),
                  ],
                ),
              ] else if (appointment.state == EventState.pending) ...[
                Text(
                  'This appointment is pending approval',
                  style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ] else ...[
                Text(
                  'What happened with this appointment?',
                  style: TextStyle(color: AppColors.white, fontSize: 14),
                ),
                16.height,
                // Use Wrap instead of Row to prevent overflow
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildStatusButton(
                      context,
                      'Attended',
                      Colors.green,
                      AppointmentStatus.done,
                      appointment,
                    ),
                    _buildStatusButton(
                      context,
                      'Missed',
                      Colors.orange,
                      AppointmentStatus.missed,
                      appointment,
                    ),
                    _buildStatusButton(
                      context,
                      'Canceled',
                      Colors.red,
                      AppointmentStatus.canceled,
                      appointment,
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: AppColors.gray2),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showRejectionReasonDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.greyDark,
          title: Text(
            'Rejection Reason',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: reasonController,
            style: TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              hintText: 'Enter reason for rejection (optional)',
              hintStyle: TextStyle(color: AppColors.gray2),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: AppColors.gray2)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(reasonController.text.isEmpty ? null : reasonController.text),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Reject', style: TextStyle(color: AppColors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    String label,
    Color color,
    AppointmentStatus status,
    NewAppointmentDto appointment,
  ) {
    return SizedBox(
      width: 80, // Fixed width to prevent overflow
      child: ElevatedButton(
        onPressed: () async {
          if (appointment.id == null || appointment.id!.isEmpty) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot update appointment: Invalid appointment ID'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          
          try {
            await context.read<AppointmentCubit>().updateAppointmentStatus(status, appointment.id!);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Appointment status updated to $label'),
                backgroundColor: color,
              ),
            );
          } catch (e) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update appointment status: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          minimumSize: Size(80, 36),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus? status) {
    switch (status) {
      case AppointmentStatus.upcoming:
        return AppColors.primary;
      case AppointmentStatus.canceled:
        return Colors.red;
      case AppointmentStatus.done:
        return Colors.green;
      default:
        return AppColors.gray2;
    }
  }
}

Widget label(String text) {
  return Builder(builder: (context) {
    final textTheme = context.textTheme;
    return Text(
      text,
      style: textTheme.titleSmall,
    );
  });
}

Widget appointmentComponent(NewAppointmentDto entity, bool createdByMe,
    {bool invitation = false}) {
  return Builder(builder: (context) {
    final theme = context.textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greyDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gray2.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  entity.title ?? 'No title',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(entity.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entity.status?.name.toUpperCase() ?? 'UNKNOWN',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          8.height,
          if (entity.location != null) ...[
            Row(
              children: [
                Icon(Icons.location_on_outlined, color: AppColors.gray2, size: 16),
                8.width,
                Expanded(
                  child: Text(
                    entity.location!,
                    style: const TextStyle(
                      color: AppColors.gray2,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            8.height,
          ],
          Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.gray2, size: 16),
              8.width,
              Text(
                entity.participantName ?? 'No participant',
                style: const TextStyle(
                  color: AppColors.gray2,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          8.height,
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: AppColors.gray2, size: 16),
              8.width,
              Text(
                entity.date?.formatDate() ?? 'No date',
                style: const TextStyle(
                  color: AppColors.gray2,
                  fontSize: 14,
                ),
              ),
              16.width,
              Text(
                entity.date?.beautify(withDate: false) ?? 'No time',
                style: const TextStyle(
                  color: AppColors.gray2,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  });
}

Color _getStatusColor(AppointmentStatus? status) {
  switch (status) {
    case AppointmentStatus.upcoming:
      return AppColors.primary;
    case AppointmentStatus.canceled:
      return Colors.red;
    case AppointmentStatus.done:
      return Colors.green;
    default:
      return AppColors.gray2;
  }
}
