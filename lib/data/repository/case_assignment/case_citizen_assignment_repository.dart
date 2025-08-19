import 'package:reentry/core/config/supabase_config.dart';
import 'package:reentry/data/model/case_citizen_assignment_dto.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/repository/user/user_repository.dart';

class CaseCitizenAssignmentRepository {
  static const String _tableName = 'case_citizen_assignment';

  /// Create a new case citizen assignment
  Future<CaseCitizenAssignmentDto> createAssignment(CaseCitizenAssignmentDto assignment) async {
    try {
      final response = await SupabaseConfig.client
          .from(_tableName)
          .insert(assignment.toJson())
          .select()
          .single();
      
      if (response == null) {
        throw Exception('Failed to create case citizen assignment');
      }
      
      return CaseCitizenAssignmentDto.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create case citizen assignment: ${e.toString()}');
    }
  }

  /// Get all assignments for a case manager
  Future<List<CaseCitizenAssignmentDto>> getAssignmentsForCaseManager(String caseManagerId) async {
    try {
      final response = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .eq('case_manager_id', caseManagerId)
          .order('created_at', ascending: false);
      
      List<CaseCitizenAssignmentDto> assignments = [];
      for (var assignment in response) {
        // Fetch citizen information
        UserDto? citizen;
        try {
          citizen = await UserRepository().getUserById(assignment['citizen_id']);
        } catch (e) {
          print('Error fetching citizen info: $e');
        }
        
        assignments.add(CaseCitizenAssignmentDto.fromJson(assignment).copyWith(citizen: citizen));
      }
      
      return assignments;
    } catch (e) {
      throw Exception('Failed to get assignments for case manager: ${e.toString()}');
    }
  }

  /// Get all assignments for a citizen
  Future<List<CaseCitizenAssignmentDto>> getAssignmentsForCitizen(String citizenId) async {
    try {
      final response = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .eq('citizen_id', citizenId)
          .order('created_at', ascending: false);
      
      List<CaseCitizenAssignmentDto> assignments = [];
      for (var assignment in response) {
        // Fetch case manager information
        UserDto? caseManager;
        try {
          caseManager = await UserRepository().getUserById(assignment['case_manager_id']);
        } catch (e) {
          print('Error fetching case manager info: $e');
        }
        
        assignments.add(CaseCitizenAssignmentDto.fromJson(assignment).copyWith(caseManager: caseManager));
      }
      
      return assignments;
    } catch (e) {
      throw Exception('Failed to get assignments for citizen: ${e.toString()}');
    }
  }

  /// Get a specific assignment by ID
  Future<CaseCitizenAssignmentDto?> getAssignmentById(String assignmentId) async {
    try {
      final response = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .eq('id', assignmentId)
          .single();
      
      if (response == null) return null;
      
      // Fetch both user information
      UserDto? caseManager;
      UserDto? citizen;
      try {
        caseManager = await UserRepository().getUserById(response['case_manager_id']);
        citizen = await UserRepository().getUserById(response['citizen_id']);
      } catch (e) {
        print('Error fetching user info: $e');
      }
      
      return CaseCitizenAssignmentDto.fromJson(response)
          .copyWith(caseManager: caseManager, citizen: citizen);
    } catch (e) {
      throw Exception('Failed to get assignment by ID: ${e.toString()}');
    }
  }

  /// Update assignment status (accept/reject)
  Future<CaseCitizenAssignmentDto> updateAssignmentStatus(
    String assignmentId, 
    CaseCitizenAssignmentRequestStatus status, 
    {String? responseMessage}
  ) async {
    try {
      final updateData = {
        'assignment_status': status.name,
        'responded_at': DateTime.now().toIso8601String(),
        if (responseMessage != null) 'response_message': responseMessage,
        if (status == CaseCitizenAssignmentRequestStatus.accepted) 'assigned_at': DateTime.now().toIso8601String(),
      };
      
      final response = await SupabaseConfig.client
          .from(_tableName)
          .update(updateData)
          .eq('id', assignmentId)
          .select()
          .single();
      
      if (response == null) {
        throw Exception('Failed to update assignment status');
      }
      
      return CaseCitizenAssignmentDto.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update assignment status: ${e.toString()}');
    }
  }

  /// Cancel an assignment (case manager can cancel pending assignments)
  Future<void> cancelAssignment(String assignmentId) async {
    try {
      await SupabaseConfig.client
          .from(_tableName)
          .delete()
          .eq('id', assignmentId);
    } catch (e) {
      throw Exception('Failed to cancel assignment: ${e.toString()}');
    }
  }

  /// Check if an assignment already exists between case manager and citizen
  Future<bool> assignmentExists(String caseManagerId, String citizenId) async {
    try {
      final response = await SupabaseConfig.client
          .from(_tableName)
          .select('id')
          .eq('case_manager_id', caseManagerId)
          .eq('citizen_id', citizenId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Get pending assignments count for a citizen
  Future<int> getPendingAssignmentsCount(String citizenId) async {
    try {
      final response = await SupabaseConfig.client
          .from(_tableName)
          .select('id')
          .eq('citizen_id', citizenId)
          .eq('assignment_status', CaseCitizenAssignmentRequestStatus.pending.name);
      
      return response.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get all assignments with user information (for admin purposes)
  Future<List<CaseCitizenAssignmentDto>> getAllAssignments() async {
    try {
      final response = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);
      
      List<CaseCitizenAssignmentDto> assignments = [];
      for (var assignment in response) {
        // Fetch both user information
        UserDto? caseManager;
        UserDto? citizen;
        try {
          caseManager = await UserRepository().getUserById(assignment['case_manager_id']);
          citizen = await UserRepository().getUserById(assignment['citizen_id']);
        } catch (e) {
          print('Error fetching user info: $e');
        }
        
        assignments.add(CaseCitizenAssignmentDto.fromJson(assignment)
            .copyWith(caseManager: caseManager, citizen: citizen));
      }
      
      return assignments;
    } catch (e) {
      throw Exception('Failed to get all assignments: ${e.toString()}');
    }
  }
}
