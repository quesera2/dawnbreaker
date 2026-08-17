import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_impl.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/onboarding/viewmodel/onboarding_ui_state.dart';
import 'package:dawnbreaker/ui/onboarding/viewmodel/onboarding_view_model.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_notification_service.dart';
import '../../../helpers/fake_onboarding_repository.dart';
import '../../../helpers/fake_user_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingViewModel', () {
    late ProviderContainer container;
    late FakeOnboardingRepository fakeRepository;
    late FakeNotificationService fakeNotificationService;
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
      fakeNotificationService = FakeNotificationService();
      fakeUserRepository = FakeUserRepository(const LoggedIn('user-1'));
      container = ProviderContainer(
        overrides: [
          onboardingRepositoryProvider.overrideWith((_) => fakeRepository),
          fcmNotificationServiceProvider.overrideWith(
            (_) => fakeNotificationService,
          ),
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
    // 削除は設定画面ではなくこの画面が行う。設定画面を残したままサインアウトすると、
    // まだ生きている購読が NoLogin で走って例外になるため（ログアウトと同じ形）
    group('deleteAccount', () {
      group('正常系', () {
        setUp(() => setUpState(mode: .executeAccountDeletion));

        test('アカウントを消す', () async {
          await viewModel.deleteAccount();
          expect(fakeUserRepository.deleteAccountCount, 1);
        });

        // 捨てると FCM が新しいトークンを配るため、サインアウトより後に捨てる
        test('サインアウトしてからこの端末のトークンを捨てる', () async {
          await viewModel.deleteAccount();
          expect(fakeNotificationService.deleteTokenCount, 1);
        });

        test('消えたアカウントのセッションを残さない', () async {
          await viewModel.deleteAccount();
          expect(fakeUserRepository.signOutCount, 1);
        });

        test('開き直したときにチュートリアルから始まるようにする', () async {
          await viewModel.deleteAccount();
          expect(fakeRepository.removeCompletionCalled, true);
        });

        test('処理中は操作を塞ぐ', () async {
          final future = viewModel.deleteAccount();
          expect(viewState.isDeletingAccount, true);
          await future;
          expect(viewState.isDeletingAccount, false);
        });

        test('トークンを捨てられなくても削除は続く', () async {
          fakeNotificationService.deleteTokenShouldThrow = true;
          await viewModel.deleteAccount();
          expect(fakeUserRepository.deleteAccountCount, 1);
          expect(fakeUserRepository.signOutCount, 1);
        });

        test('チュートリアルを終えるとログイン画面へ進む', () async {
          await viewModel.deleteAccount();
          await viewModel.onClickDone();
          expect(viewState.destination?.type, OnboardingDestination.login);
        });
      });

      group('異常系', () {
        test('削除を引き受けていない画面では実行できない', () {
          setUpState();
          expect(() => viewModel.deleteAccount(), throwsStateError);
        });

        group('削除に失敗した場合', () {
          setUp(() {
            setUpState(mode: .executeAccountDeletion);
            fakeUserRepository.shouldFailDeleteAccount = true;
          });

          test('エラーが通知される', () async {
            await viewModel.deleteAccount();
            expect(viewState.dialogMessage, isA<DeleteAccountErrorMessage>());
          });

          test('消えていないのでサインアウトしない', () async {
            await viewModel.deleteAccount();
            expect(fakeUserRepository.signOutCount, 0);
            expect(fakeRepository.removeCompletionCalled, false);
          });

          test('消えていないので通知は受け取れるままにする', () async {
            await viewModel.deleteAccount();
            expect(fakeNotificationService.deleteTokenCount, 0);
          });

          // サインインしたままなので、ログイン画面へ出すと状態が食い違う
          for (final (action, description) in [
            ('done', 'チュートリアルを終えるとホーム画面へ戻る'),
            ('skip', 'チュートリアルをスキップするとホーム画面へ戻る'),
          ]) {
            test(description, () async {
              await viewModel.deleteAccount();
              viewState.dialogMessage!.secondaryHandler!();

              if (action == 'done') {
                await viewModel.onClickDone();
              } else {
                await viewModel.onClickSkip();
              }

              expect(viewState.destination?.type, OnboardingDestination.home);
            });
          }

          test('再試行するともう一度消しにいく', () async {
            await viewModel.deleteAccount();
            fakeUserRepository.shouldFailDeleteAccount = false;

            viewState.dialogMessage!.primaryHandler!();
            await pumpEventQueue();

            expect(fakeUserRepository.deleteAccountCount, 2);
            expect(fakeUserRepository.signOutCount, 1);
          });

          test('やめるとホーム画面へ戻る', () async {
            await viewModel.deleteAccount();

            viewState.dialogMessage!.secondaryHandler!();

            expect(viewState.destination?.type, OnboardingDestination.home);
          });

          test('操作を塞いだままにしない', () async {
            await viewModel.deleteAccount();

            expect(viewState.isDeletingAccount, false);
          });

          test('再試行がまた失敗したらもう一度知らせる', () async {
            await viewModel.deleteAccount();
            final firstMessage = viewState.dialogMessage!;

            firstMessage.primaryHandler!();
            await pumpEventQueue();

            expect(viewState.dialogMessage, isA<DeleteAccountErrorMessage>());
            expect(viewState.dialogMessage!.id, isNot(firstMessage.id));
          });
        });

        // アカウントは消えている。後始末が転んでも、消えていないかのようには見せない
        group('削除後の後始末に失敗した場合', () {
          setUp(() => setUpState(mode: .executeAccountDeletion));

          test('チュートリアルフラグを消せなくても削除は終わる', () async {
            fakeRepository.shouldThrow = true;

            await viewModel.deleteAccount();

            expect(fakeUserRepository.signOutCount, 1);
            expect(fakeNotificationService.deleteTokenCount, 1);
            expect(viewState.dialogMessage, isNull);
            expect(viewState.isDeletingAccount, false);
          });

          test('サインアウトできなくても削除は終わる', () async {
            fakeUserRepository.shouldThrow = true;

            await viewModel.deleteAccount();

            expect(fakeUserRepository.deleteAccountCount, 1);
            expect(viewState.dialogMessage, isNull);
            expect(viewState.isDeletingAccount, false);
          });
        });
      });
    });
  });
}
