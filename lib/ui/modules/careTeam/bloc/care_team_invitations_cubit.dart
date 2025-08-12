import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/data/model/care_team_invitation_dto.dart';
import 'package:reentry/data/model/care_team_assignment_dto.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/repository/care_team/care_team_repository.dart';

// States
abstract class CareTeamInvitationsState {}

class CareTeamInvitationsInitial extends CareTeamInvitationsState {}

class CareTeamInvitationsLoading extends CareTeamInvitationsState {}

class CareTeamInvitationsSuccess extends CareTeamInvitationsState {
  final List<CareTeamInvitationDto> invitations;
  final List<CareTeamAssignmentDto> assignments;
  final List<UserDto> searchResults;

  CareTeamInvitationsSuccess({
    this.invitations = const [],
    this.assignments = const [],
    this.searchResults = const [],
  });
}

class CareTeamInvitationsError extends CareTeamInvitationsState {
  final String message;

  CareTeamInvitationsError(this.message);
}

// Cubit
class CareTeamInvitationsCubit extends Cubit<CareTeamInvitationsState> {
  final CareTeamRepository _repository = CareTeamRepository();

  CareTeamInvitationsCubit() : super(CareTeamInvitationsInitial());

  Future<void> fetchInvitationsForUser(String userId) async {
    emit(CareTeamInvitationsLoading());
    try {
      final invitations = await _repository.getInvitationsForUser(userId);
      final assignments = await _repository.getAssignmentsForUser(userId);
      emit(CareTeamInvitationsSuccess(
        invitations: invitations,
        assignments: assignments,
      ));
    } catch (e) {
      emit(CareTeamInvitationsError(e.toString()));
    }
  }

  Future<void> fetchPendingInvitationsForUser(String userId) async {
    emit(CareTeamInvitationsLoading());
    try {
      final invitations = await _repository.getPendingInvitationsForUser(userId);
      emit(CareTeamInvitationsSuccess(invitations: invitations));
    } catch (e) {
      emit(CareTeamInvitationsError(e.toString()));
    }
  }

  Future<void> createInvitation({
    required String inviterId,
    required String inviteeId,
    required InvitationType invitationType,
    String? message,
  }) async {
    emit(CareTeamInvitationsLoading());
    try {
      await _repository.createInvitation(
        inviterId: inviterId,
        inviteeId: inviteeId,
        invitationType: invitationType,
        message: message,
      );
      
      // Refresh invitations
      final invitations = await _repository.getInvitationsForUser(inviterId);
      final assignments = await _repository.getAssignmentsForUser(inviterId);
      emit(CareTeamInvitationsSuccess(
        invitations: invitations,
        assignments: assignments,
      ));
    } catch (e) {
      emit(CareTeamInvitationsError(e.toString()));
    }
  }

  Future<void> acceptInvitation(String invitationId, String userId) async {
    emit(CareTeamInvitationsLoading());
    try {
      await _repository.acceptInvitation(invitationId, userId);
      
      // Refresh invitations and assignments
      final invitations = await _repository.getInvitationsForUser(userId);
      final assignments = await _repository.getAssignmentsForUser(userId);
      emit(CareTeamInvitationsSuccess(
        invitations: invitations,
        assignments: assignments,
      ));
    } catch (e) {
      emit(CareTeamInvitationsError(e.toString()));
    }
  }

  Future<void> rejectInvitation(String invitationId, String userId, {String? reason}) async {
    emit(CareTeamInvitationsLoading());
    try {
      await _repository.rejectInvitation(invitationId, userId, reason: reason);
      
      // Refresh invitations
      final invitations = await _repository.getInvitationsForUser(userId);
      final assignments = await _repository.getAssignmentsForUser(userId);
      emit(CareTeamInvitationsSuccess(
        invitations: invitations,
        assignments: assignments,
      ));
    } catch (e) {
      emit(CareTeamInvitationsError(e.toString()));
    }
  }

  Future<void> terminateAssignment(String assignmentId, String userId) async {
    emit(CareTeamInvitationsLoading());
    try {
      await _repository.terminateAssignment(assignmentId, userId);
      
      // Refresh assignments
      final invitations = await _repository.getInvitationsForUser(userId);
      final assignments = await _repository.getAssignmentsForUser(userId);
      emit(CareTeamInvitationsSuccess(
        invitations: invitations,
        assignments: assignments,
      ));
    } catch (e) {
      emit(CareTeamInvitationsError(e.toString()));
    }
  }

  Future<void> searchUsersForInvitation(String searchTerm, String currentUserId) async {
    try {
      final searchResults = await _repository.searchUsersForInvitation(searchTerm, currentUserId);
      emit(CareTeamInvitationsSuccess(searchResults: searchResults));
    } catch (e) {
      emit(CareTeamInvitationsError(e.toString()));
    }
  }

  Future<bool> checkExistingInvitation(String inviterId, String inviteeId, InvitationType invitationType) async {
    try {
      return await _repository.checkExistingInvitation(inviterId, inviteeId, invitationType);
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkExistingAssignment(String careTeamMemberId, String clientId, AssignmentType assignmentType) async {
    try {
      return await _repository.checkExistingAssignment(careTeamMemberId, clientId, assignmentType);
    } catch (e) {
      return false;
    }
  }
}
