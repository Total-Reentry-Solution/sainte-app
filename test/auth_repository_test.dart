import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/data/repository/auth/auth_repository.dart';
import 'package:reentry/core/config/supabase_config.dart';
import 'package:reentry/exception/app_exceptions.dart';

// Mocks
class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

class MockAuthResponse extends Mock implements supabase.AuthResponse {}

// Test repository that bypasses network calls for fetching profile
class _TestAuthRepository extends AuthRepository {
  final UserDto? _user;
  _TestAuthRepository(this._user);

  @override
  Future<UserDto?> findUserById(String id) async => _user;
}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    SupabaseConfig.testClient = mockClient;
    when(() => mockClient.auth).thenReturn(mockAuth);
  });

  tearDown(() {
    SupabaseConfig.testClient = null;
  });

  group('AuthRepository.login', () {
    final userJson = {
      'id': 'user-1',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'aud': 'authenticated',
      'created_at': '2024-01-01T00:00:00Z',
      'email': 'test@example.com',
      'phone': '',
      'confirmed_at': null,
      'email_confirmed_at': null,
      'phone_confirmed_at': null,
      'last_sign_in_at': '2024-01-01T00:00:00Z',
      'role': 'authenticated',
      'updated_at': '2024-01-01T00:00:00Z',
    };
    final supabaseUser = supabase.User.fromJson(userJson);

    test('returns user profile on successful login', () async {
      final response = MockAuthResponse();
      when(() => response.user).thenReturn(supabaseUser);
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => response);

      final userDto = UserDto(
        userId: 'user-1',
        name: 'Test User',
        accountType: AccountType.citizen,
      );
      final repo = _TestAuthRepository(userDto);

      final result = await repo.login(email: 'test@example.com', password: 'pw');

      expect(result, isNotNull);
      expect(result?.authId, 'user-1');
      expect(result?.data, userDto);
    });

    test('returns null profile when Supabase has no user data', () async {
      final response = MockAuthResponse();
      when(() => response.user).thenReturn(supabaseUser);
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => response);

      final repo = _TestAuthRepository(null);
      final result = await repo.login(email: 'test@example.com', password: 'pw');

      expect(result, isNotNull);
      expect(result?.authId, 'user-1');
      expect(result?.data, isNull);
    });

    test('throws when account is deleted', () async {
      final response = MockAuthResponse();
      when(() => response.user).thenReturn(supabaseUser);
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => response);

      final userDto = UserDto(
        userId: 'user-1',
        name: 'Deleted User',
        accountType: AccountType.citizen,
        deleted: true,
      );
      final repo = _TestAuthRepository(userDto);

      expect(
        () => repo.login(email: 'test@example.com', password: 'pw'),
        throwsA(isA<BaseExceptions>()),
      );
    });
  });

  group('OAuth callback', () {
    final userJson = {
      'id': 'user-2',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'aud': 'authenticated',
      'created_at': '2024-01-01T00:00:00Z',
      'email': 'oauth@example.com',
      'phone': '',
      'confirmed_at': null,
      'email_confirmed_at': null,
      'phone_confirmed_at': null,
      'last_sign_in_at': '2024-01-01T00:00:00Z',
      'role': 'authenticated',
      'updated_at': '2024-01-01T00:00:00Z',
    };
    final supabaseUser = supabase.User.fromJson(userJson);

    test('fetches profile after OAuth sign in', () async {
      when(() => mockAuth.signInWithOAuth(
            supabase.OAuthProvider.google,
            redirectTo: any(named: 'redirectTo'),
          )).thenAnswer((_) async {});
      when(() => mockAuth.currentUser).thenReturn(supabaseUser);

      final userDto = UserDto(
        userId: 'user-2',
        name: 'OAuth User',
        accountType: AccountType.citizen,
      );
      final repo = _TestAuthRepository(userDto);

      final result = await repo.googleSignIn();
      expect(result, userDto);
    });

    test('throws when OAuth callback returns no user', () async {
      when(() => mockAuth.signInWithOAuth(
            supabase.OAuthProvider.google,
            redirectTo: any(named: 'redirectTo'),
          )).thenAnswer((_) async {});
      when(() => mockAuth.currentUser).thenReturn(null);

      final repo = _TestAuthRepository(null);

      expect(repo.googleSignIn(), throwsA(isA<BaseExceptions>()));
    });
  });
}
