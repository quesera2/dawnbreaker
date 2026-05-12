import 'package:dawnbreaker/data/preferences/preferences_manager.dart';
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

      test('デフォルト値のtrueが流れる', () async {
        await expectLater(
          repository.watchNotificationEnabled().take(1),
          emits(true),
        );
      });
    });

    group('初期値がfalseの場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create(
          mockValues: {PreferenceKey.notificationEnabled.rawKey: false},
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
        emitsInOrder([true, false]),
      );
      await pumpEventQueue();

      await repository.setNotificationEnabled(false);
      await expectation;
    });

    test('変更した値がストレージに保存される', () async {
      await repository.setNotificationEnabled(false);

      expect(
        manager.getBool(PreferenceKey.notificationEnabled, defaultValue: true),
        false,
      );
    });

    test('変更後の新しいsubscriberは最新値を受け取る', () async {
      await repository.setNotificationEnabled(false);

      await expectLater(
        repository.watchNotificationEnabled().take(1),
        emits(false),
      );
    });
  });
}
