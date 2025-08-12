import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/ui/components/container/box_container.dart';
import 'package:reentry/ui/modules/careTeam/bloc/care_team_invitations_cubit.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/model/care_team_invitation_dto.dart';
import 'package:reentry/data/enum/account_type.dart';

class InviteUserDialog extends StatefulWidget {
  final String currentUserId;

  const InviteUserDialog({
    super.key,
    required this.currentUserId,
  });

  @override
  State<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<InviteUserDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  UserDto? _selectedUser;
  InvitationType _invitationType = InvitationType.care_team_member;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.length >= 2) {
      setState(() {
        _isSearching = true;
      });
      context.read<CareTeamInvitationsCubit>().searchUsersForInvitation(
        _searchController.text,
        widget.currentUserId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.greyDark,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invite User to Care Team',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            20.height,
            
            // Invitation Type Selection
            const Text(
              'Invitation Type:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            10.height,
            DropdownButtonFormField<InvitationType>(
              value: _invitationType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              dropdownColor: AppColors.greyDark,
              style: const TextStyle(color: AppColors.white),
              items: InvitationType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    type == InvitationType.care_team_member 
                        ? 'Add to Care Team'
                        : 'Assign as Case Manager',
                    style: const TextStyle(color: AppColors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _invitationType = value!;
                });
              },
            ),
            20.height,

            // User Search
            const Text(
              'Search Users:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            10.height,
            TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: TextStyle(color: AppColors.gray2),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search, color: AppColors.gray2),
              ),
            ),
            10.height,

            // Search Results
            if (_isSearching || _selectedUser != null) ...[
              BlocBuilder<CareTeamInvitationsCubit, CareTeamInvitationsState>(
                builder: (context, state) {
                  if (state is CareTeamInvitationsLoading && _isSearching) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is CareTeamInvitationsSuccess && state.searchResults.isNotEmpty) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gray2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: state.searchResults.length,
                        itemBuilder: (context, index) {
                          final user = state.searchResults[index];
                          final isSelected = _selectedUser?.userId == user.userId;
                          
                          // Filter out users who are not citizens (only citizens can be invited to care teams)
                          if (user.accountType != AccountType.citizen) {
                            return const SizedBox();
                          }
                          
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: AppColors.primary.withOpacity(0.3),
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(user.avatar ?? 'https://via.placeholder.com/40'),
                              radius: 20,
                            ),
                            title: Text(
                              user.name ?? 'Unknown User',
                              style: const TextStyle(
                                color: AppColors.white,
                              ),
                            ),
                            subtitle: Text(
                              user.email ?? '',
                              style: const TextStyle(
                                color: AppColors.gray2,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedUser = user;
                                _isSearching = false;
                              });
                            },
                          );
                        },
                      ),
                    );
                  }

                  if (state is CareTeamInvitationsSuccess && state.searchResults.isEmpty && _searchController.text.isNotEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No users found',
                          style: TextStyle(color: AppColors.gray2),
                        ),
                      ),
                    );
                  }

                  return const SizedBox();
                },
              ),
            ],

            // Selected User
            if (_selectedUser != null) ...[
              20.height,
              BoxContainer(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(_selectedUser!.avatar ?? 'https://via.placeholder.com/40'),
                        radius: 25,
                      ),
                      12.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedUser!.name ?? 'Unknown User',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                            Text(
                              _selectedUser!.email ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.gray2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedUser = null;
                          });
                        },
                        icon: const Icon(Icons.close, color: AppColors.gray2),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Message
            if (_selectedUser != null) ...[
              20.height,
              const Text(
                'Message (optional):',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              10.height,
              TextField(
                controller: _messageController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  hintText: 'Add a personal message...',
                  hintStyle: TextStyle(color: AppColors.gray2),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],

            20.height,

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.gray2),
                    ),
                  ),
                ),
                if (_selectedUser != null) ...[
                  10.width,
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _sendInvitation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Send Invitation'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendInvitation() {
    if (_selectedUser == null) return;

    context.read<CareTeamInvitationsCubit>().createInvitation(
      inviterId: widget.currentUserId,
      inviteeId: _selectedUser!.userId!,
      invitationType: _invitationType,
      message: _messageController.text.isEmpty ? null : _messageController.text,
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invitation sent to ${_selectedUser!.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
