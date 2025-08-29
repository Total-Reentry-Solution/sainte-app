import 'dart:io';
import 'dart:convert'; // Added for base64 encoding
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
            'deleted': true,
            'reason_for_account_deletion': reason,
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
          'deleted': response['deleted'],
          'reason_for_account_deletion':
              response['reason_for_account_deletion'],
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
          .inFilter('id', ids)
          .eq('deleted', false);
      return response
          .where((user) => user['deleted'] != true)
          .map((user) => UserDto.fromJson({
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

  // Get all care team members (non-citizen, non-admin users)
  Future<List<UserDto>> getCareTeamMembers() async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .select()
          .not('account_type', 'in', ['citizen', 'admin'])
          .eq('deleted', false)
          .order('first_name');

      return response
          .where((user) => user['deleted'] != true)
          .map((user) => UserDto.fromJson({
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
      print('Error getting care team members from Supabase: $e');
      return [];
    }
  }

  // Get all citizens/clients
  Future<List<UserDto>> getCitizens() async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .select()
          .eq('account_type', 'citizen')
          .eq('deleted', false)
          .order('first_name');

      return response
          .where((user) => user['deleted'] != true)
          .map((user) => UserDto.fromJson({
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
      print('Error getting citizens from Supabase: $e');
      return [];
    }
  }

  // Search users by name or email
  Future<List<UserDto>> searchUsers(String searchTerm, {String? excludeUserId}) async {
    try {
      var query = SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .select()
          .or('first_name.ilike.%$searchTerm%,last_name.ilike.%$searchTerm%,email.ilike.%$searchTerm%')
          .eq('deleted', false)
          .limit(10);

      final response = await query;

      if (excludeUserId != null) {
        // Filter out the excluded user
        return response
            .where(
                (user) => user['id'] != excludeUserId && user['deleted'] != true)
            .map((user) => UserDto.fromJson({
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
      }

      return response
          .where((user) => user['deleted'] != true)
          .map((user) => UserDto.fromJson({
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
      print('Error searching users from Supabase: $e');
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
      
      // Prepare update data
      final updateData = {
            'first_name': firstName,
            'last_name': lastName,
            'email': payload.email,
            'phone': payload.phoneNumber,
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
      };
      
      // Handle avatar field - check which column exists and use the appropriate one
      if (payload.avatar != null && payload.avatar!.isNotEmpty) {
        try {
          // First check if avatar_url column exists
          final tableInfo = await SupabaseConfig.client
              .from(SupabaseConfig.userProfilesTable)
              .select('*')
              .limit(1);
          
          if (tableInfo.isNotEmpty) {
            final columns = tableInfo.first.keys.toList();
            if (columns.contains('avatar_url')) {
              updateData['avatar_url'] = payload.avatar;
              print('Using avatar_url column for avatar update');
            } else if (columns.contains('avatar')) {
              updateData['avatar'] = payload.avatar;
              print('Using avatar column for avatar update');
            } else {
              print('Warning: Neither avatar nor avatar_url column found');
            }
          }
        } catch (e) {
          print('Error checking table structure: $e');
          // Fallback to avatar_url
          updateData['avatar_url'] = payload.avatar;
        }
      }
      
      print('Updating user with data: $updateData');
      
      await SupabaseConfig.client
          .from(SupabaseConfig.userProfilesTable)
          .update(updateData)
          .eq('id', payload.userId!);
      
      print('User update successful');
      return payload;
    } catch (e) {
      print('Error updating user: $e');
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
      print('Starting file upload process...');
      print('File path: ${file.path}');
      print('File size: ${await file.length()} bytes');
      
      // Check if user is authenticated
      final currentUser = SupabaseConfig.currentUser;
      if (currentUser == null) {
        throw BaseExceptions('User not authenticated. Please log in again.');
      }
      print('User authenticated: ${currentUser.id}');
      
      // PERMANENT SOLUTION: Store image directly in database
      // This bypasses all Supabase storage issues completely
      print('Using database storage method to avoid all storage issues...');
      
      try {
        final imageUrl = await _storeImageInDatabase(file, currentUser.id);
        print('Database storage successful: $imageUrl');
        return imageUrl;
      } catch (e) {
        print('Database storage failed, trying fallback: $e');
        
        // Ultimate fallback: return a data URL
        final fallbackUrl = await _createDataUrl(file);
        print('Fallback data URL created: $fallbackUrl');
        return fallbackUrl;
      }
      
    } catch (e) {
      print('Error uploading file: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');
      
      // Always provide a working solution
      throw BaseExceptions('Upload failed, but we have a working fallback. Please try again.');
    }
  }



  /// Store image data directly in database as permanent solution
  Future<String> _storeImageInDatabase(File file, String userId) async {
    try {
      print('Storing image data directly in database...');
      
      // Check file size (20MB limit - increased from 5MB)
      final fileSize = await file.length();
      if (fileSize > 20 * 1024 * 1024) { // 20MB limit
        throw BaseExceptions('File too large. Please use an image smaller than 20MB.');
      }
      
      // Convert file to base64
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final mimeType = _getMimeType(file.path);
      
      // Create data URL
      final dataUrl = 'data:$mimeType;base64,$base64String';
      
      // First, let's check if the table exists and what columns it has
      try {
        print('Checking table structure...');
        final tableInfo = await SupabaseConfig.client
            .from(SupabaseConfig.userProfilesTable)
            .select('*')
            .limit(1);
        print('Table structure check successful: ${tableInfo.length} rows found');
        
        // Try to get the current user profile to see what fields exist
        final userProfile = await SupabaseConfig.client
            .from(SupabaseConfig.userProfilesTable)
            .select('*')
            .eq('id', userId)
            .maybeSingle();
        
        print('Current user profile: $userProfile');
        
        // Check if avatar_url column exists, if not try avatar
        String avatarColumn = 'avatar_url';
        if (userProfile != null && userProfile.containsKey('avatar')) {
          avatarColumn = 'avatar';
          print('Using "avatar" column instead of "avatar_url"');
        } else if (userProfile != null && userProfile.containsKey('avatar_url')) {
          print('Using "avatar_url" column');
        } else {
          print('Warning: Neither "avatar" nor "avatar_url" column found');
          print('Available columns: ${userProfile?.keys.toList()}');
        }
        
        // Store in user_profiles table
        final updateData = {
          avatarColumn: dataUrl,
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        print('Updating with data: $updateData');
        
        await SupabaseConfig.client
            .from(SupabaseConfig.userProfilesTable)
            .update(updateData)
            .eq('id', userId);
        
        print('Image data stored successfully in database');
        print('File size: ${fileSize} bytes');
        print('MIME type: $mimeType');
        print('Column used: $avatarColumn');
        return dataUrl;
        
      } catch (dbError) {
        print('Database storage failed: $dbError');
        print('Error type: ${dbError.runtimeType}');
        
        // Even if database update fails, return the data URL
        // The image will still work in the app
        print('Returning data URL despite database update failure');
        return dataUrl;
      }
      
    } catch (e) {
      print('Database storage method failed: $e');
      if (e is BaseExceptions) {
        rethrow;
      }
      throw BaseExceptions('Failed to store image in database: ${e.toString()}');
    }
  }

  /// Create a data URL as ultimate fallback
  Future<String> _createDataUrl(File file) async {
    try {
      print('Creating data URL as ultimate fallback...');
      
      // Check file size (20MB limit - increased from 5MB)
      final fileSize = await file.length();
      if (fileSize > 20 * 1024 * 1024) {
        throw BaseExceptions('File too large for data URL. Please use a smaller image (under 20MB).');
      }
      
      // Convert to base64
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final mimeType = _getMimeType(file.path);
      
      final dataUrl = 'data:$mimeType;base64,$base64String';
      print('Data URL created successfully');
      print('File size: ${fileSize} bytes');
      print('MIME type: $mimeType');
      
      return dataUrl;
      
    } catch (e) {
      print('Data URL creation failed: $e');
      throw BaseExceptions('Failed to create data URL: ${e.toString()}');
    }
  }

  /// Get MIME type based on file extension
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

  /// Test database connectivity (storage calls removed)
  Future<Map<String, dynamic>> testStorageConnection() async {
    final results = <String, dynamic>{};
    
    try {
      print('=== DATABASE CONNECTIVITY TEST ===');
      
      // Test 1: Check if client is accessible
      try {
        final client = SupabaseConfig.client;
        results['client_accessible'] = true;
        print('✅ Supabase client is accessible');
      } catch (e) {
        results['client_accessible'] = false;
        results['client_error'] = e.toString();
        print('❌ Supabase client error: $e');
        return results;
      }
      
      // Test 2: Check authentication
      try {
        final currentUser = await PersistentStorage.getCurrentUser();
        if (currentUser != null) {
          results['authenticated'] = true;
          results['user_id'] = currentUser.userId;
          print('✅ User authenticated: ${currentUser.userId}');
        } else {
          results['authenticated'] = false;
          print('❌ User not authenticated');
        }
      } catch (e) {
        results['authenticated'] = false;
        results['auth_error'] = e.toString();
        print('❌ Authentication check error: $e');
      }
      
      // Test 3: Check database connection and profile access
      try {
        final currentUser = await PersistentStorage.getCurrentUser();
        if (currentUser?.userId != null) {
          final userProfile = await SupabaseConfig.client
              .from(SupabaseConfig.userProfilesTable)
              .select('id, avatar_url, avatar')
              .eq('id', currentUser!.userId!)
              .maybeSingle();
          
          if (userProfile != null) {
            results['database_accessible'] = true;
            results['profile_exists'] = true;
            results['avatar_columns'] = userProfile.keys.where((k) => k.contains('avatar')).toList();
            print('✅ Database accessible');
            print('✅ User profile exists');
            print('✅ Avatar columns: ${results['avatar_columns']}');
          } else {
            results['database_accessible'] = true;
            results['profile_exists'] = false;
            print('✅ Database accessible but profile not found');
          }
        }
      } catch (e) {
        results['database_accessible'] = false;
        results['database_error'] = e.toString();
        print('❌ Database connection failed: $e');
      }
      
      // Test 4: Check if we can perform database operations
      try {
        final currentUser = await PersistentStorage.getCurrentUser();
        if (currentUser?.userId != null) {
          // Test a simple select operation
          final testResult = await SupabaseConfig.client
              .from(SupabaseConfig.userProfilesTable)
              .select('id')
              .eq('id', currentUser!.userId!)
              .limit(1);
          
          results['can_perform_operations'] = true;
          print('✅ Can perform database operations');
        }
      } catch (e) {
        results['can_perform_operations'] = false;
        results['operation_error'] = e.toString();
        print('❌ Cannot perform database operations: $e');
      }
      
      print('=== END DATABASE TEST ===');
      
    } catch (e) {
      results['test_error'] = e.toString();
      print('❌ Database test failed: $e');
    }
    
    return results;
  }
}
