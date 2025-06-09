import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
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

class OAuthCredentialWrapper {
  final OAuthCredential credential;
  final String? name;

  const OAuthCredentialWrapper({required this.credential, required this.name});
}

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
  final _supabase = SupabaseConfig.client;

  Future<void> _logout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
      await _supabase.auth.signOut();
      await PersistentStorage.logout();
      emit(LogoutSuccess());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _login(LoginEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      final response = await _supabase.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );
      
      if (response.user == null) {
        throw Exception('Login failed');
      }

      final user = await _repository.findUserById(response.user!.id);
      if (user == null) {
        throw Exception('User not found');
      }

      await PersistentStorage.setUser(user);
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _register(RegisterEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      final response = await _supabase.auth.signUp(
        email: event.email,
        password: event.password,
      );

      if (response.user == null) {
        throw Exception('Registration failed');
      }

      final user = UserDto(
        userId: response.user!.id,
        email: event.email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.createAccount(user);
      await PersistentStorage.setUser(user);
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _OAuthSignIn(OAuthEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      UserDto user;
      
      if (event.provider == 'google') {
        user = await _repository.googleSignIn();
      } else if (event.provider == 'apple') {
        user = await _repository.appleSignIn();
      } else {
        throw Exception('Unsupported provider');
      }

      await PersistentStorage.setUser(user);
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _passwordReset(PasswordResetEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      await _supabase.auth.resetPasswordForEmail(event.email);
      emit(PasswordResetSuccess());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _createAccountWithEmailAndPasswordEvent(
    CreateAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      final response = await _supabase.auth.signUp(
        email: event.email,
        password: event.password,
      );

      if (response.user == null) {
        throw Exception('Account creation failed');
      }

      final user = UserDto(
        userId: response.user!.id,
        email: event.email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.createAccount(user);
      await PersistentStorage.setUser(user);
      emit(AuthSuccess(user));
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

    //  print('ebilate -> -> ${googleAuth?.idToken}');
   
    print('google auth user -> ${googleUser?.displayName}');
    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    // Once signed in, return the UserCredential

    return OAuthCredentialWrapper(
        credential: credential, name: googleUser?.displayName);
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
    final token = appleUser.identityToken;
    if (token == null) {
      emit(AuthError('Something went wrong'));
    }

    final provider = OAuthProvider('apple.com');
    final credential = provider.credential(
        accessToken: appleUser.authorizationCode, idToken: token);

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token ?? '');

    return OAuthCredentialWrapper(
        credential: credential, name: appleUser.givenName);
  } catch (e) {
    emit(AuthError('Something went wrong'));
    return null;
  }
}
