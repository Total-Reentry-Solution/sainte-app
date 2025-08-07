import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:reentry/core/const/app_constants.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/core/util/input_validators.dart';
import 'package:reentry/data/model/appointment_dto.dart';
import 'package:reentry/ui/components/app_bar.dart';
import 'package:reentry/ui/components/buttons/app_button.dart';
import 'package:reentry/ui/components/buttons/primary_button.dart';
import 'package:reentry/ui/components/container/box_container.dart';
import 'package:reentry/ui/components/date_dialog.dart';
import 'package:reentry/ui/components/input/input_field.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/dialog/alert_dialog.dart';
import 'package:reentry/ui/modules/admin/admin_stat_cubit.dart';
import 'package:reentry/ui/modules/appointment/bloc/appointment_bloc.dart';
import 'package:reentry/ui/modules/appointment/bloc/appointment_cubit.dart';
import 'package:reentry/ui/modules/appointment/select_appointment_user.dart';
import 'package:reentry/ui/modules/appointment/select_appointment_user_screen_non_client.dart';
import 'package:reentry/ui/modules/shared/success_screen.dart';
import '../../../data/enum/account_type.dart';
import '../authentication/bloc/account_cubit.dart';
import 'bloc/appointment_event.dart';
import 'bloc/appointment_state.dart';

class AppointmentUserDto {
  final String name;
  final String userId;
  final String avatar;

  const AppointmentUserDto(
      {required this.userId, required this.name, required this.avatar});
}

class CreateAppointmentScreen extends HookWidget {
  final NewAppointmentDto? appointment;
  final bool cancel;
  final bool reschedule;

  const CreateAppointmentScreen({super.key,
    this.appointment,
    this.cancel = false,
    this.reschedule = false});

