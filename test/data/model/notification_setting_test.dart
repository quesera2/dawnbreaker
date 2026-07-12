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

  group('NotificationSetting.fromMap', () {
    test('保存した値を復元できる', () {
      const original = NotificationSetting(
        enabled: true,
        notifyDay: NotifyDay.yesterday,
        hour: 22,
        minute: 30,
      );
      expect(NotificationSetting.fromMap(original.toJson()), original);
    });

    test('設定がない場合はデフォルト値を返す', () {
      expect(NotificationSetting.fromMap(null), const NotificationSetting());
    });

    test('壊れた値の場合はデフォルト値を返す', () {
      expect(
        NotificationSetting.fromMap({'enabled': 'not a bool'}),
        const NotificationSetting(),
      );
    });

    test('範囲外の hour / minute は clamp される', () {
      final setting = NotificationSetting.fromMap({
        'enabled': false,
        'notifyDay': 'today',
        'hour': 25,
        'minute': 61,
      });
      expect(setting.hour, 23);
      expect(setting.minute, 59);
    });
  });
}
