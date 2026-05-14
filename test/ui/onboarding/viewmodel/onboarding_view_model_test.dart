import 'package:dawnbreaker/core/notification/notification_service_impl.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_impl.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/onboarding/viewmodel/onboarding_ui_state.dart';
import 'package:dawnbreaker/ui/onboarding/viewmodel/onboarding_view_model.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_notification_service.dart';
import '../../../helpers/fake_onboarding_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingViewModel', () {
    late ProviderContainer container;
    late FakeOnboardingRepository fakeRepository;
    late FakeNotificationService fakeNotificationService;
    late OnboardingViewModel viewModel;
    late OnboardingUiState viewState;

    void setUpState({OnboardingMode mode = .initial}) {
      viewModel = container.read(
        onboardingViewModelProvider(mode: mode).notifier,
      );
      container.listen(
        onboardingViewModelProvider(mode: mode),
        (_, next) => viewState = next,
        fireImmediately: true,
      );
    }

    setUp(() {
      fakeRepository = FakeOnboardingRepository();
      fakeNotificationService = FakeNotificationService();
      container = ProviderContainer(
        overrides: [
          onboardingRepositoryProvider.overrideWith((_) => fakeRepository),
          notificationServiceProvider.overrideWith(
            (_) async => fakeNotificationService,
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    group('初期状態', () {
      setUp(setUpState);

      test('ボタンが操作可能な状態である', () {
        expect(viewState.isLoading, false);
      });

      test('遷移先が決まっていない', () {
        expect(viewState.destination, isNull);
      });

      test('エラーがない', () {
        expect(viewState.dialogMessage, isNull);
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
            setUpState(mode: mode);
            await viewModel.onClickDone();
            expect(viewState.destination?.type, expected);
          });
        }

        test('遷移完了まで操作できない状態のままである', () async {
          setUpState();
          await viewModel.onClickDone();
          expect(viewState.isLoading, true);
        });
      });

      group('異常系', () {
        setUp(() {
          fakeRepository.shouldThrow = true;
          setUpState();
        });

        test('エラーが通知される', () async {
          await viewModel.onClickDone();
          expect(viewState.dialogMessage, isA<OnboardingSaveErrorMessage>());
        });

        test('ボタンが操作可能な状態に戻る', () async {
          await viewModel.onClickDone();
          expect(viewState.isLoading, false);
        });

        test('画面遷移しない', () async {
          await viewModel.onClickDone();
          expect(viewState.destination, isNull);
        });
      });
    });

    group('onRequestNotification', () {
      group('正常系', () {
        setUp(setUpState);

        for (final (permissionGranted, notificationEnabled, description) in [
          (true, true, '通知を許可すると通知設定が有効になり次のページへ進む'),
          (false, false, '通知を拒否しても次のページへ進み通知設定は変わらない'),
        ]) {
          test(description, () async {
            fakeNotificationService.permissionResult = permissionGranted;
            await viewModel.onRequestNotification();
            expect(viewState.destination?.type, OnboardingDestination.next);
            expect(
              fakeRepository.enableNotificationCalled,
              notificationEnabled,
            );
          });
        }
      });
    });

    group('onClickSkip', () {
      group('正常系', () {
        setUp(setUpState);

        test('ホーム画面に遷移する', () async {
          await viewModel.onClickSkip();
          expect(viewState.destination?.type, OnboardingDestination.home);
        });
      });

      group('異常系', () {
        test('設定画面からスキップすることはできない', () {
          setUpState(mode: .fromSettings);
          expect(() => viewModel.onClickSkip(), throwsStateError);
        });

        test('エラーが通知される', () async {
          fakeRepository.shouldThrow = true;
          setUpState();
          await viewModel.onClickSkip();
          expect(viewState.dialogMessage, isA<OnboardingSaveErrorMessage>());
        });

        test('ボタンが操作可能な状態に戻る', () async {
          fakeRepository.shouldThrow = true;
          setUpState();
          await viewModel.onClickSkip();
          expect(viewState.isLoading, false);
        });
      });
    });
  });
}
