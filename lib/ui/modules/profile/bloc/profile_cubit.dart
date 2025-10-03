import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_state.dart';
import '../../../../data/repository/user/user_repository_interface.dart';
import '../../../../data/repository/auth/auth_repository_interface.dart';

// Clean Profile Cubit
class ProfileCubit extends Cubit<ProfileState> {
  final UserRepositoryInterface _userRepository;
  
  ProfileCubit({
    required UserRepositoryInterface userRepository,
    required AuthRepositoryInterface authRepository,
  }) : _userRepository = userRepository,
       super(ProfileInitial());

  Future<void> loadProfile(String userId) async {
    emit(ProfileLoading());
    
    try {
      final user = await _userRepository.getUserById(userId);
      if (user != null) {
        emit(ProfileLoaded(user));
      } else {
        emit(ProfileError('User not found'));
      }
    } catch (e) {
      emit(ProfileError('Failed to load profile: ${e.toString()}'));
    }
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> profileData) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(ProfileUpdating(currentState.user));
      
      try {
        final updatedUser = await _userRepository.updateUserProfile(userId, profileData);
        if (updatedUser != null) {
          emit(ProfileUpdated(updatedUser));
        } else {
          emit(ProfileUpdateError('Failed to update profile', currentState.user));
        }
      } catch (e) {
        emit(ProfileUpdateError('Failed to update profile: ${e.toString()}', currentState.user));
      }
    }
  }

  Future<void> uploadAvatar(String userId, String imagePath) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(ProfileUpdating(currentState.user));
      
      try {
        final avatarUrl = await _userRepository.uploadUserAvatar(userId, imagePath);
        if (avatarUrl != null) {
          final updatedUser = currentState.user.copyWith(avatarUrl: avatarUrl);
          emit(ProfileUpdated(updatedUser));
        } else {
          emit(ProfileUpdateError('Failed to upload avatar', currentState.user));
        }
      } catch (e) {
        emit(ProfileUpdateError('Failed to upload avatar: ${e.toString()}', currentState.user));
      }
    }
  }

  Future<void> refreshProfile() async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      await loadProfile(currentState.user.id);
    }
  }
}
