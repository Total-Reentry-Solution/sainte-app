import '../../../../data/model/user.dart';

// Clean Profile State
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final AppUser user;
  
  ProfileLoaded(this.user);
}

class ProfileError extends ProfileState {
  final String message;
  
  ProfileError(this.message);
}

class ProfileUpdating extends ProfileState {
  final AppUser user;
  
  ProfileUpdating(this.user);
}

class ProfileUpdated extends ProfileState {
  final AppUser user;
  
  ProfileUpdated(this.user);
}

class ProfileUpdateError extends ProfileState {
  final String message;
  final AppUser user;
  
  ProfileUpdateError(this.message, this.user);
}
