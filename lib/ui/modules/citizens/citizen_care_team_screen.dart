import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/data/model/case_citizen_assignment_dto.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/ui/components/input/input_field.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';
import 'package:reentry/ui/components/container/box_container.dart';

class CitizenCareTeamScreen extends StatefulWidget {
  const CitizenCareTeamScreen({super.key});

  @override
  State<CitizenCareTeamScreen> createState() => _CitizenCareTeamScreenState();
}

class _CitizenCareTeamScreenState extends State<CitizenCareTeamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _responseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      child: BlocBuilder<AccountCubit, UserDto?>(
        builder: (context, account) {
          if (account == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.greyDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.white,
                  unselectedLabelColor: AppColors.grey1,
                  indicatorColor: AppColors.primary,
                                     tabs: const [
                     Tab(text: 'Accepted'),
                     Tab(text: 'Pending'),
                     Tab(text: 'Rejected'),
                   ],
                ),
              ),
              20.height,
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                                     children: [
                     _buildAcceptedTab(account),
                     _buildPendingTab(account),
                     _buildRejectedTab(account),
                   ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPendingTab(UserDto account) {
    // TODO: Replace with actual data from CaseCitizenAssignmentRepository
    final mockAssignments = [
      _createMockAssignment(
        id: '1',
        caseManagerId: 'cm-1',
        citizenId: account.userId ?? '',
        assignmentStatus: CaseCitizenAssignmentRequestStatus.pending,
        requestMessage: 'I would like to work with you on your case. I have experience in reentry support and can help you achieve your goals.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        caseManager: _createMockUser('John Smith', 'Case Manager', 'john.smith@reentry.org'),
      ),
      _createMockAssignment(
        id: '2',
        caseManagerId: 'cm-2',
        citizenId: account.userId ?? '',
        assignmentStatus: CaseCitizenAssignmentRequestStatus.pending,
        requestMessage: 'I specialize in employment assistance and housing support. Let\'s work together to build a successful reentry plan.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        caseManager: _createMockUser('Sarah Johnson', 'Peer Mentor', 'sarah.j@reentry.org'),
      ),
    ];

    if (mockAssignments.isEmpty) {
             return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             const Icon(Icons.inbox_outlined, size: 64, color: AppColors.grey1),
             16.height,
            Text(
              'No pending requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
            ),
            8.height,
            Text(
              'You don\'t have any pending assignment requests.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: mockAssignments.length,
      itemBuilder: (context, index) {
        final assignment = mockAssignments[index];
        return _buildAssignmentCard(assignment, true);
      },
    );
  }

  Widget _buildAcceptedTab(UserDto account) {
    // TODO: Replace with actual data from CaseCitizenAssignmentRepository
    final mockAssignments = [
      _createMockAssignment(
        id: '3',
        caseManagerId: 'cm-3',
        citizenId: account.userId ?? '',
        assignmentStatus: CaseCitizenAssignmentRequestStatus.accepted,
        requestMessage: 'I\'m excited to work with you on your reentry journey.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        respondedAt: DateTime.now().subtract(const Duration(days: 3)),
        responseMessage: 'Thank you! I\'m looking forward to working together.',
        caseManager: _createMockUser('Mike Wilson', 'Case Manager', 'mike.w@reentry.org'),
      ),
    ];
    


    if (mockAssignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.grey1),
            16.height,
            Text(
              'No accepted assignments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
            ),
            8.height,
            Text(
              'You haven\'t accepted any assignment requests yet.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: mockAssignments.length,
      itemBuilder: (context, index) {
        final assignment = mockAssignments[index];
        return _buildAssignmentCard(assignment, false);
      },
    );
  }

  Widget _buildRejectedTab(UserDto account) {
    // TODO: Replace with actual data from CaseCitizenAssignmentRepository
    final mockAssignments = [
      _createMockAssignment(
        id: '4',
        caseManagerId: 'cm-4',
        citizenId: account.userId ?? '',
        assignmentStatus: CaseCitizenAssignmentRequestStatus.rejected,
        requestMessage: 'I can help you with job training and placement.',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        respondedAt: DateTime.now().subtract(const Duration(days: 6)),
        responseMessage: 'I appreciate the offer, but I prefer to work with someone else.',
        caseManager: _createMockUser('Lisa Brown', 'Peer Mentor', 'lisa.b@reentry.org'),
      ),
    ];

    if (mockAssignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, size: 64, color: AppColors.grey1),
            16.height,
            Text(
              'No rejected assignments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
            ),
            8.height,
            Text(
              'You haven\'t rejected any assignment requests.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: mockAssignments.length,
      itemBuilder: (context, index) {
        final assignment = mockAssignments[index];
        return _buildAssignmentCard(assignment, false);
      },
    );
  }

  Widget _buildAssignmentCard(CaseCitizenAssignmentDto assignment, bool isPending) {
    final caseManager = assignment.caseManager;
    
         return Container(
       margin: const EdgeInsets.only(bottom: 16),
       child: BoxContainer(
         child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with case manager info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary,
                child: Text(
                  caseManager?.name?.substring(0, 1).toUpperCase() ?? '?',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              16.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caseManager?.name ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                                         Text(
                       caseManager?.jobTitle ?? 'Case Manager',
                       style: const TextStyle(
                         fontSize: 14,
                         color: AppColors.grey1,
                       ),
                     ),
                                         Text(
                       caseManager?.email ?? '',
                       style: const TextStyle(
                         fontSize: 12,
                         color: AppColors.grey1,
                       ),
                     ),
                  ],
                ),
              ),
              _buildStatusChip(assignment.assignmentStatus),
            ],
          ),
          
          16.height,
          
          // Request message
          if (assignment.requestMessage != null) ...[
            Text(
              'Request Message:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
            ),
            8.height,
                         Text(
               assignment.requestMessage!,
               style: const TextStyle(
                 fontSize: 14,
                 color: AppColors.grey1,
               ),
             ),
            16.height,
          ],
          
          // Response message (if exists)
          if (assignment.responseMessage != null) ...[
            Text(
              'Your Response:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
            ),
            8.height,
                         Text(
               assignment.responseMessage!,
               style: const TextStyle(
                 fontSize: 14,
                 color: AppColors.grey1,
               ),
             ),
            16.height,
          ],
          
          // Timestamps
          Row(
            children: [
              Text(
                'Requested: ${_formatDate(assignment.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.grey1,
                ),
              ),
              if (assignment.respondedAt != null) ...[
                const Spacer(),
                Text(
                  'Responded: ${_formatDate(assignment.respondedAt!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey1,
                  ),
                ),
              ],
            ],
          ),
          
                     // Action buttons for pending requests
           if (isPending) ...[
             16.height,
             Row(
               children: [
                 Expanded(
                   child: ElevatedButton(
                     onPressed: () => _showResponseDialog(assignment, true),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.primary,
                       foregroundColor: AppColors.white,
                       padding: const EdgeInsets.symmetric(vertical: 12),
                     ),
                     child: const Text('Accept'),
                   ),
                 ),
                 16.width,
                 Expanded(
                   child: ElevatedButton(
                     onPressed: () => _showResponseDialog(assignment, false),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.greyDark,
                       foregroundColor: AppColors.white,
                       padding: const EdgeInsets.symmetric(vertical: 12),
                     ),
                     child: const Text('Reject'),
                   ),
                 ),
               ],
             ),
           ],
           
           // Action buttons for accepted care team members
           if (assignment.assignmentStatus == CaseCitizenAssignmentRequestStatus.accepted) ...[
             16.height,
             Row(
               children: [
                 Expanded(
                   child: ElevatedButton.icon(
                     onPressed: () => _openMessageScreen(assignment),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.primary,
                       foregroundColor: AppColors.white,
                       padding: const EdgeInsets.symmetric(vertical: 12),
                     ),
                     icon: const Icon(Icons.message, size: 18),
                     label: const Text('Message'),
                   ),
                 ),
                 16.width,
                 Expanded(
                   child: ElevatedButton.icon(
                     onPressed: () => _createAppointmentWithCareTeamMember(assignment),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.green,
                       foregroundColor: AppColors.white,
                       padding: const EdgeInsets.symmetric(vertical: 12),
                     ),
                     icon: const Icon(Icons.calendar_today, size: 18),
                     label: const Text('Appointment'),
                   ),
                 ),
               ],
             ),
           ],
           

         ],
       ),
     ));
   }

  Widget _buildStatusChip(CaseCitizenAssignmentRequestStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case CaseCitizenAssignmentRequestStatus.pending:
        color = AppColors.orange;
        text = 'Pending';
        break;
      case CaseCitizenAssignmentRequestStatus.accepted:
        color = AppColors.green;
        text = 'Accepted';
        break;
      case CaseCitizenAssignmentRequestStatus.rejected:
        color = AppColors.red;
        text = 'Rejected';
        break;
      case CaseCitizenAssignmentRequestStatus.active:
        color = AppColors.primary;
        text = 'Active';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showResponseDialog(CaseCitizenAssignmentDto assignment, bool isAccepting) {
    _responseController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isAccepting ? 'Accept Assignment' : 'Reject Assignment',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAccepting 
                ? 'Are you sure you want to accept this assignment request?'
                : 'Are you sure you want to reject this assignment request?',
            ),
            16.height,
            InputField(
              controller: _responseController,
              label: isAccepting ? 'Acceptance Message (Optional)' : 'Rejection Reason (Optional)',
              hint: isAccepting 
                ? 'Add a message welcoming the case manager...'
                : 'Explain why you\'re rejecting this request...',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement actual assignment status update
              _updateAssignmentStatus(assignment, isAccepting);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAccepting ? AppColors.primary : AppColors.red,
            ),
            child: Text(isAccepting ? 'Accept' : 'Reject'),
          ),
        ],
      ),
    );
  }

  void _updateAssignmentStatus(CaseCitizenAssignmentDto assignment, bool isAccepting) {
    // TODO: Implement actual API call to update assignment status
    // final status = isAccepting 
    //   ? CaseCitizenAssignmentRequestStatus.accepted 
    //   : CaseCitizenAssignmentRequestStatus.rejected;
    
    // final message = _responseController.text.trim();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAccepting 
            ? 'Assignment accepted successfully!'
            : 'Assignment rejected successfully!',
        ),
        backgroundColor: isAccepting ? AppColors.green : AppColors.red,
      ),
    );
    
    // Refresh the UI
    setState(() {});
  }

  void _openMessageScreen(CaseCitizenAssignmentDto assignment) {
    // TODO: Implement messaging functionality
    // This should open a conversation with the care team member
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening message screen with ${assignment.caseManager?.name ?? 'Care Team Member'}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _createAppointmentWithCareTeamMember(CaseCitizenAssignmentDto assignment) {
    // TODO: Implement appointment creation with care team member as participant
    // This should automatically add the care team member as a participant
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Creating appointment with ${assignment.caseManager?.name ?? 'Care Team Member'} as participant'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  // Mock data creation methods (remove when implementing real data)
  CaseCitizenAssignmentDto _createMockAssignment({
    required String id,
    required String caseManagerId,
    required String citizenId,
    required CaseCitizenAssignmentRequestStatus assignmentStatus,
    String? requestMessage,
    required DateTime createdAt,
    DateTime? respondedAt,
    String? responseMessage,
    UserDto? caseManager,
  }) {
    return CaseCitizenAssignmentDto(
      id: id,
      caseManagerId: caseManagerId,
      citizenId: citizenId,
      assignmentStatus: assignmentStatus,
      requestMessage: requestMessage,
      createdAt: createdAt,
      updatedAt: createdAt,
      respondedAt: respondedAt,
      responseMessage: responseMessage,
      caseManager: caseManager,
    );
  }

  UserDto _createMockUser(String name, String jobTitle, String email) {
    return UserDto(
      userId: 'mock-id',
      email: email,
      name: name,
      phoneNumber: '',
      avatar: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      accountType: AccountType.case_manager,
      deleted: false,
      verificationStatus: null,
      verification: null,
      intakeForm: null,
      moodLogs: [],
      moodTimeLine: [],
      services: [],
      assignee: [],
      jobTitle: jobTitle,
      organization: null,
      organizationAddress: null,
      organizations: [],
      activityDate: null,
      supervisorsName: null,
      dob: null,
      mentors: [],
      pushNotificationToken: null,
      userCode: null,
      personId: 'mock-person-id',
      officers: [],
      password: null,
      settings: const UserSettings(),
      reasonForAccountDeletion: null,
      supervisorsEmail: null,
      address: null,
    );
  }
}
