import 'package:dawnbreaker/data/preferences/preferences_manager.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_exception.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OnboardingRepository repository;
  late FakePreferencesManager manager;

  group('saveCompletion', () {
    group('正常系', () {
      group('完了状態が保持されていない場合', () {
        setUp(() async {
          manager = await FakePreferencesManager.create();
          repository = OnboardingRepositoryImpl(manager);
        });

        test('完了状態が保存される', () async {
          await repository.saveCompletion();
          expect(manager.getBool(PreferenceKey.onboardingComplete), true);
        });

        test('複数回呼んでも完了状態が保存される', () async {
          await repository.saveCompletion();
          await repository.saveCompletion();
          expect(manager.getBool(PreferenceKey.onboardingComplete), true);
        });
      });

      group('完了状態が保持されている場合', () {
        setUp(() async {
          manager = await FakePreferencesManager.create(
            mockValues: {'onboarding_complete': true},
          );
          repository = OnboardingRepositoryImpl(manager);
          expect(manager.getBool(PreferenceKey.onboardingComplete), true);
        });

        test('保存処理を呼び出しても問題ないこと', () async {
          await repository.saveCompletion();
          expect(manager.getBool(PreferenceKey.onboardingComplete), true);
        });
      });
    });

    group('異常系', () {
      setUp(() async {
        manager = await FakePreferencesManager.create(shouldThrow: true);
        repository = OnboardingRepositoryImpl(manager);
      });

      test('ストレージが異常な場合、完了状態が保存されない', () async {
        await expectLater(
          () => repository.saveCompletion(),
          throwsA(isA<OnboardingSaveException>()),
        );
      });
    });
  });
}