  @override
  Widget build(BuildContext context) {
    final titleController = useTextEditingController(text: appointment?.title);
    final descriptionController =
    useTextEditingController(text: appointment?.description);
    final locationController =
    useTextEditingController(text: appointment?.location);
    final date = useState<DateTime?>(appointment?.date);
    final selectedTime = useState<TimeOfDay?>(
        TimeOfDay.fromDateTime(appointment?.date ?? DateTime.now()));
    final participant =
    useState<AppointmentUserDto?>(appointment?.getParticipant());
    final currentKey = GlobalKey<FormState>();
    final addToCalender = useState<bool>(true);
    final showLocationInput = useState<bool>(false);
    final creator = context
        .watch<AccountCubit>()
        .state;
    if (creator == null) {
      return const SizedBox();
    }
    return BlocProvider(
      create: (context) => AppointmentBloc(),
      child: BlocConsumer<AppointmentBloc, AppointmentState>(builder: (context,
          state,) {
        var isCanceled = (appointment?.status ==AppointmentStatus.canceled);
        var isPassed = appointment!=null&&((appointment?.date.difference(DateTime.now()).inHours??0)<0);
        
        return Container(
          constraints:
          BoxConstraints(maxHeight: reschedule ? 500 : double.infinity),
          child: BaseScaffold(
              appBar: CustomAppbar(
                title: 'Appointments',
                onBackPress: () {
                  context.popBack();
                },
              ),
              child: Scrollbar(
                thumbVisibility: true,
                  thickness: 8,
                  child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                    key: currentKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        20.height,
                        // Appointment Title
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.white, width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextFormField(
                            controller: titleController,
                            style: const TextStyle(color: AppColors.white, fontSize: 16),
                            decoration: const InputDecoration(
                              labelText: 'Appointment title',
                              labelStyle: TextStyle(color: AppColors.white),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            validator: InputValidators.stringValidation,
                          ),
                        ),
                        15.height,
                        // Appointment Description
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.white, width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextFormField(
                            controller: descriptionController,
                            style: const TextStyle(color: AppColors.white, fontSize: 16),
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Appointment descriptions',
                              labelStyle: TextStyle(color: AppColors.white),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            validator: InputValidators.stringValidation,
                          ),
                        ),
                        30.height,
                        // Appointment Information Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.greyDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date & Time
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, color: AppColors.white, size: 20),
                                  10.width,
                                  Text(
                                    'Date & Time',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              8.height,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      if(appointment!=null&& (appointment?.status != AppointmentStatus.upcoming && !isPassed)){
                                        return;
                                      }
                                      if(kIsWeb){
                                        final result = await showDatePicker(
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime.now().add(Duration(days: 365*50)),
                                            onDatePickerModeChange: (value) {},
                                            context: context);
                                        date.value = result;
                                        return;
                                      }
                                      context.displayDialog(DateTimeDialog(
                                          dob: false,
                                          firstDate: DateTime.now(),
                                          initialDate: DateTime.now(),
                                          lastDate: DateTime.now().add(Duration(days: 365*50)),
                                          onSelect: (result) {
                                            date.value = result;
                                          }));
                                    },
                                    child: Text(
                                      date.value?.formatDate() ?? 'Select date',
                                      style: const TextStyle(color: AppColors.white, fontSize: 14),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      if(appointment!=null&& ( appointment?.status != AppointmentStatus.upcoming && !isPassed)){
                                        return;
                                      }
                                      final result = await context
                                          .displayDialog(AppTimePicker());
                                      final data = result as TimeOfDay?;
                                      if (data != null) {
                                        selectedTime.value = data;
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.greyDark,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        selectedTime.value?.format(context) ?? 'Select time',
                                        style: const TextStyle(color: AppColors.white, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              20.height,
                              // Location
                              Row(
                                children: [
                                  Icon(Icons.add_location_alt_outlined, color: AppColors.white, size: 20),
                                  10.width,
                                  Text(
                                    'Location',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              8.height,
                              if (showLocationInput.value) ...[
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.white, width: 1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextFormField(
                                    controller: locationController,
                                    style: const TextStyle(color: AppColors.white, fontSize: 16),
                                    decoration: const InputDecoration(
                                      labelText: 'Enter appointment location',
                                      labelStyle: TextStyle(color: AppColors.white),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    onFieldSubmitted: (value) {
                                      showLocationInput.value = false;
                                    },
                                  ),
                                ),
                                8.height,
                              ] else ...[
                                InkWell(
                                  onTap: () {
                                    showLocationInput.value = true;
                                  },
                                  child: Text(
                                    locationController.text.isNotEmpty ? locationController.text : 'Enter appointment location',
                                    style: const TextStyle(color: AppColors.white, fontSize: 14),
                                  ),
                                ),
                              ],
                              20.height,
                              // Participants
                              Row(
                                children: [
                                  Icon(Icons.person_add_alt_outlined, color: AppColors.white, size: 20),
                                  10.width,
                                  Text(
                                    'Participants',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              8.height,
                              InkWell(
                                onTap: () async {
                                  if(appointment!=null&& (appointment?.status != AppointmentStatus.upcoming && !isPassed)){
                                    return;
                                  }
                                  Widget? route;
                                  if (creator.accountType != AccountType.citizen) {
                                    route = SelectAppointmentUserScreenNonClient(onselect: (data){
                                      participant.value = data;
                                    },);
                                  } else {
                                    route = SelectAppointmentUserScreenClient(onselect: (data){
                                      participant.value = data;
                                    },);
                                  }
                                  dynamic result;
                                  if (kIsWeb) {
                                    result = context.displayDialog(route as Widget);
                                  } else {
                                    result = await context.pushRoute(route as Widget);
                                  }

                                  final data = result as AppointmentUserDto?;
                                  if(data!=null){
                                    return;
                                  }
                                  participant.value = data;
                                },
                                child: Text(
                                  participant.value?.name ?? 'Add participants',
                                  style: const TextStyle(color: AppColors.white, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        20.height,
                        // Calendar Integration
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Add event to your calender',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Switch(
                              value: addToCalender.value,
                              activeColor: AppColors.white,
                              activeTrackColor: AppColors.primary,
                              onChanged: (checked) {
                                addToCalender.value = checked;
                              },
                            ),
                          ],
                        ),
                        10.height,
                        const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.gray2,
                        ),
                        10.height,
                        Text(
                          isCanceled ? 'Appointment has been canceled' : 'Participants will be informed of your appointment',
                          style: const TextStyle(color: AppColors.gray2, fontSize: 14),
                        ),
                        50.height,
                        // Create Appointment Button
                        if (appointment==null||(appointment?.status == AppointmentStatus.upcoming && !isPassed))
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: state is AppointmentLoading ? null : () async {
                                if(!currentKey.currentState!.validate()){
                                  return;
                                }
                                if (date.value == null ) {
                                  context.showSnackbarError('Please select a date');
                                  return;
                                }
                                if (selectedTime.value == null) {
                                  context.showSnackbarError('Please select a time');
                                  return;
                                }
                                if (titleController.text.trim().isEmpty) {
                                  context.showSnackbarError('Please enter an appointment title');
                                  return;
                                }
                                if (descriptionController.text.trim().isEmpty) {
                                  context.showSnackbarError('Please enter an appointment description');
                                  return;
                                }
                                
                                final resultDate = date.value?.copyWith(
                                    hour: selectedTime.value!.hour,
                                    minute: selectedTime.value!.minute);
                                if (resultDate == null) {
                                  return;
                                }
                                // Handle manual entry participants differently
                                final isManualEntry = participant.value?.userId.startsWith('manual_') ?? false;
                                
                                final data = NewAppointmentDto(
                                    title: titleController.text,
                                    id: appointment?.id,
                                    description: descriptionController.text,
                                    date: resultDate,
                                    orgs: creator.organizations,
                                    creatorAvatar:
                                    creator.avatar ?? AppConstants.avatar,
                                    creatorName: creator.name,
                                    participantAvatar: participant.value?.avatar,
                                    // For manual entries, don't set participantId (let it be null)
                                    // For mentors, use their actual userId
                                    participantId: isManualEntry ? null : participant.value?.userId,
                                    participantName: participant.value?.name,
                                    status: AppointmentStatus.upcoming,
                                    location: locationController.text.isEmpty
                                        ? null
                                        : locationController.text,
                                    creatorId: creator.userId ?? '',
                                    state: participant.value == null
                                        ? EventState.scheduled
                                        : EventState.pending);
                                if (appointment != null) {
                                  context
                                      .read<AppointmentBloc>()
                                      .add(UpdateAppointmentEvent(data));
                                  return;
                                }
                                context
                                    .read<AppointmentBloc>()
                                    .add(CreateAppointmentEvent(data));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                foregroundColor: AppColors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: state is AppointmentLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                                      ),
                                    )
                                  : Text(
                                      appointment != null ? 'Save' : 'Create appointment',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        50.height,
                      ],
                    )),
              ))),
        );
      }, listener: (_, state) async {
        if (state is AppointmentSuccess) {
          if (kIsWeb) {
            context.showSnackbarSuccess("Appointment created successfully");
            context.pop();
          } else {
            context.read<AdminStatCubit>().updateAppointment();
            context.pushReplace(SuccessScreen(
              callback: () {},
              title: 'Appointment created successfully',
              description: 'Your appointment have been created successfully',
            ));

            final resultDate = date.value?.copyWith(
                hour: selectedTime.value!.hour,
                minute: selectedTime.value!.minute);
            if (resultDate == null) {
              return;
            }
            if (addToCalender.value) {
              // await createGoogleCalendarEvent(
              //     titleController.text,
              //     descriptionController.text,
              //     locationController.text,
              //     resultDate);
            }
          }
          return;
        }
        if (state is UpdateAppointmentSuccess) {
          if (kIsWeb) {
            context.showSnackbarSuccess("Appointment updated successfully");
            Navigator.pop(context);
          } else {
            context.pushReplace(SuccessScreen(
              callback: () {},
              title: 'Appointment updated successfully',
              description: 'Your appointment have been updated successfully',
            ));
          }
          return;
        }
        if (state is CancelAppointmentSuccess) {
          if (kIsWeb) {
            // context.read<AppointmentCubit>().fetchAppointments();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Appointment canceled successfully"),
                backgroundColor: AppColors.green,
              ),
            );
            Navigator.pop(context);
          } else {
            context.pushReplace(SuccessScreen(
              callback: () {},
              title: 'Appointment canceled successfully',
              description: 'Your appointment have been canceled successfully',
            ));
          }
          return;
        }
        if (state is AppointmentError) {
          context.showSnackbarError(state.message);
        }
      }),
    );
  }
}