import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:reentry/core/config/supabase_config.dart';
import 'package:reentry/data/repository/auth/auth_repository.dart';
import 'package:reentry/data/shared/share_preference.dart';
import 'package:reentry/domain/usecases/auth/create_account_usecases.dart';
import 'package:reentry/domain/usecases/auth/login_usecase.dart';
import 'package:reentry/ui/modules/authentication/bloc/auth_events.dart';
import 'package:reentry/ui/modules/authentication/bloc/authentication_state.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../data/shared/keys.dart';
import '../../../../di/get_it.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginEvent>(_login);
    on<RegisterEvent>(_register);
    on<OAuthEvent>(_OAuthSignIn);
    on<LogoutEvent>(_logout);
    on<PasswordResetEvent>(_passwordReset);
    on<CreateAccountEvent>(_createAccountWithEmailAndPasswordEvent);
  }

  final _repository = AuthRepository();

  Future<void> _logout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
      await _repository.signOut();
      await PersistentStorage.logout();
      emit(LogoutSuccess());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _passwordReset(
      PasswordResetEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repository.resetPassword(email: event.email);
      emit(PasswordResetSuccess(resend: event.resend));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _login(LoginEvent event, Emitter<AuthState> emit) async {
    //repository login
    emit(LoginLoading());
    final result = await LoginUseCase().call(event);
    emit(result);
  }

  Future<void> _createAccountWithEmailAndPasswordEvent(
      CreateAccountEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      final result = await _repository.createAccountWithEmailAndPassword(
          email: event.email, password: event.password);
      emit(AuthenticationSuccess(result?.id));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _register(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await CreateAccountUseCase().call(event.data.toUserDto());
    emit(result);
  }

  Future<void> _OAuthSignIn(OAuthEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      UserDto? userProfile;
      String email = '';
      String name = '';
      String id = '';
      
      if (event.type == OAuthType.google) {
        final result = await _signInWithGoogle(emit);
        if (result != null) {
          userProfile = result['userProfile'];
          email = result['email'];
          name = result['name'];
          id = result['id'];
        }
      } else {
        final result = await _signInWithApple(emit);
        if (result != null) {
          userProfile = result['userProfile'];
          email = result['email'];
          name = result['name'];
          id = result['id'];
        }
      }
      
      if (userProfile != null) {
        final pref = await locator.getAsync<PersistentStorage>();
        await pref.cacheData(data: userProfile.toJson(), key: Keys.user);
        emit(OAuthSuccess(userProfile, email: email, name: name, id: id));
      } else {
        emit(AuthError('OAuth sign in failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}

Future<Map<String, dynamic>?> _signInWithGoogle(
    Emitter<AuthState> emit) async {
  try {
    // Trigger the authentication flow
    await GoogleSignIn().signOut();
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      emit(AuthError('Google sign in cancelled'));
      return null;
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser.authentication;

    print('google auth user -> ${googleUser.displayName}');
    
    // Sign in with Supabase using Google OAuth
    final response = await SupabaseConfig.auth.signInWithOAuth(
      Provider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
    );
    
    if (response.user == null) {
      emit(AuthError('Google sign in failed'));
      return null;
    }

    // Get or create user profile
    final authRepository = AuthRepository();
    final userProfile = await authRepository._getOrCreateUserProfile(response.user!);

    return {
      'userProfile': userProfile,
      'email': response.user!.email ?? '',
      'name': googleUser.displayName ?? '',
      'id': response.user!.id,
    };
  } catch (e) {
    emit(AuthError('Google sign in failed: ${e.toString()}'));
    return null;
  }
}

Future<Map<String, dynamic>?> _signInWithApple(
    Emitter<AuthState> emit) async {
  try {
    // Trigger the authentication flow
    final appleUser = await SignInWithApple.getAppleIDCredential(scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName
    ]);
    
    // Sign in with Supabase using Apple OAuth
    final response = await SupabaseConfig.auth.signInWithOAuth(
      Provider.apple,
      redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
    );
    
    if (response.user == null) {
      emit(AuthError('Apple sign in failed'));
      return null;
    }

    // Get or create user profile
    final authRepository = AuthRepository();
    final userProfile = await authRepository._getOrCreateUserProfile(response.user!);

    return {
      'userProfile': userProfile,
      'email': response.user!.email ?? '',
      'name': '${appleUser.givenName ?? ''} ${appleUser.familyName ?? ''}'.trim(),
      'id': response.user!.id,
    };
  } catch (e) {
    emit(AuthError('Apple sign in failed: ${e.toString()}'));
    return null;
  }
}
