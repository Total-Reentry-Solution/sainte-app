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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    label(invitation ? "Invitations" : 'Appointments'),
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
                  if (appointments.isEmpty) {
                    return Container(
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
                            'No appointments found',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          8.height,
                          Text(
                            'Create your first appointment to get started',
                            style: TextStyle(
                              color: AppColors.gray2,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return Column(
                    children: appointments.map((appointment) {
                      return InkWell(
                        onTap: () => _showAppointmentStatusDialog(context, appointment),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                                      appointment.title ?? 'No title',
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
                                      color: AppColors.gray2,
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
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                })
              ],
            )),
      ],
    );
  }
}

void _showAppointmentStatusDialog(BuildContext context, NewAppointmentDto appointment) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.greyDark,
        title: Text(
          'Update Appointment Status',
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
            20.height,
            Text(
              'What happened with this appointment?',
              style: TextStyle(color: AppColors.white, fontSize: 14),
            ),
            16.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.gray2),
            ),
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
  return ElevatedButton(
    onPressed: () async {
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    child: Text(label),
  );
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
