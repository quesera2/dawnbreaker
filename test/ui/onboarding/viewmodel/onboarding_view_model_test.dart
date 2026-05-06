import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_impl.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/onboarding/viewmodel/onboarding_ui_state.dart';
import 'package:dawnbreaker/ui/onboarding/viewmodel/onboarding_view_model.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_onboarding_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingViewModel', () {
    late ProviderContainer container;
    late FakeOnboardingRepository fakeRepository;

    setUp(() {
      fakeRepository = FakeOnboardingRepository();
      container = ProviderContainer(
        overrides: [
          onboardingRepositoryProvider.overrideWith((_) => fakeRepository),
        ],
      );
    });

    tearDown(() => container.dispose());

    group('初期状態', () {
      test('ボタンが操作可能な状態である', () {
        final state = container.read(
          onboardingViewModelProvider(mode: .initial),
        );
        expect(state.isLoading, false);
      });

      test('遷移先が決まっていない', () {
        final state = container.read(
          onboardingViewModelProvider(mode: .initial),
        );
        expect(state.destination, isNull);
      });

      test('エラーがない', () {
        final state = container.read(
          onboardingViewModelProvider(mode: .initial),
        );
        expect(state.dialogMessage, isNull);
      });
    });

    group('onClickDone', () {
      group('正常系', () {
        for (final (mode, expected, description) in [
          (
            OnboardingMode.initial,
            OnboardingDestination.newTask,
            'チュートリアル完了後にタスク作成画面に遷移する',
          ),
          (
            OnboardingMode.fromSettings,
            OnboardingDestination.pop,
            '設定から開いた場合に前の画面に戻る',
          ),
        ]) {
          test(description, () async {
            await container
                .read(onboardingViewModelProvider(mode: mode).notifier)
                .onClickDone();
            final state = container.read(
              onboardingViewModelProvider(mode: mode),
            );
            expect(state.destination, expected);
          });
        }

        test('遷移完了まで操作できない状態のままである', () async {
          await container
              .read(onboardingViewModelProvider(mode: .initial).notifier)
              .onClickDone();
          final state = container.read(
            onboardingViewModelProvider(mode: .initial),
          );
          expect(state.isLoading, true);
        });
      });

      group('異常系', () {
        setUp(() => fakeRepository.shouldThrow = true);

        test('エラーが通知される', () async {
          await container
              .read(onboardingViewModelProvider(mode: .initial).notifier)
              .onClickDone();
          final state = container.read(
            onboardingViewModelProvider(mode: .initial),
          );
          expect(state.dialogMessage, isA<OnboardingSaveErrorMessage>());
        });

        test('ボタンが操作可能な状態に戻る', () async {
          await container
              .read(onboardingViewModelProvider(mode: .initial).notifier)
              .onClickDone();
          final state = container.read(
            onboardingViewModelProvider(mode: .initial),
          );
          expect(state.isLoading, false);
        });

        test('画面遷移しない', () async {
          await container
              .read(onboardingViewModelProvider(mode: .initial).notifier)
              .onClickDone();
          final state = container.read(
            onboardingViewModelProvider(mode: .initial),
          );
          expect(state.destination, isNull);
        });
      });
    });

    group('onClickSkip', () {
      group('正常系', () {
        test('ホーム画面に遷移する', () async {
          await container
              .read(onboardingViewModelProvider(mode: .initial).notifier)
              .onClickSkip();
          final state = container.read(
            onboardingViewModelProvider(mode: .initial),
          );
          expect(state.destination, OnboardingDestination.home);
        });
      });

      group('異常系', () {
        test('設定画面からスキップすることはできない', () {
          expect(
            () => container
                .read(onboardingViewModelProvider(mode: .fromSettings).notifier)
                .onClickSkip(),
            throwsStateError,
          );
        });

        test('エラーが通知される', () async {
          fakeRepository.shouldThrow = true;
          await container
              .read(onboardingViewModelProvider(mode: .initial).notifier)
              .onClickSkip();
          final state = container.read(
            onboardingViewModelProvider(mode: .initial),
          );
          expect(state.dialogMessage, isA<OnboardingSaveErrorMessage>());
        });

        test('ボタンが操作可能な状態に戻る', () async {
          fakeRepository.shouldThrow = true;
          await container
              .read(onboardingViewModelProvider(mode: .initial).notifier)
              .onClickSkip();
          final state = container.read(
            onboardingViewModelProvider(mode: .initial),
          );
          expect(state.isLoading, false);
        });
      });
    });
  });
}
