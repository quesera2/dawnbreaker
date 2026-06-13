import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart'
    show NotificationSetting, NotifyDay;
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/preferences/preference_key.dart'
    show
        notificationSettingKey,
        homeSortModeKey,
        colorSettingsKey,
        progressBarAnimationKey;
import 'package:dawnbreaker/data/repository/settings/settings_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsRepositoryImpl repository;
  late FakePreferencesManager manager;

  tearDown(() => repository.dispose());

  group('watchNotificationSetting', () {
    group('初期値が設定されていない場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create();
        repository = SettingsRepositoryImpl(manager);
      });

      test('デフォルト値（enabled: false, 当日9:00）が流れる', () async {
        final setting = await repository.watchNotificationSetting().first;
        expect(setting.enabled, false);
        expect(setting.notifyDay, NotifyDay.today);
        expect(setting.hour, 9);
        expect(setting.minute, 0);
      });
    });

    group('保存済みの設定がある場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create(
          mockValues: {
            notificationSettingKey.rawKey:
                '{"enabled":true,"notifyDay":"yesterday","hour":22,"minute":30}',
          },
        );
        repository = SettingsRepositoryImpl(manager);
      });

      test('保存済みの設定が流れる', () async {
        final setting = await repository.watchNotificationSetting().first;
        expect(setting.enabled, true);
        expect(setting.notifyDay, NotifyDay.yesterday);
        expect(setting.hour, 22);
        expect(setting.minute, 30);
      });
    });

    group('不正な設定が保存されている場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create(
          mockValues: {notificationSettingKey.rawKey: 'invalid json'},
        );
        repository = SettingsRepositoryImpl(manager);
      });

      test('デフォルト値が流れる', () async {
        final setting = await repository.watchNotificationSetting().first;
        expect(setting.enabled, false);
        expect(setting.notifyDay, NotifyDay.today);
        expect(setting.hour, 9);
        expect(setting.minute, 0);
      });
    });
  });

  group('setNotificationSetting', () {
    setUp(() async {
      manager = await FakePreferencesManager.create();
      repository = SettingsRepositoryImpl(manager);
    });

    test('変更した値がstreamに流れる', () async {
      const updated = NotificationSetting(enabled: true, hour: 8, minute: 30);
      final expectation = expectLater(
        repository.watchNotificationSetting().take(2),
        emitsInOrder([
          isA<NotificationSetting>().having((s) => s.enabled, 'enabled', false),
          isA<NotificationSetting>()
              .having((s) => s.enabled, 'enabled', true)
              .having((s) => s.hour, 'hour', 8)
              .having((s) => s.minute, 'minute', 30),
        ]),
      );
      await pumpEventQueue();

      await repository.setNotificationSetting(updated);
      await expectation;
    });

    test('変更した値がストレージに保存される', () async {
      const updated = NotificationSetting(
        enabled: true,
        notifyDay: NotifyDay.yesterday,
        hour: 20,
        minute: 0,
      );
      await repository.setNotificationSetting(updated);

      final stored = manager.get(notificationSettingKey, defaultValue: '');
      final decoded = NotificationSetting.decode(stored);
      expect(decoded.enabled, true);
      expect(decoded.notifyDay, NotifyDay.yesterday);
      expect(decoded.hour, 20);
      expect(decoded.minute, 0);
    });

    test('変更後の新しいsubscriberは最新値を受け取る', () async {
      const updated = NotificationSetting(enabled: true, hour: 7);
      await repository.setNotificationSetting(updated);

      final setting = await repository.watchNotificationSetting().first;
      expect(setting.enabled, true);
      expect(setting.hour, 7);
    });
  });

  group('watchHomeDisplayMode', () {
    group('初期値が設定されていない場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create();
        repository = SettingsRepositoryImpl(manager);
      });

      test('デフォルト値のtimelineが流れる', () async {
        await expectLater(
          repository.watchHomeDisplayMode().take(1),
          emits(HomeDisplayMode.timeline),
        );
      });
    });

    group('初期値がbyColorの場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create(
          mockValues: {homeSortModeKey.rawKey: 'by_color'},
        );
        repository = SettingsRepositoryImpl(manager);
      });

      test('byColorが流れる', () async {
        await expectLater(
          repository.watchHomeDisplayMode().take(1),
          emits(HomeDisplayMode.byColor),
        );
      });
    });
  });

  group('setHomeDisplayMode', () {
    setUp(() async {
      manager = await FakePreferencesManager.create();
      repository = SettingsRepositoryImpl(manager);
    });

    test('変更した値がstreamに流れる', () async {
      final expectation = expectLater(
        repository.watchHomeDisplayMode().take(2),
        emitsInOrder([HomeDisplayMode.timeline, HomeDisplayMode.byColor]),
      );
      await pumpEventQueue();

      await repository.setHomeDisplayMode(.byColor);
      await expectation;
    });

    test('変更した値がストレージに保存される', () async {
      await repository.setHomeDisplayMode(.byColor);

      expect(manager.get(homeSortModeKey, defaultValue: ''), 'by_color');
    });

    test('変更後の新しいsubscriberは最新値を受け取る', () async {
      await repository.setHomeDisplayMode(.byColor);

      await expectLater(
        repository.watchHomeDisplayMode().take(1),
        emits(HomeDisplayMode.byColor),
      );
    });
  });

  group('watchColorSettings', () {
    group('初期値が設定されていない場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create();
        repository = SettingsRepositoryImpl(manager);
      });

      test('全カラーのデフォルト設定が流れる', () async {
        final settings = await repository.watchColorSettings().first;
        expect(settings.map((s) => s.color).toSet(), TaskColor.values.toSet());
        expect(settings.every((s) => s.alias.isEmpty), isTrue);
      });

      test('.none が末尾に配置される', () async {
        final settings = await repository.watchColorSettings().first;
        expect(settings.last.color, TaskColor.none);
      });
    });

    group('保存済みの設定がある場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create(
          mockValues: {
            colorSettingsKey.rawKey: ['red:0:レッド', 'blue:1:ブルー'],
          },
        );
        repository = SettingsRepositoryImpl(manager);
      });

      test('保存済み順序でカラー設定が流れ、未保存カラーは末尾に追加される', () async {
        final settings = await repository.watchColorSettings().first;
        expect(settings[0].color, TaskColor.red);
        expect(settings[0].alias, 'レッド');
        expect(settings[1].color, TaskColor.blue);
        expect(settings[1].alias, 'ブルー');
        expect(settings.map((s) => s.color).toSet(), TaskColor.values.toSet());
      });
    });
  });

  group('setColorSettings', () {
    setUp(() async {
      manager = await FakePreferencesManager.create();
      repository = SettingsRepositoryImpl(manager);
    });

    test('変更した設定がstreamに流れる', () async {
      final updated = [
        const ColorSetting(color: TaskColor.red, alias: 'キッチン', order: 0),
        const ColorSetting(color: TaskColor.blue, alias: '', order: 1),
      ];
      final expectation = expectLater(
        repository.watchColorSettings().skip(1).take(1),
        emits(updated),
      );
      await pumpEventQueue();

      await repository.setColorSettings(updated);
      await expectation;
    });

    test('変更した設定がストレージに保存される', () async {
      final updated = [
        const ColorSetting(color: TaskColor.green, alias: '植物', order: 0),
      ];
      await repository.setColorSettings(updated);

      expect(manager.get(colorSettingsKey, defaultValue: const <String>[]), [
        'green:0:植物',
      ]);
    });
  });

  group('watchProgressBarAnimationEnabled', () {
    group('初期値が設定されていない場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create();
        repository = SettingsRepositoryImpl(manager);
      });

      test('デフォルト値のtrueが流れる', () async {
        await expectLater(
          repository.watchProgressBarAnimationEnabled().take(1),
          emits(true),
        );
      });
    });

    group('初期値がfalseの場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create(
          mockValues: {progressBarAnimationKey.rawKey: false},
        );
        repository = SettingsRepositoryImpl(manager);
      });

      test('falseが流れる', () async {
        await expectLater(
          repository.watchProgressBarAnimationEnabled().take(1),
          emits(false),
        );
      });
    });
  });

  group('setProgressBarAnimationEnabled', () {
    setUp(() async {
      manager = await FakePreferencesManager.create();
      repository = SettingsRepositoryImpl(manager);
    });

    test('変更した値がstreamに流れる', () async {
      final expectation = expectLater(
        repository.watchProgressBarAnimationEnabled().take(2),
        emitsInOrder([true, false]),
      );
      await pumpEventQueue();

      await repository.setProgressBarAnimationEnabled(false);
      await expectation;
    });

    test('変更した値がストレージに保存される', () async {
      await repository.setProgressBarAnimationEnabled(false);

      expect(manager.get(progressBarAnimationKey, defaultValue: true), false);
    });

    test('変更後の新しいsubscriberは最新値を受け取る', () async {
      await repository.setProgressBarAnimationEnabled(false);

      await expectLater(
        repository.watchProgressBarAnimationEnabled().take(1),
        emits(false),
      );
    });
  });
}
