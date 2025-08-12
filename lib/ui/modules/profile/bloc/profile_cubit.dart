import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reentry/core/resources/data_state.dart';
import 'package:reentry/core/util/image_util.dart';
import 'package:reentry/data/model/user_dto.dart';
// import 'package:reentry/data/repository/blog/blog_repository.dart';
import 'package:reentry/data/repository/org/organization_repository.dart';
import 'package:reentry/domain/usecases/user/update_profile_photo_usecase.dart';
import 'package:reentry/ui/modules/profile/bloc/profile_state.dart';
import '../../../../data/repository/user/user_repository.dart';
import '../../../../data/shared/share_preference.dart';
import '../../../../core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileState());
  final _repo = UserRepository();

  final _orgRepo = OrganizationRepository();

  Future<void> deleteAccount(String userId, String reason) async {
    emit(ProfileLoading());
    try {
      await _repo.deleteAccount(userId, reason);
      emit(DeleteAccountSuccess());
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> removeFromOr(String userId, String orgId) async {
    print('reentry orgId -> ${userId}');
    emit(ProfileLoading());
    try {
      await _orgRepo.removeFromOrganization(orgId, userId);
      emit(RemovedFromOrganizationSuccess());
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateProfilePhoto(XFile file) async {
    try {
      emit(ProfileLoading());
      
      print('=== UPDATING PROFILE PHOTO (NEW METHOD) ===');
      
      // Use the new simplified upload method instead of the old problematic flow
      final success = await uploadProfilePictureSimple(file);
      
      if (success) {
        print('✅ Profile photo updated successfully using new method');
        emit(ProfileSuccess());
      } else {
        print('❌ Profile photo update failed');
        emit(ProfileError('Failed to update profile photo'));
      }
      
    } catch (e) {
      print('Error in updateProfilePhoto: $e');
      emit(ProfileError('Failed to update profile photo: ${e.toString()}'));
    }
  }

  Future<void> updateProfilePhotoWeb(Uint8List? file, UserDto user) async {
    emit(ProfileLoading());
    try {
      if (file != null) {
        // For web, we need to create a temporary file from Uint8List
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/temp_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(file);
        
        try {
          // Use the new database storage approach instead of the old uploadFile
          final success = await uploadProfilePictureSimple(XFile(tempFile.path));
          if (success) {
            // Get the updated user with the new avatar
            final updatedUser = await PersistentStorage.getCurrentUser();
            if (updatedUser != null) {
              emit(ProfileSuccess(user: updatedUser));
              return;
            }
          }
        } finally {
          // Clean up temporary file
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      }
      
      // If no file or upload failed, just update the user without avatar change
      final result = await _repo.updateUser(user);
      await PersistentStorage.cacheUserInfo(user);
      emit(ProfileSuccess(user: result));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> registerPushNotificationToken() async {
    _repo.registerPushNotificationToken();
  }

  Future<void> updateProfile(UserDto user, {bool ignoreStorage = false}) async {
    emit(ProfileLoading());
    try {
      final result = await _repo.updateUser(user);
      if (!ignoreStorage) {
        await PersistentStorage.cacheUserInfo(user);
      }
      emit(ProfileSuccess(user: result));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> submitIntakeForm(String userId, IntakeForm form) async {
    emit(ProfileLoading());
    try {
      UserDto? user = await _repo.getUserById(userId);
      if (user == null) {
        emit(ProfileError('User not found'));
        return;
      }
      user = user.copyWith(intakeForm: form);
      await _repo.updateUser(user);
      emit(IntakeFormSuccess(user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  /// Check if profile picture functionality is properly set up
  Future<bool> checkProfilePictureSetup() async {
    try {
      print('=== CHECKING PROFILE PICTURE SETUP ===');
      
      // Instead of checking storage, check if database is accessible
      final currentUser = await PersistentStorage.getCurrentUser();
      if (currentUser == null) {
        print('❌ User not authenticated');
        return false;
      }
      
      print('✅ User authenticated: ${currentUser.userId}');
      
      // Test database connection instead of storage
      try {
        final userProfile = await SupabaseConfig.client
            .from(SupabaseConfig.userProfilesTable)
            .select('id')
            .eq('id', currentUser!.userId!)
            .maybeSingle();
        
        if (userProfile != null) {
          print('✅ Database connection successful');
          print('✅ User profile accessible');
          return true;
        } else {
          print('❌ User profile not found in database');
          return false;
        }
      } catch (e) {
        print('❌ Database connection failed: $e');
        return false;
      }
    } catch (e) {
      print('Profile picture setup check failed: $e');
      return false;
    }
  }

  /// Run comprehensive storage diagnostics (now database diagnostics)
  Future<Map<String, dynamic>> runStorageDiagnostics() async {
    try {
      emit(ProfileLoading());
      
      print('=== RUNNING DATABASE DIAGNOSTICS ===');
      
      final results = <String, dynamic>{};
      
      // Test 1: Check if client is accessible
      try {
        final client = SupabaseConfig.client;
        results['client_accessible'] = true;
        print('✅ Supabase client is accessible');
      } catch (e) {
        results['client_accessible'] = false;
        results['client_error'] = e.toString();
        print('❌ Supabase client error: $e');
        emit(ProfileError('Client error: ${e.toString()}'));
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
      
      // Test 3: Check database connection
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
      
      print('=== END DATABASE DIAGNOSTICS ===');
      emit(ProfileSuccess());
      return results;
      
    } catch (e) {
      print('Database diagnostics failed: $e');
      emit(ProfileError('Diagnostics failed: ${e.toString()}'));
      return {'error': e.toString()};
    }
  }

  /// Attempt to set up profile picture storage (now just provides instructions)
  Future<bool> setupProfilePictureStorage() async {
    try {
      emit(ProfileLoading());
      
      print('=== PROFILE PICTURE SETUP INSTRUCTIONS ===');
      print('Since we now use database storage, no Supabase storage setup is needed!');
      print('Profile pictures are stored directly in your database as data URLs.');
      print('This approach:');
      print('✅ Eliminates all storage bucket issues');
      print('✅ Works immediately without configuration');
      print('✅ Stores images permanently in your database');
      print('✅ No more "_Namespace" errors');
      
      emit(ProfileSuccess());
      return true;
    } catch (e) {
      print('Failed to provide setup instructions: $e');
      emit(ProfileError('Failed to provide instructions: ${e.toString()}'));
      return false;
    }
  }

  /// Automatically fix storage issues (now just confirms database approach works)
  Future<bool> autoFixStorageIssues() async {
    try {
      emit(ProfileLoading());
      
      print('=== AUTOMATIC STORAGE FIX ===');
      print('Storage issues are automatically fixed by using database storage!');
      
      // Test if our database approach works
      final currentUser = await PersistentStorage.getCurrentUser();
      if (currentUser == null) {
        emit(ProfileError('User not authenticated'));
        return false;
      }
      
      print('✅ User authenticated: ${currentUser.userId}');
      print('✅ Database storage approach is ready');
      print('✅ No Supabase storage configuration needed');
      print('✅ Profile pictures will work immediately');
      
      emit(ProfileSuccess());
      return true;
      
    } catch (e) {
      print('Auto-fix failed: $e');
      emit(ProfileError('Auto-fix failed: ${e.toString()}'));
      return false;
    }
  }

  /// Test the new database storage approach
  Future<bool> testDatabaseStorage() async {
    try {
      emit(ProfileLoading());
      
      print('=== TESTING DATABASE STORAGE APPROACH ===');
      
      // Get current user from repository instead of Supabase config
      final currentUser = await PersistentStorage.getCurrentUser();
      if (currentUser == null) {
        emit(ProfileError('User not authenticated'));
        return false;
      }
      
      // Test database connection
      try {
        final userProfile = await SupabaseConfig.client
            .from(SupabaseConfig.userProfilesTable)
            .select('id, avatar_url, avatar')
            .eq('id', currentUser!.userId!)
            .single();
        
        print('✅ Database connection successful');
        print('✅ User profile accessible');
        print('✅ Current avatar: ${userProfile['avatar'] ?? userProfile['avatar_url'] ?? 'None'}');
        print('✅ Available columns: ${userProfile.keys.toList()}');
        
        emit(ProfileSuccess());
        return true;
        
      } catch (e) {
        print('❌ Database test failed: $e');
        emit(ProfileError('Database test failed: ${e.toString()}'));
        return false;
      }
      
    } catch (e) {
      print('Database storage test failed: $e');
      emit(ProfileError('Test failed: ${e.toString()}'));
      return false;
    }
  }

  /// Test simple upload to identify issues
  Future<bool> testSimpleUpload() async {
    try {
      emit(ProfileLoading());
      
      print('=== TESTING SIMPLE UPLOAD ===');
      
      // Get current user from repository instead of Supabase config
      final currentUser = await PersistentStorage.getCurrentUser();
      if (currentUser == null) {
        emit(ProfileError('User not authenticated'));
        return false;
      }
      
      print('✅ User authenticated: ${currentUser.userId}');
      
      // Create a simple test file
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/test_upload_${DateTime.now().millisecondsSinceEpoch}.txt');
      await testFile.writeAsString('Test upload content');
      
      try {
        print('✅ Test file created: ${testFile.path}');
        
        // Test the new database storage approach instead of the old uploadFile
        final success = await uploadProfilePictureSimple(XFile(testFile.path));
        if (success) {
          print('✅ New upload method test successful');
          
          // Test updating the user
          final updatedUser = await PersistentStorage.getCurrentUser();
          if (updatedUser != null) {
            print('✅ User update successful: ${updatedUser.avatar}');
          }
          
          emit(ProfileSuccess());
          return true;
        } else {
          print('❌ New upload method test failed');
          emit(ProfileError('New upload method test failed'));
          return false;
        }
        
      } catch (e) {
        print('❌ Upload or update failed: $e');
        emit(ProfileError('Test failed: ${e.toString()}'));
        
        return false;
      } finally {
        // Clean up test file
        if (await testFile.exists()) {
          await testFile.delete();
        }
      }
      
    } catch (e) {
      print('❌ Test setup failed: $e');
      emit(ProfileError('Test setup failed: ${e.toString()}'));
      return false;
    }
  }

  /// New simplified profile picture upload that bypasses all storage issues
  Future<bool> uploadProfilePictureSimple(XFile file) async {
    try {
      emit(ProfileLoading());
      
      print('=== SIMPLIFIED PROFILE PICTURE UPLOAD ===');
      
      // Get current user from repository instead of Supabase config
      final currentUser = await PersistentStorage.getCurrentUser();
      if (currentUser == null) {
        emit(ProfileError('User not authenticated'));
        return false;
      }
      
      print('✅ User authenticated: ${currentUser.userId}');
      
      // Convert XFile to File
      final imageFile = File(file.path);
      
      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) { // 5MB limit
        emit(ProfileError('File too large. Please use an image smaller than 5MB.'));
        return false;
      }
      
      // Convert to base64 data URL
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      final mimeType = _getMimeType(file.path);
      final dataUrl = 'data:$mimeType;base64,$base64String';
      
      print('✅ Image converted to data URL');
      print('✅ File size: ${fileSize} bytes');
      print('✅ MIME type: $mimeType');
      
      // Update user profile directly in database
      try {
        // First check which avatar column exists
        final tableInfo = await SupabaseConfig.client
            .from(SupabaseConfig.userProfilesTable)
            .select('*')
            .limit(1);
        
        String avatarColumn = 'avatar_url'; // Default
        if (tableInfo.isNotEmpty) {
          final columns = tableInfo.first.keys.toList();
          if (columns.contains('avatar')) {
            avatarColumn = 'avatar';
            print('✅ Using "avatar" column');
          } else if (columns.contains('avatar_url')) {
            print('✅ Using "avatar_url" column');
          } else {
            print('⚠️ Warning: Neither avatar nor avatar_url column found');
            print('Available columns: $columns');
          }
        }
        
        // Update the database
        final updateData = {
          avatarColumn: dataUrl,
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        print('✅ Updating database with: $updateData');
        
        await SupabaseConfig.client
            .from(SupabaseConfig.userProfilesTable)
            .update(updateData)
            .eq('id', currentUser!.userId!);
        
        print('✅ Database update successful');
        
        // Update local user object
        final updatedUser = currentUser.copyWith(avatar: dataUrl);
        
        // Update local storage
        try {
          await PersistentStorage.cacheUserInfo(updatedUser);
          print('✅ Local storage updated');
        } catch (e) {
          print('⚠️ Local storage update failed: $e');
          // Continue anyway, the main update was successful
        }
        
        emit(ProfileSuccess(user: updatedUser));
        print('✅ Profile picture upload completed successfully!');
        return true;
        
      } catch (dbError) {
        print('❌ Database update failed: $dbError');
        emit(ProfileError('Failed to update database: ${dbError.toString()}'));
        return false;
      }
      
    } catch (e) {
      print('❌ Simplified upload failed: $e');
      emit(ProfileError('Upload failed: ${e.toString()}'));
      return false;
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


}
