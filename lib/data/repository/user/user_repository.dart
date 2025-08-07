import 'dart:io';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/data/model/client_dto.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/repository/clients/client_repository.dart';
import 'package:reentry/data/repository/user/user_repository_interface.dart';
import 'package:reentry/data/shared/share_preference.dart';
import 'package:reentry/exception/app_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/config/supabase_config.dart';

class UserRepository extends UserRepositoryInterface {

  @override
  Future<UserDto> getCurrentUser() {
    // TODO: implement getCurrentUser
    throw UnimplementedError();
  }

  Future<void> deleteAccount(String userId, String reason) async {
    try {
      await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .update({
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      throw BaseExceptions('Failed to delete account:  [${e.toString()}');
    }
  }

  @override
  Future<UserDto?> getUserById(String id) async {
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
          'address': response['address'],
          'account_type': response['account_type'],
          'organizations': response['organizations'],
          'organization': response['organization'],
          'organization_address': response['organization_address'],
          'job_title': response['job_title'],
          'supervisors_name': response['supervisors_name'],
          'supervisors_email': response['supervisors_email'],
          'services': response['services'],
          'created_at': response['created_at'],
          'updated_at': response['updated_at'],
        });
      }
      return null;
    } catch (e) {
      print('Error getting user from Supabase: $e');
      return null;
    }
  }

  Future<List<UserDto>> getUsersByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return [];
    }
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .select()
          .inFilter('id', ids);
      return response.map((user) => UserDto.fromJson({
        'id': user['id'],
        'email': user['email'],
        'name': '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
        'phoneNumber': user['phone'],
        'avatar': user['avatar_url'],
        'address': user['address'],
        'account_type': user['account_type'],
        'organizations': user['organizations'],
        'organization': user['organization'],
        'organization_address': user['organization_address'],
        'job_title': user['job_title'],
        'supervisors_name': user['supervisors_name'],
        'supervisors_email': user['supervisors_email'],
        'services': user['services'],
        'created_at': user['created_at'],
        'updated_at': user['updated_at'],
      })).toList();
    } catch (e) {
      print('Error getting users from Supabase: $e');
      return [];
    }
  }

 Future<void> registerPushNotificationToken() async {/*
    final user = await PersistentStorage.getCurrentUser();
    if (user == null) {
      throw BaseExceptions('User not found');
    }

    try {
      await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .update({
            'push_notification_token': 'web-token', // Web push token handling
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.userId!);
    } catch (e) {
      throw BaseExceptions('Failed to register push token: ${e.toString()}');
    }*/
    return;
  }
  @override
  Future<UserDto> updateUser(UserDto payload) async {
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
            'email': payload.email,
            'phone': payload.phoneNumber,
            'avatar_url': payload.avatar,
            'address': payload.address,
            'account_type': payload.accountType.name,
            'organizations': payload.organizations,
            'organization': payload.organization,
            'organization_address': payload.organizationAddress,
            'job_title': payload.jobTitle,
            'supervisors_name': payload.supervisorsName,
            'supervisors_email': payload.supervisorsEmail,
            'services': payload.services,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', payload.userId!);
      return payload;
    } catch (e) {
      print(e.toString());
      throw BaseExceptions(e.toString());
    }
  }

  @override
  Future<List<UserDto>> getUserAssignee() async {
    final currentUser = await PersistentStorage.getCurrentUser();
    if (currentUser == null) {
      return [];
    }
    
    try {
      if (currentUser.userId != null) {
        final response = await SupabaseConfig.client
            .from('client_assignees') // You'll need to create this table
            .select('assignee_id')
            .eq('client_id', currentUser.userId!);
        
        if (response.isNotEmpty) {
          final assigneeIds = response.map((e) => e['assignee_id'] as String).toList();
          return await getUsersByIds(assigneeIds);
        }
      }
      return [];
    } catch (e) {
      print('Error getting assignees from Supabase: $e');
      return [];
    }
  }

  @override
  Future<String> uploadFile(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final response = await SupabaseConfig.client.storage
          .from('avatars') // You'll need to create this bucket
          .upload(fileName, file);
      
      final url = SupabaseConfig.client.storage
          .from('avatars')
          .getPublicUrl(fileName);
      
      return url;
    } catch (e) {
      throw BaseExceptions('Failed to upload file: ${e.toString()}');
    }
  }
}
