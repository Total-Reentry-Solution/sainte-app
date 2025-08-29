import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:reentry/core/config/supabase_config.dart';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/repository/user/user_repository.dart';
import 'package:reentry/data/shared/share_preference.dart';
import 'package:reentry/di/get_it.dart';

// Mocks
class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}
class MockPostgrestFilterBuilder extends Mock implements supabase.PostgrestFilterBuilder {}
class MockPersistentStorage extends Mock implements PersistentStorage {}

void main() {
  late MockSupabaseClient mockClient;
  late MockPostgrestFilterBuilder mockClientAssigneesBuilder;
  late MockPostgrestFilterBuilder mockUserProfilesBuilder;
  late MockPersistentStorage mockStorage;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockClientAssigneesBuilder = MockPostgrestFilterBuilder();
    mockUserProfilesBuilder = MockPostgrestFilterBuilder();
    mockStorage = MockPersistentStorage();

    // Configure storage to return a current user
    locator.reset();
    locator.registerSingleton<PersistentStorage>(mockStorage);
    when(() => mockStorage.getUser()).thenReturn(
      UserDto(userId: 'client-1', name: 'Client One', accountType: AccountType.citizen),
    );

    // Mock Supabase client
    SupabaseConfig.testClient = mockClient;
    when(() => mockClient.from('client_assignees'))
        .thenReturn(mockClientAssigneesBuilder);
    when(() => mockClient.from('user_profiles'))
        .thenReturn(mockUserProfilesBuilder);

    // client_assignees query
    when(() => mockClientAssigneesBuilder.select('assignee_id'))
        .thenReturn(mockClientAssigneesBuilder);
    when(() => mockClientAssigneesBuilder.eq('client_id', any()))
        .thenAnswer((_) async => [
              {'assignee_id': 'assignee-1'},
              {'assignee_id': 'assignee-2'},
            ]);

    // user_profiles query
    when(() => mockUserProfilesBuilder.select())
        .thenReturn(mockUserProfilesBuilder);
    when(() => mockUserProfilesBuilder.inFilter('id', any()))
        .thenAnswer((_) async => [
              {
                'id': 'assignee-1',
                'name': 'Alice',
                'account_type': 'citizen',
                'email': 'alice@example.com',
                'created_at': '2024-01-01T00:00:00Z',
                'updated_at': '2024-01-02T00:00:00Z',
              },
              {
                'id': 'assignee-2',
                'name': 'Bob',
                'account_type': 'citizen',
                'email': 'bob@example.com',
                'created_at': '2024-01-01T00:00:00Z',
                'updated_at': '2024-01-02T00:00:00Z',
              }
            ]);
  });

  tearDown(() {
    SupabaseConfig.testClient = null;
    locator.reset();
  });

  test('getUserAssignee returns list of assignments', () async {
    final repo = UserRepository();
    final result = await repo.getUserAssignee();
    expect(result.map((e) => e.userId).toList(), ['assignee-1', 'assignee-2']);
  });
}
