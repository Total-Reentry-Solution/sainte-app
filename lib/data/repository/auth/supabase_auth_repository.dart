import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reentry/core/config/supabase_config.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/repository/auth/auth_repository_interface.dart';
import 'package:reentry/exception/app_exceptions.dart';

class SupabaseAuthRepository extends AuthRepositoryInterface {
  final _supabase = SupabaseConfig.client;

  @override
  Future<UserDto> appleSignIn() async {
    try {
      final response = await _supabase.auth.signInWithApple();
      if (response.user == null) {
        throw BaseExceptions('Failed to sign in with Apple');
      }
      return UserDto(
        userId: response.user!.id,
        email: response.user!.email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }

  @override
  Future<UserDto> createAccount(UserDto createAccount) async {
    try {
      if (createAccount.userId == null) {
        throw BaseExceptions('Unable to create account');
      }

      final response = await _supabase
          .from('users')
          .insert(createAccount.toJson())
          .select()
          .single();

      return UserDto.fromJson(response);
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }

  @override
  Future<UserDto> googleSignIn() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        Provider.google,
        redirectTo: 'io.supabase.sainte://login-callback/',
      );
      
      if (response.user == null) {
        throw BaseExceptions('Failed to sign in with Google');
      }

      return UserDto(
        userId: response.user!.id,
        email: response.user!.email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }

  Future<UserDto?> findUserById(String id) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('user_id', id)
          .single();
      
      return UserDto.fromJson(response);
    } catch (e) {
      return null;
    }
  }
} 