import 'package:flutter_test/flutter_test.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/enum/account_type.dart';

void main() {
  test('UserDto parses and serializes snake_case fields', () {
    final json = {
      'id': '1',
      'name': 'Test User',
      'account_type': 'citizen',
      'deleted': true,
      'push_notification_token': 'token',
      'reason_for_account_deletion': 'reason',
      'settings': {
        'push_notification': false,
        'email_notification': true,
        'sms_notification': true,
        'language': 'en',
        'theme': 'dark',
      }
    };

    final user = UserDto.fromJson(json);
    expect(user.deleted, isTrue);
    expect(user.accountType, AccountType.citizen);
    expect(user.pushNotificationToken, 'token');
    expect(user.reasonForAccountDeletion, 'reason');
    expect(user.settings.pushNotification, isFalse);
    expect(user.settings.emailNotification, isTrue);
    expect(user.settings.smsNotification, isTrue);
    expect(user.settings.language, 'en');
    expect(user.settings.theme, 'dark');

    final serialized = user.toJson();
    expect(serialized['deleted'], isTrue);
    expect(serialized['push_notification_token'], 'token');
    expect(serialized['reason_for_account_deletion'], 'reason');
    expect(serialized['settings'], {
      'push_notification': false,
      'email_notification': true,
      'sms_notification': true,
      'language': 'en',
      'theme': 'dark',
    });
  });
}
