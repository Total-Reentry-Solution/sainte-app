import 'package:reentry/data/model/care_team_invitation_dto.dart';
import 'package:reentry/data/model/care_team_assignment_dto.dart';
import 'package:reentry/data/model/case_assignment_dto.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/exception/app_exceptions.dart';
import 'package:reentry/core/config/supabase_config.dart';

class CareTeamRepository {

  // Care Team Invitations

  Future<CareTeamInvitationDto> createInvitation({
    required String inviterId,
    required String inviteeId,
    required InvitationType invitationType,
    String? message,
  }) async {
    try {
      final response = await SupabaseConfig.client
          .from('care_team_invitations')
          .insert({
            'inviter_id': inviterId,
            'invitee_id': inviteeId,
            'invitation_type': invitationType.name,
            'status': InvitationStatus.pending.name,
            'message': message,
          })
          .select()
          .single();

      return CareTeamInvitationDto.fromJson(response);
    } catch (e) {
      throw BaseExceptions('Failed to create invitation: ${e.toString()}');
    }
  }

  Future<List<CareTeamInvitationDto>> getInvitationsForUser(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('care_team_invitations')
          .select('*')
          .or('inviter_id.eq.$userId,invitee_id.eq.$userId')
          .order('created_at', ascending: false);

      final invitations = <CareTeamInvitationDto>[];
      
      for (final invitation in response as List) {
        // Get inviter profile
        final inviterProfile = await SupabaseConfig.client
            .from('user_profiles')
            .select()
            .eq('id', invitation['inviter_id'])
            .maybeSingle();
            
        // Get invitee profile
        final inviteeProfile = await SupabaseConfig.client
            .from('user_profiles')
            .select()
            .eq('id', invitation['invitee_id'])
            .maybeSingle();
            
        // Create UserDto objects
        final inviter = inviterProfile != null ? UserDto.fromJson(inviterProfile) : null;
        final invitee = inviteeProfile != null ? UserDto.fromJson(inviteeProfile) : null;
        
        // Create the invitation DTO with the user profiles
        final invitationDto = CareTeamInvitationDto.fromJson(invitation);
        final invitationWithProfiles = invitationDto.copyWith(
          inviter: inviter,
          invitee: invitee,
        );
        
        invitations.add(invitationWithProfiles);
      }

      return invitations;
    } catch (e) {
      throw BaseExceptions('Failed to fetch invitations: ${e.toString()}');
    }
  }

  Future<List<CareTeamInvitationDto>> getPendingInvitationsForUser(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('care_team_invitations')
          .select('*')
          .eq('invitee_id', userId)
          .eq('status', InvitationStatus.pending.name)
          .order('created_at', ascending: false);

      final invitations = <CareTeamInvitationDto>[];
      
      for (final invitation in response as List) {
        // Get inviter profile
        final inviterProfile = await SupabaseConfig.client
            .from('user_profiles')
            .select()
            .eq('id', invitation['inviter_id'])
            .maybeSingle();
            
        // Get invitee profile
        final inviteeProfile = await SupabaseConfig.client
            .from('user_profiles')
            .select()
            .eq('id', invitation['invitee_id'])
            .maybeSingle();
            
        // Create UserDto objects
        final inviter = inviterProfile != null ? UserDto.fromJson(inviterProfile) : null;
        final invitee = inviteeProfile != null ? UserDto.fromJson(inviteeProfile) : null;
        
        // Create the invitation DTO with the user profiles
        final invitationDto = CareTeamInvitationDto.fromJson(invitation);
        final invitationWithProfiles = invitationDto.copyWith(
          inviter: inviter,
          invitee: invitee,
        );
        
        invitations.add(invitationWithProfiles);
      }

      return invitations;
    } catch (e) {
      throw BaseExceptions('Failed to fetch pending invitations: ${e.toString()}');
    }
  }

  Future<void> acceptInvitation(String invitationId, String userId) async {
    try {
      // First, verify the user is the invitee
      final invitation = await SupabaseConfig.client
          .from('care_team_invitations')
          .select()
          .eq('id', invitationId)
          .single();

      if (invitation['invitee_id'] != userId) {
        throw BaseExceptions('User is not authorized to accept this invitation');
      }

      // Update the invitation status
      await SupabaseConfig.client
          .from('care_team_invitations')
          .update({
            'status': InvitationStatus.accepted.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invitationId);

      // Create the assignment
      // Map invitation type to assignment type
      String assignmentType;
      if (invitation['invitation_type'] == 'client_assignment') {
        assignmentType = 'client_assignment';
      } else {
        assignmentType = 'care_team_member';
      }
      
      await SupabaseConfig.client
          .from('care_team_assignments')
          .insert({
            'care_team_member_id': invitation['inviter_id'],
            'client_id': invitation['invitee_id'],
            'assigned_by': invitation['inviter_id'],
            'assignment_type': assignmentType,
            'status': AssignmentStatus.active.name,
            'start_date': DateTime.now().toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw BaseExceptions('Failed to accept invitation: ${e.toString()}');
    }
  }

  Future<void> rejectInvitation(String invitationId, String userId, {String? reason}) async {
    try {
      // First, verify the user is the invitee
      final invitation = await SupabaseConfig.client
          .from('care_team_invitations')
          .select()
          .eq('id', invitationId)
          .single();

      if (invitation['invitee_id'] != userId) {
        throw BaseExceptions('User is not authorized to reject this invitation');
      }

      // Update the invitation status
      await SupabaseConfig.client
          .from('care_team_invitations')
          .update({
            'status': InvitationStatus.rejected.name,
            'reason_for_rejection': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invitationId);
    } catch (e) {
      throw BaseExceptions('Failed to reject invitation: ${e.toString()}');
    }
  }

  // Care Team Assignments

  Future<List<CareTeamAssignmentDto>> getAssignmentsForUser(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('care_team_assignments')
          .select('*')
          .or('care_team_member_id.eq.$userId,client_id.eq.$userId')
          .eq('status', AssignmentStatus.active.name)
          .order('created_at', ascending: false);

      final assignments = <CareTeamAssignmentDto>[];
      
      for (final assignment in response as List) {
        // Get care team member profile
        final careTeamMemberProfile = await SupabaseConfig.client
            .from('user_profiles')
            .select()
            .eq('id', assignment['care_team_member_id'])
            .maybeSingle();
            
        // Get client profile
        final clientProfile = await SupabaseConfig.client
            .from('user_profiles')
            .select()
            .eq('id', assignment['client_id'])
            .maybeSingle();
            
        // Get assigned by user profile
        final assignedByProfile = await SupabaseConfig.client
            .from('user_profiles')
            .select()
            .eq('id', assignment['assigned_by'])
            .maybeSingle();
            
        // Create UserDto objects
        final careTeamMember = careTeamMemberProfile != null ? UserDto.fromJson(careTeamMemberProfile) : null;
        final client = clientProfile != null ? UserDto.fromJson(clientProfile) : null;
        final assignedByUser = assignedByProfile != null ? UserDto.fromJson(assignedByProfile) : null;
        
        // Create the assignment DTO with the user profiles
        final assignmentDto = CareTeamAssignmentDto.fromJson(assignment);
        final assignmentWithProfiles = assignmentDto.copyWith(
          careTeamMember: careTeamMember,
          client: client,
          assignedByUser: assignedByUser,
        );
        
        assignments.add(assignmentWithProfiles);
      }

      return assignments;
    } catch (e) {
      throw BaseExceptions('Failed to fetch assignments: ${e.toString()}');
    }
  }

  Future<List<CareTeamAssignmentDto>> getActiveAssignmentsForCareTeamMember(String careTeamMemberId) async {
    try {
      final response = await SupabaseConfig.client
          .from('care_team_assignments')
          .select('*')
          .eq('care_team_member_id', careTeamMemberId)
          .eq('status', AssignmentStatus.active.name)
          .order('created_at', ascending: false);

      final assignments = <CareTeamAssignmentDto>[];
      
      for (final assignment in response as List) {
        // Get care team member profile
        final careTeamMemberProfile = await SupabaseConfig.client
            .from('user_profiles')
            .select()
            .eq('id', assignment['care_team_member_id'])
            .maybeSingle();
            
        // Get client profile
        final clientProfile = await SupabaseConfig.client
            .from('user_profiles')
            .select()
            .eq('id', assignment['client_id'])
            .maybeSingle();
            
        // Get assigned by user profile
        final assignedByProfile = await SupabaseConfig.client
            .from('user_profiles')
            .select()
            .eq('id', assignment['assigned_by'])
            .maybeSingle();
            
        // Create UserDto objects
        final careTeamMember = careTeamMemberProfile != null ? UserDto.fromJson(careTeamMemberProfile) : null;
        final client = clientProfile != null ? UserDto.fromJson(clientProfile) : null;
        final assignedByUser = assignedByProfile != null ? UserDto.fromJson(assignedByProfile) : null;
        
        // Create the assignment DTO with the user profiles
        final assignmentDto = CareTeamAssignmentDto.fromJson(assignment);
        final assignmentWithProfiles = assignmentDto.copyWith(
          careTeamMember: careTeamMember,
          client: client,
          assignedByUser: assignedByUser,
        );
        
        assignments.add(assignmentWithProfiles);
      }

      return assignments;
    } catch (e) {
      throw BaseExceptions('Failed to fetch active assignments: ${e.toString()}');
    }
  }

  Future<List<CareTeamAssignmentDto>> getActiveAssignmentsForClient(String clientId) async {
    try {
      final response = await SupabaseConfig.client
          .from('care_team_assignments')
          .select('*')
          .eq('client_id', clientId)
          .eq('status', AssignmentStatus.active.name)
          .order('created_at', ascending: false);

      final assignments = <CareTeamAssignmentDto>[];
      
      for (final assignment in response as List) {
        // Get care team member profile
        final careTeamMemberProfile = await SupabaseConfig.client
            .from('user_profiles')
            .select()
            .eq('id', assignment['care_team_member_id'])
            .maybeSingle();
            
        // Get client profile
        final clientProfile = await SupabaseConfig.client
            .from('user_profiles')
            .select()
            .eq('id', assignment['client_id'])
            .maybeSingle();
            
        // Get assigned by user profile
        final assignedByProfile = await SupabaseConfig.client
            .from('user_profiles')
            .select()
            .eq('id', assignment['assigned_by'])
            .maybeSingle();
            
        // Create UserDto objects
        final careTeamMember = careTeamMemberProfile != null ? UserDto.fromJson(careTeamMemberProfile) : null;
        final client = clientProfile != null ? UserDto.fromJson(clientProfile) : null;
        final assignedByUser = assignedByProfile != null ? UserDto.fromJson(assignedByProfile) : null;
        
        // Create the assignment DTO with the user profiles
        final assignmentDto = CareTeamAssignmentDto.fromJson(assignment);
        final assignmentWithProfiles = assignmentDto.copyWith(
          careTeamMember: careTeamMember,
          client: client,
          assignedByUser: assignedByUser,
        );
        
        assignments.add(assignmentWithProfiles);
      }

      return assignments;
    } catch (e) {
      throw BaseExceptions('Failed to fetch client assignments: ${e.toString()}');
    }
  }

  Future<void> terminateAssignment(String assignmentId, String userId) async {
    try {
      // First, verify the user is involved in this assignment
      final assignment = await SupabaseConfig.client
          .from('care_team_assignments')
          .select()
          .eq('id', assignmentId)
          .single();

      if (assignment['care_team_member_id'] != userId && 
          assignment['client_id'] != userId && 
          assignment['assigned_by'] != userId) {
        throw BaseExceptions('User is not authorized to terminate this assignment');
      }

      // Update the assignment status
      await SupabaseConfig.client
          .from('care_team_assignments')
          .update({
            'status': AssignmentStatus.terminated.name,
            'end_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assignmentId);
    } catch (e) {
      throw BaseExceptions('Failed to terminate assignment: ${e.toString()}');
    }
  }

  // Utility methods

  Future<List<UserDto>> searchUsersForInvitation(String searchTerm, String currentUserId) async {
    try {
      final response = await SupabaseConfig.client
          .from('user_profiles')
          .select()
          .or('first_name.ilike.%$searchTerm%,last_name.ilike.%$searchTerm%,email.ilike.%$searchTerm%')
          .eq('account_type', 'citizen') // Only search for citizens
          .neq('id', currentUserId)
          .limit(10);

      return (response as List)
          .map((e) => UserDto.fromJson(e))
          .toList();
    } catch (e) {
      throw BaseExceptions('Failed to search users: ${e.toString()}');
    }
  }

  Future<bool> checkExistingInvitation(String inviterId, String inviteeId, InvitationType invitationType) async {
    try {
              final response = await SupabaseConfig.client
            .from('care_team_invitations')
            .select()
            .eq('inviter_id', inviterId)
            .eq('invitee_id', inviteeId)
            .eq('invitation_type', invitationType.name)
            .or('status.eq.${InvitationStatus.pending.name},status.eq.${InvitationStatus.accepted.name}');

      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkExistingAssignment(String careTeamMemberId, String clientId, AssignmentType assignmentType) async {
    try {
      final response = await SupabaseConfig.client
          .from('care_team_assignments')
          .select()
          .eq('care_team_member_id', careTeamMemberId)
          .eq('client_id', clientId)
          .eq('assignment_type', assignmentType.name)
          .eq('status', AssignmentStatus.active.name);

      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Case Assignments methods

  Future<List<CaseAssignmentDto>> getCaseAssignmentsForClient(String clientId) async {
    try {
      final response = await SupabaseConfig.client
          .from('case_assignments')
          .select('*')
          .eq('person_id', clientId)
          .eq('status', 'active')
          .order('assigned_at', ascending: false);

      final caseAssignments = <CaseAssignmentDto>[];
      
      for (final assignment in response as List) {
        // Get person profile
        final personProfile = await SupabaseConfig.client
            .from('user_profiles')
            .select('*')
            .eq('id', assignment['person_id'])
            .maybeSingle();
            
        // Get caseload profile (this might be a different table)
        final caseloadProfile = await SupabaseConfig.client
            .from('user_profiles')
            .select('*')
            .eq('id', assignment['caseload_id'])
            .maybeSingle();
            
        // Create UserDto objects
        final person = personProfile != null ? UserDto.fromJson(personProfile) : null;
        final caseload = caseloadProfile != null ? UserDto.fromJson(caseloadProfile) : null;
        
        // Create the case assignment DTO with the user profiles
        final caseAssignmentDto = CaseAssignmentDto.fromJson(assignment);
        final caseAssignmentWithProfiles = caseAssignmentDto.copyWith(
          person: person,
          caseload: caseload,
        );
        
        caseAssignments.add(caseAssignmentWithProfiles);
      }

      return caseAssignments;
    } catch (e) {
      throw BaseExceptions('Failed to fetch case assignments: ${e.toString()}');
    }
  }

  Future<List<CaseAssignmentDto>> getCaseAssignmentsForCareTeamMember(String careTeamMemberId) async {
    try {
      // Get all clients assigned to this care team member
      final clientAssignments = await getActiveAssignmentsForCareTeamMember(careTeamMemberId);
      final clientIds = clientAssignments.map((a) => a.clientId).toSet();
      
      if (clientIds.isEmpty) return [];
      
      // Get case assignments for all assigned clients
      final response = await SupabaseConfig.client
          .from('case_assignments')
          .select('*')
          .inFilter('person_id', clientIds.toList())
          .eq('status', 'active')
          .order('assigned_at', ascending: false);

      final caseAssignments = <CaseAssignmentDto>[];
      
      for (final assignment in response as List) {
        // Get person profile
        final personProfile = await SupabaseConfig.client
            .from('user_profiles')
            .select('*')
            .eq('id', assignment['person_id'])
            .maybeSingle();
            
        // Get caseload profile
        final caseloadProfile = await SupabaseConfig.client
            .from('user_profiles')
            .select('*')
            .eq('id', assignment['caseload_id'])
            .maybeSingle();
            
        // Create UserDto objects
        final person = personProfile != null ? UserDto.fromJson(personProfile) : null;
        final caseload = caseloadProfile != null ? UserDto.fromJson(caseloadProfile) : null;
        
        // Create the case assignment DTO with the user profiles
        final caseAssignmentDto = CaseAssignmentDto.fromJson(assignment);
        final caseAssignmentWithProfiles = caseAssignmentDto.copyWith(
          person: person,
          caseload: caseload,
        );
        
        caseAssignments.add(caseAssignmentWithProfiles);
      }

      return caseAssignments;
    } catch (e) {
      throw BaseExceptions('Failed to fetch case assignments for care team member: ${e.toString()}');
    }
  }
}
