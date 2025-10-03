import 'auth_repository_interface.dart';
import '../../model/user.dart';
import '../../enum/account_type.dart';

// Mock Auth Repository - Clean implementation with mock data
class MockAuthRepository implements AuthRepositoryInterface {
  static AppUser? _currentUser;
  static final List<AppUser> _users = [];

  @override
  Future<AppUser?> signInWithEmail(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Find user by email
    final user = _users.firstWhere(
      (u) => u.email == email,
      orElse: () => throw Exception('User not found'),
    );
    
    _currentUser = user;
    return user;
  }

  @override
  Future<AppUser?> signUpWithEmail(String email, String password, String firstName, String lastName) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check if user already exists
    if (_users.any((u) => u.email == email)) {
      throw Exception('User already exists');
    }
    
    // Create new user
    final newUser = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      firstName: firstName,
      lastName: lastName,
      accountType: AccountType.citizen,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _users.add(newUser);
    _currentUser = newUser;
    return newUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentUser;
  }

  @override
  Future<AppUser?> updateUser(AppUser user) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
      if (_currentUser?.id == user.id) {
        _currentUser = user;
      }
      return user;
    }
    return null;
  }

  @override
  Future<void> deleteUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _users.removeWhere((u) => u.id == userId);
    if (_currentUser?.id == userId) {
      _currentUser = null;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock implementation - just simulate success
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock implementation - just simulate success
  }

  @override
  Future<void> sendVerificationEmail() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock implementation - just simulate success
  }

  @override
  Future<bool> verifyEmail(String token) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock implementation - always return true
    return true;
  }

  // Helper method to add mock users for testing
  static void addMockUser(AppUser user) {
    _users.add(user);
  }

  // Helper method to clear all mock data
  static void clearMockData() {
    _users.clear();
    _currentUser = null;
  }
}
