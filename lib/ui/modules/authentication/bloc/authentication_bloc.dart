import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:reentry/data/repository/auth/auth_repository.dart';
import 'package:reentry/data/shared/share_preference.dart';
import 'package:reentry/domain/usecases/auth/create_account_usecases.dart';
import 'package:reentry/domain/usecases/auth/login_usecase.dart';
import 'package:reentry/ui/modules/authentication/bloc/auth_events.dart';
import 'package:reentry/ui/modules/authentication/bloc/authentication_state.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/config/supabase_config.dart';
import '../../../../data/shared/keys.dart';
import '../../../../di/get_it.dart';

class OAuthCredentialWrapper {
  final dynamic credential;
  final String? name;

  const OAuthCredentialWrapper({required this.credential, required this.name});
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginEvent>(_login);
    on<LogoutEvent>(_logout);
    on<PasswordResetEvent>(_passwordReset);
    on<OAuthEvent>(_OAuthSignIn);
    on<SignInWithGoogleEvent>(_signInWithGoogleEvent);
    on<SignInWithAppleEvent>(_signInWithAppleEvent);
    on<CreateAccountEvent>(_createAccountWithEmailAndPasswordEvent);
    on<RegisterEvent>(_register);
  }

  final _repository = AuthRepository();

  Future<void> _logout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      // Sign out from Supabase
      await SupabaseConfig.signOut();
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
      
      // Result will be Supabase User
      final supabaseUser = result as supabase.User?;
      emit(AuthenticationSuccess(supabaseUser?.id));
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
    // Handle OAuth through Supabase
    await _handleSupabaseOAuth(event, emit);
  }

  Future<void> _signInWithGoogleEvent(SignInWithGoogleEvent event, Emitter<AuthState> emit) async {
    await _handleSupabaseOAuth(OAuthEvent(OAuthType.google), emit);
  }

  Future<void> _signInWithAppleEvent(SignInWithAppleEvent event, Emitter<AuthState> emit) async {
    await _handleSupabaseOAuth(OAuthEvent(OAuthType.apple), emit);
  }

  Future<void> _handleSupabaseOAuth(OAuthEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      
      if (event.type == OAuthType.google) {
        await SupabaseConfig.client.auth.signInWithOAuth(
          supabase.OAuthProvider.google,
          redirectTo: Uri.base.toString(),
        );
      } else {
        await SupabaseConfig.client.auth.signInWithOAuth(
          supabase.OAuthProvider.apple,
          redirectTo: Uri.base.toString(),
        );
      }
      
      // For web OAuth, we need to check if the user is authenticated after the redirect
      final currentUser = SupabaseConfig.currentUser;
      if (currentUser != null) {
        final value = await _repository.findUserById(currentUser.id);
        if (value != null) {
          final pref = await locator.getAsync<PersistentStorage>();
          await pref.cacheData(data: value.toJson(), key: Keys.user);
        }
        emit(OAuthSuccess(value,
            email: currentUser.email ?? '',
            name: currentUser.userMetadata?['full_name'] ?? '',
            id: currentUser.id));
      } else {
        emit(AuthError('OAuth sign in failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}

Future<OAuthCredentialWrapper?> _signInWithGoogle(
    Emitter<AuthState> emit) async {
  try {
    // Trigger the authentication flow
    await GoogleSignIn().signOut();
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    print('google auth user -> ${googleUser?.displayName}');
    
    // For Supabase, we'll use the OAuth flow instead
    return OAuthCredentialWrapper(
        credential: null, name: googleUser?.displayName);
  } catch (e) {
    emit(AuthError('Something went wrong'));
    return null;
  }
}

Future<OAuthCredentialWrapper?> _signInWithApple(
    Emitter<AuthState> emit) async {
  try {
    // Trigger the authentication flow
    final appleUser = await SignInWithApple.getAppleIDCredential(scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName
    ]);
    
    // For Supabase, we'll use the OAuth flow instead
    return OAuthCredentialWrapper(
        credential: null, name: appleUser.givenName);
  } catch (e) {
    emit(AuthError('Something went wrong'));
    return null;
  }
}
