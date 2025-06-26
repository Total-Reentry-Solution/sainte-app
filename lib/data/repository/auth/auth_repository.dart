import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reentry/core/config/supabase_config.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/repository/auth/auth_repository_interface.dart';
import 'package:reentry/exception/app_exceptions.dart';
import '../../../domain/usecases/auth/login_usecase.dart';

class AuthRepository extends AuthRepositoryInterface {
  final _supabase = SupabaseConfig.client;

  @override
  Future<UserDto> appleSignIn() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        Provider.apple,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
      );
      
      if (response.user == null) {
        throw BaseExceptions('Apple sign in failed');
      }
      
      // Get or create user profile
      final userProfile = await _getOrCreateUserProfile(response.user!);
      return userProfile;
    } catch (e) {
      throw BaseExceptions('Apple sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<UserDto> createAccount(UserDto createAccount) async {
    try {
      if (createAccount.userId == null) {
        throw BaseExceptions('Unable to create account - no user ID');
      }
      
      final userCode = DateTime.now().millisecondsSinceEpoch.toString();
      final data = createAccount.copyWith(
        userId: createAccount.userId,
        createdAt: DateTime.now(),
        userCode: userCode,
        updatedAt: DateTime.now(),
      );

      await _supabase
          .from('user_profiles')
          .insert(data.toJson());

      return data;
    } catch (e) {
      throw BaseExceptions('Failed to create account: ${e.toString()}');
    }
  }

  Future<UserDto?> findUserById(String id) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', id)
          .single();
      
      if (response != null) {
        return UserDto.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UserDto> googleSignIn() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        Provider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
      );
      
      if (response.user == null) {
        throw BaseExceptions('Google sign in failed');
      }
      
      // Get or create user profile
      final userProfile = await _getOrCreateUserProfile(response.user!);
      return userProfile;
    } catch (e) {
      throw BaseExceptions('Google sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<LoginResponse?> login({
    required String email, 
    required String password
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      final authUser = response.user;
      if (authUser == null) {
        throw BaseExceptions('Account not found');
      }
      
      final userId = authUser.id;
      final user = await findUserById(userId);

      if (user?.deleted ?? false) {
        throw BaseExceptions('Your account has been deleted');
      }
      
      return LoginResponse(authUser.id, user);
    } on AuthException catch (e) {
      String errorMessage = 'Something went wrong';
      
      switch (e.message) {
        case 'Invalid login credentials':
          errorMessage = 'Invalid email or password';
          break;
        case 'Email not confirmed':
          errorMessage = 'Please confirm your email address';
          break;
        case 'User not found':
          errorMessage = 'No user found for that email';
          break;
        default:
          errorMessage = e.message ?? 'Authentication failed';
      }
      
      throw BaseExceptions(errorMessage);
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }

  @override
  Future<void> updateUser(UserDto payload) async {
    try {
      await _supabase
          .from('user_profiles')
          .update(payload.toJson())
          .eq('id', payload.userId);
    } catch (e) {
      throw BaseExceptions('Failed to update user: ${e.toString()}');
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://reset-password/',
      );
    } catch (e) {
      throw BaseExceptions('Failed to send password reset email: ${e.toString()}');
    }
  }

  @override
  Future<User?> createAccountWithEmailAndPassword({
    required String email, 
    required String password
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      return response.user;
    } on AuthException catch (e) {
      String error = 'Something went wrong';
      
      switch (e.message) {
        case 'Password should be at least 6 characters':
          error = 'The password provided is too weak';
          break;
        case 'User already registered':
          error = 'The account already exists for that email';
          break;
        case 'Invalid email':
          error = 'Please provide a valid email address';
          break;
        default:
          error = e.message ?? 'Failed to create account';
      }
      
      throw BaseExceptions(error);
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }

  // Helper method to get or create user profile
  Future<UserDto> _getOrCreateUserProfile(User user) async {
    try {
      // Try to get existing profile
      final existingProfile = await findUserById(user.id);
      if (existingProfile != null) {
        return existingProfile;
      }
      
      // Create new profile if doesn't exist
      final newProfile = UserDto(
        userId: user.id,
        email: user.email ?? '',
        firstName: user.userMetadata?['full_name']?.split(' ').first ?? '',
        lastName: user.userMetadata?['full_name']?.split(' ').last ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userCode: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      
      await _supabase
          .from('user_profiles')
          .insert(newProfile.toJson());
      
      return newProfile;
    } catch (e) {
      throw BaseExceptions('Failed to get or create user profile: ${e.toString()}');
    }
  }

  // Sign out method
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw BaseExceptions('Failed to sign out: ${e.toString()}');
    }
  }

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;
  
  // Get current user
  User? get currentUser => _supabase.auth.currentUser;
  
  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
