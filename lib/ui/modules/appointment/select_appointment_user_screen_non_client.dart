import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/ui/components/app_bar.dart';
import 'package:reentry/ui/components/buttons/primary_button.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/components/user_info_component.dart';
import 'package:reentry/ui/modules/appointment/create_appointment_screen.dart';
import 'package:reentry/ui/modules/clients/bloc/client_cubit.dart';
import 'package:reentry/core/resources/data_state.dart';
import 'package:reentry/ui/components/error_component.dart';
import 'package:reentry/ui/components/loading_component.dart';
import 'package:reentry/ui/modules/clients/bloc/client_state.dart';
import 'package:reentry/data/model/appointment_dto.dart';
import 'package:reentry/ui/components/input/input_field.dart';
import 'package:reentry/core/util/input_validators.dart';
import 'package:reentry/core/const/app_constants.dart';

class SelectAppointmentUserScreenNonClient extends HookWidget {
  const SelectAppointmentUserScreenNonClient({super.key,this.onselect});

  final void Function (AppointmentUserDto)? onselect;
  @override
  Widget build(BuildContext context) {
    final selectedUser = useState<AppointmentUserDto?>(null);
    final isManualEntry = useState(false);
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final formKey = GlobalKey<FormState>();
    
    return BlocProvider(
      create: (context) => ClientCubit()..fetchClients(),
      child: BaseScaffold(
          appBar:  CustomAppbar(
            title: 'Select participant',
            onBackPress: (){
              context.popBack();
            },
          ),
          child:
              BlocBuilder<ClientCubit, ClientState>(builder: (context, state) {
            if (state is ClientLoading) {
              return const LoadingComponent();
            }
            if (state is ClientDataSuccess) {
              return HookBuilder(builder: (context) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    20.height,
                    
                    // Toggle between selection modes
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.greyDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select participant type',
                            style: context.textTheme.titleSmall?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          15.height,
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => isManualEntry.value = false,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: !isManualEntry.value ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: !isManualEntry.value ? AppColors.primary : AppColors.inputBorderColor,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Select from mentors',
                                        style: TextStyle(
                                          color: !isManualEntry.value ? AppColors.black : AppColors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              10.width,
                              Expanded(
                                child: InkWell(
                                  onTap: () => isManualEntry.value = true,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: isManualEntry.value ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isManualEntry.value ? AppColors.primary : AppColors.inputBorderColor,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Manual entry',
                                        style: TextStyle(
                                          color: isManualEntry.value ? AppColors.black : AppColors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    20.height,
                    
                    // Content based on selection mode
                    Expanded(
                      child: isManualEntry.value 
                        ? _buildManualEntryForm(context, nameController, emailController, formKey, selectedUser)
                        : _buildMentorSelectionList(context, state, selectedUser),
                    ),

                    PrimaryButton(
                      text: 'Continue',
                      enable: selectedUser.value != null,
                      onPress: () {
                        if (selectedUser.value == null) {
                          return;
                        }
                        onselect?.call(selectedUser.value!);
                        context.popRoute(
                          result: selectedUser.value!,
                        );
                      },
                    ),
                    20.height,
                  ],
                );
              });
            }
            return ErrorComponent(
              title: "Something went wrong!",
              description: "Unable to fetch data please retry",
              onActionButtonClick: () {
                context.read<ClientCubit>().fetchClients();
              },
            );
          })),
    );
  }

  Widget _buildManualEntryForm(
    BuildContext context, 
    TextEditingController nameController, 
    TextEditingController emailController, 
    GlobalKey<FormState> formKey,
    ValueNotifier<AppointmentUserDto?> selectedUser
  ) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter participant details',
            style: context.textTheme.titleSmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          15.height,
          InputField(
            hint: 'Enter participant name',
            label: 'Name',
            controller: nameController,
            validator: InputValidators.stringValidation,
            onChange: (value) {
              // Create a temporary user DTO for manual entry
              if (value.isNotEmpty && emailController.text.isNotEmpty) {
                selectedUser.value = AppointmentUserDto(
                  userId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                  name: value,
                  avatar: AppConstants.avatar,
                );
              } else {
                selectedUser.value = null;
              }
            },
          ),
          15.height,
          InputField(
            hint: 'Enter participant email',
            label: 'Email',
            controller: emailController,
            validator: InputValidators.emailValidation,
            onChange: (value) {
              // Create a temporary user DTO for manual entry
              if (value.isNotEmpty && nameController.text.isNotEmpty) {
                selectedUser.value = AppointmentUserDto(
                  userId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  avatar: AppConstants.avatar,
                );
              } else {
                selectedUser.value = null;
              }
            },
          ),
          20.height,
          if (selectedUser.value != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                children: [
                  UserInfoComponent(
                    name: selectedUser.value!.name,
                    url: selectedUser.value!.avatar,
                    size: 40,
                  ),
                  15.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedUser.value!.name,
                          style: context.textTheme.titleSmall?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Manual entry',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: AppColors.gray2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMentorSelectionList(
    BuildContext context, 
    ClientDataSuccess state, 
    ValueNotifier<AppointmentUserDto?> selectedUser
  ) {
    if (state.data.isEmpty) {
      return const ErrorComponent(
        showButton: false,
        title: "Ooops!! Nothing here",
        description: "Unfortunately there is no one to book appointment with",
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select from available mentors',
          style: context.textTheme.titleSmall?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        15.height,
        Expanded(
          child: ListView.builder(
            itemCount: state.data.length,
            itemBuilder: (context, index) {
              final item = state.data[index];
              return selectableUserContainer(
                name: item.name,
                url: item.avatar,
                selected: selectedUser.value?.userId == item.id,
                onTap: () {
                  selectedUser.value = item.toAppointmentUserDto();
                },
              );
            },
          ),
        ),
      ],
    );
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
