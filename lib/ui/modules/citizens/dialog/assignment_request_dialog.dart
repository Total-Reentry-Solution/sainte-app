import 'package:flutter/material.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/core/theme/style/text_style.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/ui/components/buttons/primary_button.dart';
import 'package:reentry/ui/components/input/input_field.dart';
import 'package:reentry/ui/modules/careTeam/bloc/care_team_invitations_cubit.dart';
import 'package:reentry/data/model/care_team_invitation_dto.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AssignmentRequestDialog extends StatefulWidget {
  final UserDto citizen;
  final UserDto caseManager;

  const AssignmentRequestDialog({
    super.key,
    required this.citizen,
    required this.caseManager,
  });

  @override
  State<AssignmentRequestDialog> createState() => _AssignmentRequestDialogState();
}

class _AssignmentRequestDialogState extends State<AssignmentRequestDialog> {
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await context.read<CareTeamInvitationsCubit>().createInvitation(
        inviterId: widget.caseManager.userId ?? '',
        inviteeId: widget.citizen.userId ?? '',
        invitationType: InvitationType.client_assignment,
        message: _messageController.text.trim().isEmpty 
            ? null 
            : _messageController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment request sent successfully!'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: ${e.toString()}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.greyDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(
                      widget.citizen.avatar?.isNotEmpty == true 
                          ? widget.citizen.avatar! 
                          : 'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png?20150327203541',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Assignment',
                          style: AppTextStyle.heading.copyWith(
                            color: AppColors.white,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Request to be assigned to ${widget.citizen.name}',
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
              
              const SizedBox(height: 24),
              
              // Citizen Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.greyWhite.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Citizen Details',
                      style: AppTextStyle.regular.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Name',
                                style: AppTextStyle.regular.copyWith(
                                  color: AppColors.greyWhite,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                widget.citizen.name,
                                style: AppTextStyle.regular.copyWith(
                                  color: AppColors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: AppTextStyle.regular.copyWith(
                                  color: AppColors.greyWhite,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                widget.citizen.email ?? 'No email',
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
              ),
              
              const SizedBox(height: 24),
              
              // Message Input
              Text(
                'Message (Optional)',
                style: AppTextStyle.regular.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              InputField(
                controller: _messageController,
                hint: 'Add a personal message explaining why you want to be assigned...',
                lines: 3,
                maxLines: 4,
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: AppColors.greyWhite.withOpacity(0.3)),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyle.regular.copyWith(
                          color: AppColors.greyWhite,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButton(
                      text: _isSubmitting ? 'Sending...' : 'Send Request',
                      onPress: _isSubmitting ? null : _submitRequest,
                      loading: _isSubmitting,
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
}
