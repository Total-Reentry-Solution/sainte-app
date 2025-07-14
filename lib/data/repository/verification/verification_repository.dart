import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/repository/verification/verification_repository_interface.dart';
import 'package:reentry/exception/app_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/config/supabase_config.dart';
import '../../model/user_dto.dart';
import '../../model/verification_question.dart';
import '../../enum/account_type.dart';
import 'package:reentry/data/shared/share_preference.dart';

class VerificationRepository extends VerificationRepositoryInterface {

  @override
  Future<void> createVerificationRequest(VerificationRequestDto request) async {
    try {
      final user = await PersistentStorage.getCurrentUser();
      final accountType = user?.accountType ?? AccountType.citizen;
      
      await SupabaseConfig.client
          .from('verification_requests')
          .insert({
            'id': request.id,
            'user_id': request.userId ?? user?.userId,
            'question_id': request.questionId,
            'answer': request.answer,
            'status': request.status.name,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw BaseExceptions('Failed to create verification request: ${e.toString()}');
    }
  }

  @override
  Future<List<VerificationRequestDto>> getVerificationRequests() async {
    try {
      final response = await SupabaseConfig.client
          .from('verification_requests')
          .select()
          .order('created_at', ascending: false);
      
      return response.map((request) => VerificationRequestDto(
        id: request['id'],
        userId: request['user_id'],
        questionId: request['question_id'],
        answer: request['answer'],
        status: VerificationStatus.values.firstWhere(
          (e) => e.name == request['status'],
          orElse: () => VerificationStatus.pending,
        ),
        createdAt: DateTime.parse(request['created_at']),
        updatedAt: DateTime.parse(request['updated_at']),
      )).toList();
    } catch (e) {
      throw BaseExceptions('Failed to get verification requests: ${e.toString()}');
    }
  }

  @override
  Future<void> updateVerificationRequest(VerificationRequestDto request) async {
    try {
      if (request.id == null) {
        throw BaseExceptions('Verification request ID is required for update');
      }
      
      await SupabaseConfig.client
          .from('verification_requests')
          .update({
            'answer': request.answer,
            'status': request.status.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', request.id ?? '');
    } catch (e) {
      throw BaseExceptions('Failed to update verification request: ${e.toString()}');
    }
  }

  @override
  Future<List<UserDto>> getAllUsersVerificationRequest(VerificationStatus status) async {
    // COMMENTED OUT: verification_status and account_type do not exist in user_profiles schema
    /*
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .select()
          .eq('verification_status', status.name);
      return response.map((user) => UserDto(
        userId: user['id'],
        name: user['full_name'] ?? '',
        accountType: AccountType.values.firstWhere(
          (e) => e.name == user['account_type'],
          orElse: () => AccountType.citizen,
        ),
        email: user['email'],
        verificationStatus: user['verification_status'],
        createdAt: DateTime.tryParse(user['created_at'] ?? ''),
        updatedAt: DateTime.tryParse(user['updated_at'] ?? ''),
      )).toList();
    } catch (e) {
      throw BaseExceptions('Failed to get users verification requests:  [${e.toString()}');
    }
    */
    return [];
  }

  @override
  Future<void> updateForm(UserDto user, VerificationStatus status) async {
    // COMMENTED OUT: verification_status does not exist in user_profiles schema
    /*
    try {
      await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .update({
            'verification_status': status.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.userId!);
    } catch (e) {
      throw BaseExceptions('Failed to update form:  [${e.toString()}');
    }
    */
    return;
  }

  @override
  Future<void> submitForm(UserDto user, Map<String, String> form) async {
    // COMMENTED OUT: verification_status and verification_form do not exist in user_profiles schema
    /*
    try {
      await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .update({
            'verification_status': VerificationStatus.pending.name,
            'verification_form': form,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.userId!);
    } catch (e) {
      throw BaseExceptions('Failed to submit form:  [${e.toString()}');
    }
    */
    return;
  }

  @override
  Future<List<VerificationQuestionDto>> fetchQuestions() async {
    try {
      final response = await SupabaseConfig.client
          .from('verification_questions')
          .select()
          .order('created_at', ascending: false);
      
      return response.map((question) => VerificationQuestionDto(
        id: question['id'],
        question: question['question'] ?? '',
        createdAt: question['created_at'],
        updatedAt: question['updated_at'],
      )).toList();
    } catch (e) {
      throw BaseExceptions('Failed to fetch questions: ${e.toString()}');
    }
  }

  @override
  Future<void> createQuestion(VerificationQuestionDto question) async {
    try {
      await SupabaseConfig.client
          .from('verification_questions')
          .insert({
            'id': question.id,
            'question': question.question,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw BaseExceptions('Failed to create question: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteQuestion(String id) async {
    try {
      await SupabaseConfig.client
          .from('verification_questions')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw BaseExceptions('Failed to delete question: ${e.toString()}');
    }
  }

  @override
  Future<void> updateQuestion(VerificationQuestionDto question) async {
    try {
      await SupabaseConfig.client
          .from('verification_questions')
          .update({
            'question': question.question,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', question.id!);
    } catch (e) {
      throw BaseExceptions('Failed to update question: ${e.toString()}');
    }
  }

  @override
  Future<List<VerificationQuestionDto>> getAllQuestions() async {
    return fetchQuestions();
  }
}
