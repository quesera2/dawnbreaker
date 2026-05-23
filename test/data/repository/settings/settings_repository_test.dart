import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/preferences/preference_key.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsRepositoryImpl repository;
  late FakePreferencesManager manager;

  tearDown(() => repository.dispose());

  group('watchNotificationEnabled', () {
    group('初期値が設定されていない場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create();
        repository = SettingsRepositoryImpl(manager);
      });

      test('デフォルト値のfalseが流れる', () async {
        await expectLater(
          repository.watchNotificationEnabled().take(1),
          emits(false),
        );
      });
    });

    group('初期値がfalseの場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create(
          mockValues: {notificationEnabledKey.rawKey: false},
        );
        repository = SettingsRepositoryImpl(manager);
      });

      test('falseが流れる', () async {
        await expectLater(
          repository.watchNotificationEnabled().take(1),
          emits(false),
        );
      });
    });
  });

  group('setNotificationEnabled', () {
    setUp(() async {
      manager = await FakePreferencesManager.create();
      repository = SettingsRepositoryImpl(manager);
    });

    test('変更した値がstreamに流れる', () async {
      final expectation = expectLater(
        repository.watchNotificationEnabled().take(2),
        emitsInOrder([false, true]),
      );
      await pumpEventQueue();

      await repository.setNotificationEnabled(true);
      await expectation;
    });

    test('変更した値がストレージに保存される', () async {
      await repository.setNotificationEnabled(false);

      expect(manager.get(notificationEnabledKey, defaultValue: true), false);
    });

    test('変更後の新しいsubscriberは最新値を受け取る', () async {
      await repository.setNotificationEnabled(false);

      await expectLater(
        repository.watchNotificationEnabled().take(1),
        emits(false),
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

      test('デフォルト設定がストレージに保存される', () async {
        await repository.watchColorSettings().first;

        final saved = manager.get(
          colorSettingsKey,
          defaultValue: const <String>[],
        );
        expect(saved, isNotEmpty);
        expect(saved.length, TaskColor.values.length);
      });
    });

    group('保存済みの設定がある場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create(
          mockValues: {
            colorSettingsKey.rawKey: ['red:レッド', 'blue:ブルー'],
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
        const ColorSetting(color: TaskColor.red, alias: 'キッチン'),
        const ColorSetting(color: TaskColor.blue, alias: ''),
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
      final updated = [const ColorSetting(color: TaskColor.green, alias: '植物')];
      await repository.setColorSettings(updated);

      expect(manager.get(colorSettingsKey, defaultValue: const <String>[]), [
        'green:植物',
      ]);
    });
  });
}
