import 'package:dawnbreaker/data/preferences/preference_key.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_exception.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OnboardingRepository repository;
  late FakePreferencesManager manager;

  group('enableNotificationSettings', () {
    group('ストレージが正常な場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create();
        repository = OnboardingRepositoryImpl(manager);
      });

      test('通知設定が有効になる', () async {
        await repository.enableNotificationSettings();
        expect(manager.get(notificationEnabledKey, defaultValue: false), true);
      });
    });

    group('ストレージが異常な場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create(shouldThrow: true);
        repository = OnboardingRepositoryImpl(manager);
      });

      test('通知設定が保存されない', () async {
        await expectLater(
          () => repository.enableNotificationSettings(),
          throwsA(isA<OnboardingSaveException>()),
        );
      });
    });
  });

  group('saveCompletion', () {
    group('完了状態が保持されていない場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create();
        repository = OnboardingRepositoryImpl(manager);
      });

      test('完了状態が保存される', () async {
        await repository.saveCompletion();
        expect(manager.get(onboardingCompleteKey, defaultValue: false), true);
      });

      test('複数回呼んでも完了状態が保存される', () async {
        await repository.saveCompletion();
        await repository.saveCompletion();
        expect(manager.get(onboardingCompleteKey, defaultValue: false), true);
      });
    });

    group('完了状態が保持されている場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create(
          mockValues: {'onboarding_complete': true},
        );
        repository = OnboardingRepositoryImpl(manager);
        expect(manager.get(onboardingCompleteKey, defaultValue: false), true);
      });

      test('保存処理を呼び出しても問題ない', () async {
        await repository.saveCompletion();
        expect(manager.get(onboardingCompleteKey, defaultValue: false), true);
      });
    });

    group('ストレージが異常な場合', () {
      setUp(() async {
        manager = await FakePreferencesManager.create(shouldThrow: true);
        repository = OnboardingRepositoryImpl(manager);
      });

      test('完了状態が保存されない', () async {
        await expectLater(
          () => repository.saveCompletion(),
          throwsA(isA<OnboardingSaveException>()),
        );
      });
    });
  });
}
