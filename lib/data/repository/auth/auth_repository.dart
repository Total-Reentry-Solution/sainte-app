import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/repository/auth/auth_repository_interface.dart';
import 'package:reentry/exception/app_exceptions.dart';
import '../../../domain/usecases/auth/login_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/config/supabase_config.dart';

class AuthRepository extends AuthRepositoryInterface {

  @override
  Future<UserDto> appleSignIn() {
    throw UnimplementedError();
  }

  @override
  Future<UserDto> createAccount(UserDto createAccount) async {
    if (createAccount.userId == null) {
      throw BaseExceptions('Unable to create account');
    }
    
    // Create user in Supabase user_profiles table
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .insert({
            'id': createAccount.userId,
            'email': createAccount.email,
            'first_name': createAccount.name?.split(' ').first,
            'last_name': createAccount.name?.split(' ').skip(1).join(' '),
            'phone': createAccount.phoneNumber,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      return createAccount.copyWith(
        userId: response['id'],
        createdAt: DateTime.now(),
        userCode: DateTime.now().millisecondsSinceEpoch.toString(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw BaseExceptions('Failed to create account in Supabase: ${e.toString()}');
    }
  }

  Future<UserDto?> findUserById(String id) async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .select()
          .eq('id', id)
          .single();
      
      if (response != null) {
        return UserDto.fromJson({
          'id': response['id'],
          'email': response['email'],
          'name': '${response['first_name'] ?? ''} ${response['last_name'] ?? ''}'.trim(),
          'phoneNumber': response['phone'],
          'avatar': response['avatar_url'],
          'created_at': response['created_at'],
          'updated_at': response['updated_at'],
        });
      }
      return null;
    } catch (e) {
      print('Error finding user in Supabase: $e');
      return null;
    }
  }

  @override
  Future<UserDto> googleSignIn() async {
    // TODO: implement googleSignIn
    throw UnimplementedError();
  }

  @override
  Future<LoginResponse?> login(
      {required String email, required String password}) async {
    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw BaseExceptions('Account not found');
      }
      final userId = response.user!.id;
      
      // Fetch user data from Supabase user_profiles table
      final user = await findUserById(userId);
      
      return LoginResponse(userId, user);
    } on supabase.AuthException catch (e) {
      throw BaseExceptions(e.message);
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }

  @override
  Future<void> updateUser(UserDto payload) async {
    try {
      if (payload.userId == null) {
        throw BaseExceptions('User ID is required for update');
      }
      final nameParts = payload.name?.split(' ') ?? ['', ''];
      final firstName = nameParts.first;
      final lastName = nameParts.skip(1).join(' ');
      
      await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .update({
            'first_name': firstName,
            'last_name': lastName,
            'phone': payload.phoneNumber,
            'avatar_url': payload.avatar,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', payload.userId!);
      return;
    } catch (e) {
      throw BaseExceptions('Failed to update user: ${e.toString()}');
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }

  @override
  Future<supabase.User?> createAccountWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw BaseExceptions('Account not created');
      }
      
      // User profile will be created automatically by the trigger
      // But we can add additional data if needed
      await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .update({
            'email': email,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', response.user!.id);
      
      return response.user;
    } on supabase.AuthException catch (e) {
      throw BaseExceptions(e.message);
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }
}
