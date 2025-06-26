import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reentry/core/config/supabase_config.dart';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/data/model/client_dto.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/repository/clients/client_repository.dart';
import 'package:reentry/data/repository/user/user_repository_interface.dart';
import 'package:reentry/data/shared/share_preference.dart';
import 'package:reentry/exception/app_exceptions.dart';

class UserRepository extends UserRepositoryInterface {
  final _supabase = SupabaseConfig.client;

  @override
  Future<UserDto> getCurrentUser() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw BaseExceptions('No authenticated user');
      }
      
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return UserDto.fromJson(response);
    } catch (e) {
      throw BaseExceptions('Failed to get current user: ${e.toString()}');
    }
  }

  Future<void> deleteAccount(String userId, String reason) async {
    try {
      // Update user profile with deletion reason
      await _supabase
          .from('user_profiles')
          .update({
            'reason_for_account_deletion': reason,
            'deleted': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
      // Delete client record if exists
      await _supabase
          .from('clients')
          .delete()
          .eq('id', userId);
      
      // Delete the auth user
      await _supabase.auth.admin.deleteUser(userId);
    } catch (e) {
      throw BaseExceptions('Failed to delete account: ${e.toString()}');
    }
  }

  @override
  Future<UserDto?> getUserById(String id) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', id)
          .single();
      
      return UserDto.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserDto user) async {
    try {
      final updateData = {
        'first_name': user.firstName,
        'last_name': user.lastName,
        'email': user.email,
        'phone': user.phone,
        'account_type': user.accountType?.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('user_profiles')
          .update(updateData)
          .eq('id', user.userId);
    } catch (e) {
      throw BaseExceptions('Failed to update user profile: ${e.toString()}');
    }
  }

  // Upload profile photo
  Future<String> uploadProfilePhoto(File file) async {
    try {
      final userId = SupabaseConfig.currentUserId ?? 'anonymous';
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await SupabaseConfig.storage
          .from('profile_photos')
          .uploadBinary('$userId/$fileName', await file.readAsBytes());
      
      final url = SupabaseConfig.storage
          .from('profile_photos')
          .getPublicUrl('$userId/$fileName');
      
      // Update user profile with new photo URL
      await _supabase
          .from('user_profiles')
          .update({
            'profile_photo_url': url,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
      return url;
    } catch (e) {
      throw BaseExceptions('Failed to upload profile photo: ${e.toString()}');
    }
  }

  // Get all users (for admin purposes)
  Future<List<UserDto>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .order('created_at', ascending: false);
      
      return response.map((e) => UserDto.fromJson(e)).toList();
    } catch (e) {
      throw BaseExceptions('Failed to fetch users: ${e.toString()}');
    }
  }

  // Get users by account type
  Future<List<UserDto>> getUsersByAccountType(AccountType accountType) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('account_type', accountType.name)
          .order('created_at', ascending: false);
      
      return response.map((e) => UserDto.fromJson(e)).toList();
    } catch (e) {
      throw BaseExceptions('Failed to fetch users by account type: ${e.toString()}');
    }
  }

  // Search users
  Future<List<UserDto>> searchUsers(String query) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .or('first_name.ilike.%$query%,last_name.ilike.%$query%,email.ilike.%$query%')
          .order('created_at', ascending: false);
      
      return response.map((e) => UserDto.fromJson(e)).toList();
    } catch (e) {
      throw BaseExceptions('Failed to search users: ${e.toString()}');
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final totalUsers = await _supabase
          .from('user_profiles')
          .select('id', const FetchOptions(count: CountOption.exact));
      
      final activeUsers = await _supabase
          .from('user_profiles')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('deleted', false);
      
      final newUsersThisMonth = await _supabase
          .from('user_profiles')
          .select('id', const FetchOptions(count: CountOption.exact))
          .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());
      
      return {
        'total_users': totalUsers.count ?? 0,
        'active_users': activeUsers.count ?? 0,
        'new_users_this_month': newUsersThisMonth.count ?? 0,
      };
    } catch (e) {
      throw BaseExceptions('Failed to get user statistics: ${e.toString()}');
    }
  }

  // Create client record
  Future<void> createClient(ClientDto client) async {
    try {
      await _supabase
          .from('clients')
          .insert(client.toJson());
    } catch (e) {
      throw BaseExceptions('Failed to create client: ${e.toString()}');
    }
  }

  // Get client by user ID
  Future<ClientDto?> getClientByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('clients')
          .select()
          .eq('id', userId)
          .single();
      
      return ClientDto.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Update client
  Future<void> updateClient(ClientDto client) async {
    try {
      await _supabase
          .from('clients')
          .update(client.toJson())
          .eq('id', client.id);
    } catch (e) {
      throw BaseExceptions('Failed to update client: ${e.toString()}');
    }
  }

  // Get all clients
  Future<List<ClientDto>> getAllClients() async {
    try {
      final response = await _supabase
          .from('clients')
          .select('*, user_profiles!clients_id_fkey(*)')
          .order('created_at', ascending: false);
      
      return response.map((e) => ClientDto.fromJson(e)).toList();
    } catch (e) {
      throw BaseExceptions('Failed to fetch clients: ${e.toString()}');
    }
  }
}
