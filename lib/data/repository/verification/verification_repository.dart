import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reentry/core/config/supabase_config.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/model/verification_question.dart';
import 'package:reentry/data/repository/verification/verification_request_dto.dart';
import 'package:reentry/data/shared/share_preference.dart';

class VerificationRepository {
  final _supabase = SupabaseConfig.client;

  Future<void> createQuestion(String question) async {
    try {
      final questionData = {
        'question': question,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('questions')
          .insert(questionData);
    } catch (e) {
      throw Exception('Failed to create question: ${e.toString()}');
    }
  }

  Future<void> updateQuestion(VerificationQuestionDto question) async {
    try {
      final updateData = {
        'question': question.question,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('questions')
          .update(updateData)
          .eq('id', question.id);
    } catch (e) {
      throw Exception('Failed to update question: ${e.toString()}');
    }
  }

  Future<void> deleteQuestion(String? id) async {
    if (id == null) {
      return;
    }
    
    try {
      await _supabase
          .from('questions')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete question: ${e.toString()}');
    }
  }

  Future<List<VerificationQuestionDto>> fetchQuestions() async {
    try {
      final response = await _supabase
          .from('questions')
          .select()
          .order('created_at', ascending: false);

      return response
          .map((e) => VerificationQuestionDto.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch questions: ${e.toString()}');
    }
  }

  Stream<List<VerificationQuestionDto>> getAllQuestions() {
    return _supabase
        .from('questions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((response) {
          return response
              .map((e) => VerificationQuestionDto.fromJson(e))
              .toList();
        });
  }

  // Submit verification request
  Future<void> submitVerificationRequest(VerificationRequestDto request) async {
    try {
      final requestData = {
        'user_id': request.userId,
        'question_id': request.questionId,
        'answer': request.answer,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('verification_requests')
          .insert(requestData);
    } catch (e) {
      throw Exception('Failed to submit verification request: ${e.toString()}');
    }
  }

  // Get verification requests for a user
  Future<List<VerificationRequestDto>> getUserVerificationRequests(String userId) async {
    try {
      final response = await _supabase
          .from('verification_requests')
          .select('*, questions(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response
          .map((e) => VerificationRequestDto.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch verification requests: ${e.toString()}');
    }
  }

  // Get all verification requests (for admin)
  Future<List<VerificationRequestDto>> getAllVerificationRequests() async {
    try {
      final response = await _supabase
          .from('verification_requests')
          .select('*, questions(*), user_profiles!verification_requests_user_id_fkey(*)')
          .order('created_at', ascending: false);

      return response
          .map((e) => VerificationRequestDto.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all verification requests: ${e.toString()}');
    }
  }

  // Update verification request status
  Future<void> updateVerificationRequestStatus(String requestId, String status) async {
    try {
      await _supabase
          .from('verification_requests')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to update verification request status: ${e.toString()}');
    }
  }

  // Get verification statistics
  Future<Map<String, dynamic>> getVerificationStats() async {
    try {
      final totalRequests = await _supabase
          .from('verification_requests')
          .select('id', const FetchOptions(count: CountOption.exact));
      
      final pendingRequests = await _supabase
          .from('verification_requests')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('status', 'pending');
      
      final approvedRequests = await _supabase
          .from('verification_requests')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('status', 'approved');
      
      final rejectedRequests = await _supabase
          .from('verification_requests')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('status', 'rejected');

      return {
        'total_requests': totalRequests.count ?? 0,
        'pending_requests': pendingRequests.count ?? 0,
        'approved_requests': approvedRequests.count ?? 0,
        'rejected_requests': rejectedRequests.count ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to get verification statistics: ${e.toString()}');
    }
  }

  // Get questions by category
  Future<List<VerificationQuestionDto>> getQuestionsByCategory(String category) async {
    try {
      final response = await _supabase
          .from('questions')
          .select()
          .eq('category', category)
          .order('created_at', ascending: false);

      return response
          .map((e) => VerificationQuestionDto.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch questions by category: ${e.toString()}');
    }
  }

  // Search questions
  Future<List<VerificationQuestionDto>> searchQuestions(String query) async {
    try {
      final response = await _supabase
          .from('questions')
          .select()
          .ilike('question', '%$query%')
          .order('created_at', ascending: false);

      return response
          .map((e) => VerificationQuestionDto.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to search questions: ${e.toString()}');
    }
  }
}
