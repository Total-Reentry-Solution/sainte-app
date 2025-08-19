import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/ui/components/app_bar.dart';
import 'package:reentry/ui/components/buttons/primary_button.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/modules/appointment/create_appointment_screen.dart';
import 'package:reentry/ui/components/input/input_field.dart';
import 'package:reentry/core/util/input_validators.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/data/repository/appointment/appointment_repository.dart';
import 'package:reentry/data/repository/messaging/messaging_repository.dart';

import 'package:reentry/data/repository/user/user_repository.dart';
import 'package:reentry/data/repository/care_team/care_team_repository.dart';
import 'package:reentry/data/shared/share_preference.dart';

class SelectAppointmentUserScreenNonClient extends HookWidget {
  const SelectAppointmentUserScreenNonClient({super.key,this.onselect});

  final void Function (AppointmentUserDto)? onselect;
  @override
  Widget build(BuildContext context) {
    final selectedUser = useState<AppointmentUserDto?>(null);
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final searchController = useTextEditingController();
    final formKey = GlobalKey<FormState>();
    final searchResults = useState<List<UserDto>>([]);
    final contactHistory = useState<List<ContactHistoryItem>>([]);
    final assignedClients = useState<List<UserDto>>([]);
    final selectedTab = useState(0); // 0: Assigned Clients, 1: History, 2: Manual Entry
    
         // Define the function before using it in useEffect
     Future<void> fetchAssignedClients() async {
      try {
        final currentUser = await PersistentStorage.getCurrentUser();
        if (currentUser == null) return;
        
        final careTeamRepo = CareTeamRepository();
        
        // Get active assignments for this care team member
        final assignments = await careTeamRepo.getActiveAssignmentsForCareTeamMember(currentUser.userId!);
        
        // Extract client IDs from assignments
        final clientIds = assignments.map((a) => a.clientId).toSet();
        final userRepo = UserRepository();
        final clients = await userRepo.getUsersByIds(clientIds.toList());
        
        assignedClients.value = clients;
      } catch (e) {
        print('Error fetching assigned clients: $e');
        assignedClients.value = [];
      }
    }

         Future<void> fetchContactHistory() async {
      try {
        final currentUser = await PersistentStorage.getCurrentUser();
        if (currentUser == null) return;
        
        final appointmentRepo = AppointmentRepository();
        final messagingRepo = MessageRepository();
        
        // Get appointments history
        final appointments = await appointmentRepo.getAppointments(userId: currentUser.userId);
        final appointmentContacts = appointments
            .where((appointment) => appointment.participantId != null)
            .map((appointment) => ContactHistoryItem(
              userId: appointment.participantId!,
              name: appointment.participantName ?? 'Unknown',
              avatar: appointment.participantAvatar ?? '',
              type: ContactType.appointment,
              lastContact: appointment.date,
            ))
            .toList();
        
        // Get messaging history
        final messages = await messagingRepo.getMessages();
        final messageContacts = <ContactHistoryItem>[];
        
        for (final message in messages) {
          if (message.receiverId != currentUser.userId && message.receiverId != null) {
            // Get user profile for the receiver
            UserDto? receiverUser;
            try {
              receiverUser = await UserRepository().getUserById(message.receiverId!);
            } catch (e) {
              print('Error fetching user info for ${message.receiverId}: $e');
            }
            
            messageContacts.add(ContactHistoryItem(
              userId: message.receiverId!,
              name: receiverUser?.name ?? 'Unknown User',
              avatar: receiverUser?.avatar ?? '',
              type: ContactType.message,
              lastContact: message.timestamp != null ? DateTime.fromMillisecondsSinceEpoch(message.timestamp!) : null,
            ));
          }
        }
        
        // Combine and deduplicate
        final allContacts = [...appointmentContacts, ...messageContacts];
        final uniqueContacts = <String, ContactHistoryItem>{};
        
        for (final contact in allContacts) {
          if (!uniqueContacts.containsKey(contact.userId)) {
            uniqueContacts[contact.userId] = contact;
          } else {
            // Keep the most recent contact
            final existing = uniqueContacts[contact.userId]!;
            if (contact.lastContact != null && (existing.lastContact == null || 
                contact.lastContact!.isAfter(existing.lastContact!))) {
              uniqueContacts[contact.userId] = contact;
            }
          }
        }
        
        contactHistory.value = uniqueContacts.values.toList();
      } catch (e) {
        print('Error fetching contact history: $e');
        contactHistory.value = [];
      }
    }

         Future<void> searchUsers(String query) async {
      if (query.isEmpty) {
        searchResults.value = [];
        return;
      }
      
      try {
        final currentUser = await PersistentStorage.getCurrentUser();
        if (currentUser == null) return;
        
        final userRepo = UserRepository();
        final results = await userRepo.searchUsers(query, excludeUserId: currentUser.userId);
        
        // Filter to only show citizens/clients for care team members
        final clientResults = results.where((user) => 
          user.accountType == AccountType.citizen
        ).toList();
        
        searchResults.value = clientResults;
      } catch (e) {
        print('Error searching users: $e');
        searchResults.value = [];
      }
    }

         // Load data on init
     useEffect(() {
       fetchAssignedClients();
       fetchContactHistory();
       return null;
     }, []);

    return BaseScaffold(
      appBar: CustomAppbar(
        title: 'Select Participant',
        onBackPress: () => Navigator.pop(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
                         InputField(
               controller: searchController,
               hint: 'Search by name or email...',
               onChange: searchUsers,
               preffixIcon: Icon(Icons.search),
             ),
            
            const SizedBox(height: 16),
            
            // Tab bar
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => selectedTab.value = 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selectedTab.value == 0 ? AppColors.primary : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Assigned Clients',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selectedTab.value == 0 ? AppColors.primary : Colors.grey.shade600,
                          fontWeight: selectedTab.value == 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => selectedTab.value = 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selectedTab.value == 1 ? AppColors.primary : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Recent Contacts',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selectedTab.value == 1 ? AppColors.primary : Colors.grey.shade600,
                          fontWeight: selectedTab.value == 1 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => selectedTab.value = 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selectedTab.value == 2 ? AppColors.primary : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Manual Entry',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selectedTab.value == 2 ? AppColors.primary : Colors.grey.shade600,
                          fontWeight: selectedTab.value == 2 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tab content
            Expanded(
              child: IndexedStack(
                index: selectedTab.value,
                children: [
                  // Assigned Clients Tab
                  _buildAssignedClientsTab(assignedClients.value, selectedUser, onselect),
                  
                  // Recent Contacts Tab
                  _buildRecentContactsTab(contactHistory.value, selectedUser, onselect),
                  
                                     // Manual Entry Tab
                   _buildManualEntryTab(
                     context,
                     formKey, 
                     nameController, 
                     emailController, 
                     selectedUser, 
                     onselect
                   ),
                ],
              ),
            ),
            
            // Search results
            if (searchResults.value.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Search Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.value.length,
                  itemBuilder: (context, index) {
                    final user = searchResults.value[index];
                    return ListTile(
                                             leading: CircleAvatar(
                         backgroundImage: NetworkImage((user.avatar?.isNotEmpty == true) ? user.avatar! : 'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png?20150327203541'),
                       ),
                      title: Text(user.name),
                                             subtitle: Text(user.email ?? ''),
                      onTap: () {
                                                 selectedUser.value = AppointmentUserDto(
                           userId: user.userId ?? '',
                           name: user.name,
                           avatar: user.avatar ?? '',
                         );
                        onselect?.call(selectedUser.value!);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedClientsTab(List<UserDto> assignedClients, ValueNotifier<AppointmentUserDto?> selectedUser, void Function(AppointmentUserDto)? onselect) {
    if (assignedClients.isEmpty) {
      return const Center(
        child: Text(
          'No clients assigned yet.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: assignedClients.length,
      itemBuilder: (context, index) {
        final client = assignedClients[index];
        return ListTile(
                     leading: CircleAvatar(
             backgroundImage: NetworkImage((client.avatar?.isNotEmpty == true) ? client.avatar! : 'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png?20150327203541'),
           ),
          title: Text(client.name),
          subtitle: Text('Client'),
          onTap: () {
                         selectedUser.value = AppointmentUserDto(
               userId: client.userId ?? '',
               name: client.name,
               avatar: client.avatar ?? '',
             );
            onselect?.call(selectedUser.value!);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildRecentContactsTab(List<ContactHistoryItem> contacts, ValueNotifier<AppointmentUserDto?> selectedUser, void Function(AppointmentUserDto)? onselect) {
    if (contacts.isEmpty) {
      return const Center(
        child: Text(
          'No recent contacts found.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(contact.avatar.isNotEmpty ? contact.avatar : 'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png?20150327203541'),
          ),
          title: Text(contact.name),
          subtitle: Text(contact.type.name.toUpperCase()),
          onTap: () {
            selectedUser.value = AppointmentUserDto(
              userId: contact.userId,
              name: contact.name,
              avatar: contact.avatar,
            );
            onselect?.call(selectedUser.value!);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildManualEntryTab(
    BuildContext context,
    GlobalKey<FormState> formKey,
    TextEditingController nameController,
    TextEditingController emailController,
    ValueNotifier<AppointmentUserDto?> selectedUser,
    void Function(AppointmentUserDto)? onselect,
  ) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputField(
            controller: nameController,
            hint: 'Full Name',
            validator: InputValidators.stringValidation,
          ),
          const SizedBox(height: 16),
          InputField(
            controller: emailController,
            hint: 'Email Address',
            validator: InputValidators.emailValidation,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: 'Create Appointment',
              onPress: () {
                if (formKey.currentState!.validate()) {
                  selectedUser.value = AppointmentUserDto(
                    userId: '', // Will be generated or looked up
                    name: nameController.text.trim(),
                    avatar: '',
                  );
                  onselect?.call(selectedUser.value!);
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum ContactType { appointment, message }

class ContactHistoryItem {
  final String userId;
  final String name;
  final String avatar;
  final ContactType type;
  final DateTime? lastContact;
  
  ContactHistoryItem({
    required this.userId,
    required this.name,
    required this.avatar,
    required this.type,
    this.lastContact,
  });
}
