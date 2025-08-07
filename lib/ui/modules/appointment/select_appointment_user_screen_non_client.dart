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
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/repository/admin/admin_repository.dart';

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
    final mentors = useState<List<UserDto>>([]);
    final caseManagers = useState<List<UserDto>>([]);
    final isLoading = useState(true);
    
    // Define the function before using it in useEffect
    Future<void> _fetchParticipants() async {
      try {
        isLoading.value = true;
        final adminRepo = AdminRepository();
        
        // Fetch mentors
        final mentorsList = await adminRepo.getUsers(AccountType.mentor);
        mentors.value = mentorsList;
        
        // Fetch case managers
        final caseManagersList = await adminRepo.getUsers(AccountType.case_manager);
        caseManagers.value = caseManagersList;
        
      } catch (e) {
        print('Error fetching participants: $e');
      } finally {
        isLoading.value = false;
      }
    }
    
    // Fetch mentors and case managers on init
    useEffect(() {
      _fetchParticipants();
      return null;
    }, []);
    
    return BaseScaffold(
        appBar:  CustomAppbar(
          title: 'Select participant',
          onBackPress: (){
            context.popBack();
          },
        ),
        child: Column(
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
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                                color: !isManualEntry.value ? AppColors.primary : AppColors.white,
                                width: 1,
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
                                color: isManualEntry.value ? AppColors.primary : AppColors.white,
                                width: 1,
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
                : _buildMentorSelectionList(context, mentors.value, caseManagers.value, selectedUser, isLoading.value),
            ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: selectedUser.value != null ? () {
                  if (selectedUser.value == null) {
                    return;
                  }
                  onselect?.call(selectedUser.value!);
                  context.popRoute(
                    result: selectedUser.value!,
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            20.height,
          ],
        ));
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
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          15.height,
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.white, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
              controller: nameController,
              style: const TextStyle(color: AppColors.white, fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: AppColors.white),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: InputValidators.stringValidation,
              onChanged: (value) {
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
          ),
          15.height,
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.white, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
              controller: emailController,
              style: const TextStyle(color: AppColors.white, fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: AppColors.white),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: InputValidators.emailValidation,
              onChanged: (value) {
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
          ),
          20.height,
          
          // Selected participant display
          if (selectedUser.value != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.greyDark,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.gray2,
                    child: Icon(Icons.person, color: AppColors.white, size: 24),
                  ),
                  15.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedUser.value!.name,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Manual entry',
                          style: TextStyle(
                            color: AppColors.gray2,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.black,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMentorSelectionList(
    BuildContext context, 
    List<UserDto> mentors,
    List<UserDto> caseManagers,
    ValueNotifier<AppointmentUserDto?> selectedUser,
    bool isLoading
  ) {
    if (isLoading) {
      return const LoadingComponent();
    }
    
    final allParticipants = [...mentors, ...caseManagers];
    
    if (allParticipants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.gray2,
            ),
            16.height,
            Text(
              'Ooops!! Nothing here',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            8.height,
            Text(
              'Unfortunately there is no one to book appointment with',
              style: TextStyle(
                color: AppColors.gray2,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            20.height,
            Text(
              'Try sending a mentor request',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: allParticipants.length,
      itemBuilder: (context, index) {
        final participant = allParticipants[index];
        final isSelected = selectedUser.value?.userId == participant.userId;
        final isMentor = participant.accountType == AccountType.mentor;
        final isCaseManager = participant.accountType == AccountType.case_manager;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.greyDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.gray2,
              backgroundImage: participant.avatar != null ? NetworkImage(participant.avatar!) : null,
              child: participant.avatar == null 
                ? Icon(Icons.person, color: AppColors.white, size: 24)
                : null,
            ),
            title: Text(
              participant.name ?? 'Unknown User',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.email ?? '',
                  style: TextStyle(
                    color: AppColors.gray2,
                    fontSize: 14,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isMentor ? AppColors.primary : Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isMentor ? 'Peer Mentor' : 'Case Manager',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            trailing: isSelected
                ? Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.black,
                      size: 16,
                    ),
                  )
                : null,
            onTap: () {
              selectedUser.value = AppointmentUserDto(
                userId: participant.userId ?? '',
                name: participant.name ?? 'Unknown User',
                avatar: participant.avatar ?? AppConstants.avatar,
              );
            },
          ),
        );
      },
    );
  }
}
