import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/data/repository/admin/admin_repository.dart';
import 'package:reentry/data/repository/auth/auth_repository.dart';
import 'package:reentry/data/repository/user/user_repository.dart';
import 'package:reentry/data/shared/share_preference.dart';
import 'package:reentry/data/shared/keys.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/config/supabase_config.dart';
import '../../../../data/model/user_dto.dart';
import 'package:get_it/get_it.dart';
import 'package:reentry/di/get_it.dart';

class AccountCubit extends Cubit<UserDto?> {
  AccountCubit() : super(null);

  Future<void> getCurrentUser() async {
    try {
      final currentUser = SupabaseConfig.currentUser;
      if (currentUser != null) {
        final user = await UserRepository().getUserById(currentUser.id);
        emit(user);
      } else {
        emit(null);
      }
    } catch (e) {
      print('Error getting current user: $e');
      emit(null);
    }
  }

  Future<void> updateProfilePhoto(String photoUrl) async {
    try {
      final currentState = state;
      if (currentState != null) {
        final updatedUser = currentState.copyWith(avatar: photoUrl);
        await UserRepository().updateUser(updatedUser);
        emit(updatedUser);
      }
    } catch (e) {
      print('Error updating profile photo: $e');
    }
  }

  Future<void> updateUser(UserDto user) async {
    try {
      await UserRepository().updateUser(user);
      emit(user);
    } catch (e) {
      print('Error updating user: $e');
    }
  }

  Future<void> logout() async {
    try {
      await SupabaseConfig.signOut();
      await PersistentStorage.logout();
      emit(null);
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Additional methods that are being called in the app
  Future<void> readFromLocalStorage() async {
    try {
      final pref = await locator.getAsync<PersistentStorage>();
      final userData = pref.getDataFromCache(Keys.user);
      if (userData != null) {
        final user = UserDto.fromJson(userData);
        emit(user);
      }
    } catch (e) {
      print('Error reading from local storage: $e');
    }
  }

  Future<void> loadFromCloud() async {
    await getCurrentUser();
  }

  Future<void> forceRefreshFromDatabase() async {
    try {
      final currentUser = SupabaseConfig.currentUser;
      if (currentUser != null) {
        final user = await UserRepository().getUserById(currentUser.id);
        if (user != null) {
          // Update local storage with fresh data
          final pref = await locator.getAsync<PersistentStorage>();
          await pref.cacheData(data: user.toJson(), key: Keys.user);
          emit(user);
        }
      }
    } catch (e) {
      print('Error forcing refresh from database: $e');
    }
  }

  Future<void> init() async {
    await readFromLocalStorage();
    await loadFromCloud();
  }

  Future<void> setAccount(UserDto user) async {
    try {
      final pref = await locator.getAsync<PersistentStorage>();
      await pref.cacheData(data: user.toJson(), key: Keys.user);
      emit(user);
    } catch (e) {
      print('Error setting account: $e');
    }
  }

  Future<void> fetchUsers() async {
    // This method is called but doesn't seem to be implemented in the original
    // For now, we'll just get the current user
    await getCurrentUser();
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      final currentState = state;
      if (currentState != null) {
        final updatedUser = currentState.copyWith(settings: UserSettings.fromJson(settings));
        await UserRepository().updateUser(updatedUser);
        emit(updatedUser);
      }
    } catch (e) {
      print('Error updating settings: $e');
    }
  }

  Future<String> uploadFile(dynamic file) async {
    try {
      // This would typically upload to Supabase storage
      // For now, return a placeholder
      return 'https://placeholder.com/image.jpg';
    } catch (e) {
      print('Error uploading file: $e');
      return '';
    }
  }
}
