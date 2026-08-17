import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_impl.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/onboarding/viewmodel/onboarding_ui_state.dart';
import 'package:dawnbreaker/ui/onboarding/viewmodel/onboarding_view_model.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_onboarding_repository.dart';
import '../../../helpers/fake_user_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingViewModel', () {
    late ProviderContainer container;
    late FakeOnboardingRepository fakeRepository;
    late FakeUserRepository fakeUserRepository;
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
      fakeUserRepository = FakeUserRepository(const LoggedIn('user-1'));
      container = ProviderContainer(
        overrides: [
          onboardingRepositoryProvider.overrideWith((_) => fakeRepository),
          userRepositoryProvider.overrideWith((_) => fakeUserRepository),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await fakeUserRepository.close();
    });

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
            OnboardingDestination.login,
            'チュートリアル完了後にログイン画面に遷移する',
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

    group('onClickSkip', () {
      group('正常系', () {
        setUp(setUpState);

        test('ログイン画面に遷移する', () async {
          await viewModel.onClickSkip();
          expect(viewState.destination?.type, OnboardingDestination.login);
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
    // サインアウトだけはこの画面が行う。設定画面を残したままサインアウトすると、
    // まだ生きている購読が NoLogin で走って例外になるため（ログアウトと同じ形）
    group('finishAccountDeletion', () {
      group('正常系', () {
        setUp(() => setUpState(mode: .afterAccountDeletion));

        test('消えたアカウントのセッションを残さない', () async {
          await viewModel.finishAccountDeletion();
          expect(fakeUserRepository.signOutCount, 1);
        });

        test('開き直したときにチュートリアルから始まるようにする', () async {
          await viewModel.finishAccountDeletion();
          expect(fakeRepository.removeCompletionCalled, true);
        });

        test('チュートリアルを終えるとログイン画面へ進む', () async {
          await viewModel.finishAccountDeletion();
          await viewModel.onClickDone();
          expect(viewState.destination?.type, OnboardingDestination.login);
        });
      });

      group('異常系', () {
        test('削除後に戻ってきた画面でなければ実行できない', () {
          setUpState();
          expect(() => viewModel.finishAccountDeletion(), throwsStateError);
        });

        // アカウントは消えている。後始末が転んでも、消えていないかのようには見せない
        test('チュートリアルフラグを消せなくてもサインアウトする', () async {
          setUpState(mode: .afterAccountDeletion);
          fakeRepository.shouldThrow = true;

          await viewModel.finishAccountDeletion();

          expect(fakeUserRepository.signOutCount, 1);
          expect(viewState.dialogMessage, isNull);
        });

        test('サインアウトできなくてもエラーにはしない', () async {
          setUpState(mode: .afterAccountDeletion);
          fakeUserRepository.shouldThrow = true;

          await viewModel.finishAccountDeletion();

          expect(viewState.dialogMessage, isNull);
        });
      });
    });
  });
}
