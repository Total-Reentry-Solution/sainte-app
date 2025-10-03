import '../../model/user.dart';
import '../../enum/account_type.dart';

// Clean User Repository Interface
abstract class UserRepositoryInterface {
  // User CRUD
  Future<AppUser?> getUserById(String userId);
  Future<List<AppUser>> getAllUsers();
  Future<AppUser?> createUser(AppUser user);
  Future<AppUser?> updateUser(AppUser user);
  Future<void> deleteUser(String userId);
  
  // User Search & Filtering
  Future<List<AppUser>> searchUsers(String query);
  Future<List<AppUser>> getUsersByAccountType(AccountType accountType);
  Future<List<AppUser>> getUsersByOrganization(String organizationId);
  
  // User Relationships
  Future<List<AppUser>> getMentorsForUser(String userId);
  Future<List<AppUser>> getClientsForMentor(String mentorId);
  Future<List<AppUser>> getOfficersForUser(String userId);
  
  // User Profile
  Future<AppUser?> updateUserProfile(String userId, Map<String, dynamic> profileData);
  Future<String?> uploadUserAvatar(String userId, String imagePath);
}
