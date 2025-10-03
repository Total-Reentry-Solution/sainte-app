import 'user_repository_interface.dart';
import '../../model/user.dart';
import '../../enum/account_type.dart';

// Mock User Repository - Clean implementation with mock data
class MockUserRepository implements UserRepositoryInterface {
  static final List<AppUser> _users = [];

  @override
  Future<AppUser?> getUserById(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<AppUser>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_users);
  }

  @override
  Future<AppUser?> createUser(AppUser user) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Check if user already exists
    if (_users.any((u) => u.id == user.id)) {
      return null;
    }
    
    _users.add(user);
    return user;
  }

  @override
  Future<AppUser?> updateUser(AppUser user) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
      return user;
    }
    return null;
  }

  @override
  Future<void> deleteUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _users.removeWhere((u) => u.id == userId);
  }

  @override
  Future<List<AppUser>> searchUsers(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final lowercaseQuery = query.toLowerCase();
    return _users.where((u) => 
      u.firstName.toLowerCase().contains(lowercaseQuery) ||
      u.lastName.toLowerCase().contains(lowercaseQuery) ||
      u.email.toLowerCase().contains(lowercaseQuery) ||
      u.fullName.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  @override
  Future<List<AppUser>> getUsersByAccountType(AccountType accountType) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return _users.where((u) => u.accountType == accountType).toList();
  }

  @override
  Future<List<AppUser>> getUsersByOrganization(String organizationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return _users.where((u) => u.organizationIds.contains(organizationId)).toList();
  }

  @override
  Future<List<AppUser>> getMentorsForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final user = _users.firstWhere((u) => u.id == userId, orElse: () => throw Exception('User not found'));
    return _users.where((u) => 
      u.accountType == AccountType.mentor && 
      user.mentorIds.contains(u.id)
    ).toList();
  }

  @override
  Future<List<AppUser>> getClientsForMentor(String mentorId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return _users.where((u) => 
      u.accountType == AccountType.citizen && 
      u.mentorIds.contains(mentorId)
    ).toList();
  }

  @override
  Future<List<AppUser>> getOfficersForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final user = _users.firstWhere((u) => u.id == userId, orElse: () => throw Exception('User not found'));
    return _users.where((u) => 
      u.accountType == AccountType.officer && 
      user.officerIds.contains(u.id)
    ).toList();
  }

  @override
  Future<AppUser?> updateUserProfile(String userId, Map<String, dynamic> profileData) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _users[index];
      final updatedUser = user.copyWith(
        firstName: profileData['firstName'] ?? user.firstName,
        lastName: profileData['lastName'] ?? user.lastName,
        phoneNumber: profileData['phoneNumber'] ?? user.phoneNumber,
        address: profileData['address'] ?? user.address,
        jobTitle: profileData['jobTitle'] ?? user.jobTitle,
        organization: profileData['organization'] ?? user.organization,
        organizationAddress: profileData['organizationAddress'] ?? user.organizationAddress,
        supervisorName: profileData['supervisorName'] ?? user.supervisorName,
        supervisorEmail: profileData['supervisorEmail'] ?? user.supervisorEmail,
        dateOfBirth: profileData['dateOfBirth'] ?? user.dateOfBirth,
        about: profileData['about'] ?? user.about,
        updatedAt: DateTime.now(),
      );
      
      _users[index] = updatedUser;
      return updatedUser;
    }
    return null;
  }

  @override
  Future<String?> uploadUserAvatar(String userId, String imagePath) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mock implementation - return a mock URL
    return 'https://example.com/avatars/$userId.jpg';
  }

  // Helper methods for testing
  static void addMockUser(AppUser user) {
    _users.add(user);
  }

  static void clearMockData() {
    _users.clear();
  }
}
