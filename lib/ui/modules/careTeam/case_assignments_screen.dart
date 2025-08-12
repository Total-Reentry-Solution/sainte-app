import 'package:flutter/material.dart';

import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/core/theme/style/text_style.dart';
import 'package:reentry/data/model/case_assignment_dto.dart';
import 'package:reentry/data/repository/care_team/care_team_repository.dart';
import 'package:reentry/data/shared/share_preference.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/components/app_bar.dart';
import 'package:reentry/ui/components/loading_component.dart';
import 'package:reentry/ui/components/error_component.dart';

class CaseAssignmentsScreen extends StatefulWidget {
  const CaseAssignmentsScreen({super.key});

  @override
  State<CaseAssignmentsScreen> createState() => _CaseAssignmentsScreenState();
}

class _CaseAssignmentsScreenState extends State<CaseAssignmentsScreen> {
  List<CaseAssignmentDto> _caseAssignments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCaseAssignments();
  }

  Future<void> _loadCaseAssignments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = await PersistentStorage.getCurrentUser();
      if (currentUser == null) {
        setState(() {
          _error = 'User not found';
          _isLoading = false;
        });
        return;
      }

      final careTeamRepo = CareTeamRepository();
      final assignments = await careTeamRepo.getCaseAssignmentsForCareTeamMember(currentUser.userId!);

      setState(() {
        _caseAssignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: CustomAppbar(
        title: 'Case Assignments',
        onBackPress: () => Navigator.pop(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Case Assignments',
              style: AppTextStyle.heading.copyWith(
                color: AppColors.white,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'View case assignments for your assigned clients',
              style: AppTextStyle.regular.copyWith(
                color: AppColors.greyWhite,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            
            if (_isLoading)
              const LoadingComponent()
            else if (_error != null)
              ErrorComponent(
                description: _error!,
                onActionButtonClick: _loadCaseAssignments,
              )
            else if (_caseAssignments.isEmpty)
              _buildEmptyState()
            else
              Expanded(
                child: _buildCaseAssignmentsList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: AppColors.greyWhite.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Case Assignments',
            style: AppTextStyle.heading.copyWith(
              color: AppColors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have access to any case assignments yet.\nAssignments will appear here once you are assigned to clients.',
            style: AppTextStyle.regular.copyWith(
              color: AppColors.greyWhite,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCaseAssignmentsList() {
    return ListView.builder(
      itemCount: _caseAssignments.length,
      itemBuilder: (context, index) {
        final assignment = _caseAssignments[index];
        return _buildCaseAssignmentCard(assignment);
      },
    );
  }

  Widget _buildCaseAssignmentCard(CaseAssignmentDto assignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyWhite.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Case Assignment',
                      style: AppTextStyle.regular.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${assignment.assignmentId}',
                      style: AppTextStyle.regular.copyWith(
                        color: AppColors.greyWhite,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(assignment.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(assignment.status).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  assignment.status.name.toUpperCase(),
                  style: AppTextStyle.regular.copyWith(
                    color: _getStatusColor(assignment.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Client Information
          if (assignment.person != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    assignment.person!.avatar?.isNotEmpty == true 
                        ? assignment.person!.avatar! 
                        : 'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png?20150327203541',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Client',
                        style: AppTextStyle.regular.copyWith(
                          color: AppColors.greyWhite,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        assignment.person!.name,
                        style: AppTextStyle.regular.copyWith(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (assignment.person!.email != null)
                        Text(
                          assignment.person!.email!,
                          style: AppTextStyle.regular.copyWith(
                            color: AppColors.greyWhite,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // Assignment Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Date',
                      style: AppTextStyle.regular.copyWith(
                        color: AppColors.greyWhite,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatDate(assignment.assignedAt),
                      style: AppTextStyle.regular.copyWith(
                        color: AppColors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Caseload ID',
                      style: AppTextStyle.regular.copyWith(
                        color: AppColors.greyWhite,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      assignment.caseloadId,
                      style: AppTextStyle.regular.copyWith(
                        color: AppColors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(CaseAssignmentStatus status) {
    switch (status) {
      case CaseAssignmentStatus.active:
        return AppColors.green;
      case CaseAssignmentStatus.inactive:
        return AppColors.greyWhite;
      case CaseAssignmentStatus.completed:
        return AppColors.primary;
      case CaseAssignmentStatus.terminated:
        return AppColors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
