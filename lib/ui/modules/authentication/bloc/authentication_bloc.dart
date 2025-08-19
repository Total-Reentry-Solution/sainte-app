import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/data/repository/auth/auth_repository.dart';
import 'package:reentry/data/shared/share_preference.dart';
import 'package:reentry/domain/usecases/auth/create_account_usecases.dart';
import 'package:reentry/domain/usecases/auth/login_usecase.dart';
import 'package:reentry/ui/modules/authentication/bloc/auth_events.dart';
import 'package:reentry/ui/modules/authentication/bloc/authentication_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/config/supabase_config.dart';
import '../../../../data/shared/keys.dart';
import '../../../../di/get_it.dart';



class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginEvent>(_login);
    on<LogoutEvent>(_logout);
    on<PasswordResetEvent>(_passwordReset);
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



  Future<void> _signInWithGoogleEvent(SignInWithGoogleEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      final user = await _repository.googleSignIn();
      if (user != null) {
        final pref = await locator.getAsync<PersistentStorage>();
        await pref.cacheData(data: user.toJson(), key: Keys.user);
        emit(OAuthSuccess(user,
            email: user.email ?? '',
            name: user.name ?? '',
            id: user.userId ?? ''));
      } else {
        emit(AuthError('Google sign in failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _signInWithAppleEvent(SignInWithAppleEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      final user = await _repository.appleSignIn();
      if (user != null) {
        final pref = await locator.getAsync<PersistentStorage>();
        await pref.cacheData(data: user.toJson(), key: Keys.user);
        emit(OAuthSuccess(user,
            email: user.email ?? '',
            name: user.name ?? '',
            id: user.userId ?? ''));
      } else {
        emit(AuthError('Apple sign in failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }


}


