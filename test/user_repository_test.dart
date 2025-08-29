import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:reentry/data/repository/user/user_repository.dart';
import 'package:reentry/core/config/supabase_config.dart';

class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class MockPostgrestFilterBuilder extends Mock
    implements supabase.PostgrestFilterBuilder {}

void main() {
  late MockSupabaseClient mockClient;
  late MockPostgrestFilterBuilder mockBuilder;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockBuilder = MockPostgrestFilterBuilder();
    SupabaseConfig.testClient = mockClient;

    when(() => mockClient.from(any())).thenReturn(mockBuilder);
    when(() => mockBuilder.select()).thenReturn(mockBuilder);
    when(() => mockBuilder.eq(any(), any())).thenReturn(mockBuilder);
    when(() => mockBuilder.order(any())).thenAnswer((_) async => [
          {
            'id': '1',
            'email': 'a@b.com',
            'first_name': 'John',
            'last_name': 'Doe',
            'phone': '',
            'avatar_url': null,
            'address': null,
            'account_type': 'citizen',
            'organizations': [],
            'organization': null,
            'organization_address': null,
            'job_title': null,
            'supervisors_name': null,
            'supervisors_email': null,
            'services': [],
            'created_at': null,
            'updated_at': null,
            'deleted': false,
            'reason_for_account_deletion': null,
          }
        ]);
  });

  tearDown(() {
    SupabaseConfig.testClient = null;
  });

  test('getCitizens filters out deleted users', () async {
    final repo = UserRepository();
    final users = await repo.getCitizens();

    expect(users.length, 1);
    verify(() => mockBuilder.eq('deleted', false)).called(1);
  });
}
