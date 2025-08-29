import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:reentry/core/config/supabase_config.dart';
import 'package:reentry/data/repository/user/user_repository.dart';

class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}
class MockPostgrestFilterBuilder extends Mock implements supabase.PostgrestFilterBuilder {}

void main() {
  late MockSupabaseClient mockClient;
  late MockPostgrestFilterBuilder mockQuery;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockQuery = MockPostgrestFilterBuilder();
    SupabaseConfig.testClient = mockClient;
    when(() => mockClient.from(any())).thenReturn(mockQuery);
    when(() => mockQuery.select()).thenReturn(mockQuery);
    when(() => mockQuery.eq(any(), any())).thenReturn(mockQuery);
    when(() => mockQuery.order(any(), ascending: any(named: 'ascending')))
        .thenAnswer((_) async => [
              {
                'id': '1',
                'email': 'a@a.com',
                'first_name': 'A',
                'last_name': 'B',
                'account_type': 'citizen',
                'deleted': false,
              },
              {
                'id': '2',
                'email': 'b@b.com',
                'first_name': 'C',
                'last_name': 'D',
                'account_type': 'citizen',
                'deleted': true,
              }
            ]);
  });

  tearDown(() {
    SupabaseConfig.testClient = null;
  });

  test('getCitizens filters out deleted users', () async {
    final repo = UserRepository();
    final result = await repo.getCitizens();
    expect(result.length, 1);
    expect(result.first.userId, '1');
  });
}
