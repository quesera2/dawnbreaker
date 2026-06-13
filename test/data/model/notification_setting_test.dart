import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotifyDay.dayOffset', () {
    for (final (day, expected) in [
      (NotifyDay.today, 0),
      (NotifyDay.yesterday, -1),
    ]) {
      test('$day → $expected', () {
        expect(day.dayOffset, expected);
      });
    }
  });

  group('NotificationSetting.encode / decode', () {
    test('encode した値を decode で復元できる', () {
      const original = NotificationSetting(
        enabled: true,
        notifyDay: NotifyDay.yesterday,
        hour: 22,
        minute: 30,
      );
      final decoded = NotificationSetting.decode(original.encode());
      expect(decoded, original);
    });

    test('不正な JSON を decode するとデフォルト値を返す', () {
      final decoded = NotificationSetting.decode('invalid json');
      expect(decoded, const NotificationSetting());
    });

    test('空文字を decode するとデフォルト値を返す', () {
      final decoded = NotificationSetting.decode('');
      expect(decoded, const NotificationSetting());
    });

    test('範囲外の hour / minute は clamp される', () {
      final decoded = NotificationSetting.decode(
        '{"enabled":false,"notifyDay":"today","hour":25,"minute":61}',
      );
      expect(decoded.hour, 23);
      expect(decoded.minute, 59);
    });
  });
}
