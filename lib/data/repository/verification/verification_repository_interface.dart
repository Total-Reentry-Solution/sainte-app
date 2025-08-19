import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/model/verification_question.dart';
import 'package:reentry/data/model/user_dto.dart';

abstract class VerificationRepositoryInterface {
  Future<void> createVerificationRequest(VerificationRequestDto request);
  Future<List<VerificationRequestDto>> getVerificationRequests();
  Future<void> updateVerificationRequest(VerificationRequestDto request);
  
  // Additional methods that are being called in the blocs
  Future<List<UserDto>> getAllUsersVerificationRequest(VerificationStatus status);
  Future<void> updateForm(UserDto user, VerificationStatus status);
  Future<void> submitForm(UserDto user, Map<String, String> form);
  Future<List<VerificationQuestionDto>> fetchQuestions();
  Future<void> createQuestion(VerificationQuestionDto question);
  Future<void> deleteQuestion(String id);
  Future<void> updateQuestion(VerificationQuestionDto question);
  Future<List<VerificationQuestionDto>> getAllQuestions();
} 