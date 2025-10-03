import '../../model/user.dart';

// Clean Auth Repository Interface
abstract class AuthRepositoryInterface {
  // Authentication
  Future<AppUser?> signInWithEmail(String email, String password);
  Future<AppUser?> signUpWithEmail(String email, String password, String firstName, String lastName);
  Future<void> signOut();
  Future<AppUser?> getCurrentUser();
  
  // User Management
  Future<AppUser?> updateUser(AppUser user);
  Future<void> deleteUser(String userId);
  
  // Password Management
  Future<void> resetPassword(String email);
  Future<void> updatePassword(String newPassword);
  
  // Account Verification
  Future<void> sendVerificationEmail();
  Future<bool> verifyEmail(String token);
}
