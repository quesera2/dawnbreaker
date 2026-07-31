import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/login/viewmodel/login_ui_state.dart';
import 'package:dawnbreaker/ui/login/viewmodel/login_view_model.dart';
import 'package:dawnbreaker/ui/login/widgets/login_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_notification_service.dart';
import '../../../helpers/fake_user_repository.dart';
import '../../../helpers/fake_user_settings_repository.dart';

void main() {
  group('LoginViewModel', () {
    late ProviderContainer container;
    late FakeUserRepository fakeUserRepository;
    late FakeNotificationService fakeNotificationService;
    late FakeUserSettingsRepository fakeUserSettingsRepository;
    late LoginViewModelProvider provider;
    late LoginViewModel viewModel;
    late LoginUiState viewState;

    void setUpState([LoginMode mode = LoginMode.initial]) {
      provider = loginViewModelProvider(mode: mode);
      viewModel = container.read(provider.notifier);
      container.listen(
        provider,
        (_, next) => viewState = next,
        fireImmediately: true,
      );
    }

    /// ゲストとして使っている人がアカウントを結び付けにくる状況を作る
    void setUpPromotion() {
      fakeUserRepository.emit(const Guest('guest-1'));
      setUpState(LoginMode.promotion);
    }

    setUp(() {
      fakeUserRepository = FakeUserRepository(const NoLogin());
      fakeNotificationService = FakeNotificationService();
      fakeUserSettingsRepository = FakeUserSettingsRepository();
      container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWith((_) => fakeUserRepository),
          fcmNotificationServiceProvider.overrideWith(
            (_) => fakeNotificationService,
          ),
          userSettingsRepositoryProvider.overrideWith(
            (_) => fakeUserSettingsRepository,
          ),
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
        expect(viewState.isSigningIn, false);
      });

      test('遷移先が決まっていない', () {
        expect(viewState.destination, isNull);
      });
    });

    group('ゲストではじめる', () {
      setUp(setUpState);

      group('正常系', () {
        for (final (hasPermission, destination, description) in [
          (true, LoginDestination.home, '通知が許可済みならそのままホームへ進む'),
          (false, LoginDestination.notificationIntro, '通知が許可されていなければ通知の誘導を挟む'),
        ]) {
          test(description, () async {
            fakeNotificationService.checkPermissionResult = hasPermission;

            await viewModel.onClickStartAsGuest();

            expect(viewState.destination?.type, destination);
          });
        }

        test('ゲストのアカウントが作られる', () async {
          await viewModel.onClickStartAsGuest();

          expect(fakeUserRepository.signInAsGuestCount, 1);
        });

        // Android 12 以下は OS に通知の許可を求める仕組みがなく常に許可済みになるため、
        // 通知が有効になる経路はここだけになる
        test('通知が許可済みなら通知設定が有効になり通知先が登録される', () async {
          fakeNotificationService.checkPermissionResult = true;

          await viewModel.onClickStartAsGuest();
          await pumpEventQueue();

          expect(fakeUserSettingsRepository.notificationSetting.enabled, true);
          expect(fakeNotificationService.registerTokenCount, 1);
        });

        // 別端末で設定済みの通知時刻を初期値に戻さない
        test('通知が許可済みでも設定済みの通知時刻は保たれる', () async {
          fakeNotificationService.checkPermissionResult = true;
          fakeUserSettingsRepository.notificationSetting =
              const NotificationSetting(hour: 7, minute: 30);

          await viewModel.onClickStartAsGuest();
          await pumpEventQueue();

          final saved = fakeUserSettingsRepository.notificationSetting;
          expect(saved.enabled, true);
          expect(saved.hour, 7);
          expect(saved.minute, 30);
        });

        test('通知が許可されていなければ通知設定は無効なままになる', () async {
          fakeNotificationService.checkPermissionResult = false;

          await viewModel.onClickStartAsGuest();
          await pumpEventQueue();

          expect(fakeUserSettingsRepository.notificationSetting.enabled, false);
          expect(fakeNotificationService.registerTokenCount, 0);
        });

        // オフラインだと Firestore の書き込みが完了しないため、待つとホームへ進めなくなる
        test('通知設定の保存を待たずにホームへ進む', () async {
          fakeNotificationService.checkPermissionResult = true;
          fakeUserSettingsRepository.neverCompletes = true;

          await viewModel.onClickStartAsGuest();

          expect(viewState.destination?.type, LoginDestination.home);
        });

        test('通知設定を保存できなくてもホームへ進む', () async {
          fakeNotificationService.checkPermissionResult = true;
          fakeUserSettingsRepository.saveShouldThrow = true;

          await viewModel.onClickStartAsGuest();
          await pumpEventQueue();

          expect(viewState.destination?.type, LoginDestination.home);
        });

        test('ボタンが操作可能な状態に戻る', () async {
          await viewModel.onClickStartAsGuest();

          expect(viewState.isSigningIn, false);
        });

        test('最終アクティブ日時が更新される', () async {
          await viewModel.onClickStartAsGuest();
          await Future<void>.delayed(Duration.zero);

          expect(fakeUserSettingsRepository.updateLastActiveAtCount, 1);
        });

        // 放置アカウントの回収に使うだけの値なので、ここで止めない
        test('最終アクティブ日時を更新できなくてもホームへ進む', () async {
          fakeUserSettingsRepository.saveShouldThrow = true;

          await viewModel.onClickStartAsGuest();
          await Future<void>.delayed(Duration.zero);

          expect(viewState.destination?.type, LoginDestination.home);
        });

        // 誘導を出すかどうかを決めるだけの問い合わせなので、ここで止めない
        test('通知の状態を確認できなくてもホームへ進む', () async {
          fakeNotificationService.checkPermissionShouldThrow = true;

          await viewModel.onClickStartAsGuest();

          expect(viewState.destination?.type, LoginDestination.home);
        });
      });

      group('異常系', () {
        setUp(() {
          fakeUserRepository.shouldThrow = true;
        });

        test('エラーが通知される', () async {
          await viewModel.onClickStartAsGuest();

          expect(viewState.dialogMessage, isA<SignInErrorMessage>());
        });

        test('画面遷移しない', () async {
          await viewModel.onClickStartAsGuest();

          expect(viewState.destination, isNull);
        });

        test('ボタンが操作可能な状態に戻る', () async {
          await viewModel.onClickStartAsGuest();

          expect(viewState.isSigningIn, false);
        });

        test('その場で再試行できる', () async {
          await viewModel.onClickStartAsGuest();
          fakeUserRepository.shouldThrow = false;

          viewState.dialogMessage?.primaryHandler?.call();
          await Future<void>.delayed(Duration.zero);

          expect(fakeUserRepository.signInAsGuestCount, 2);
          expect(viewState.destination?.type, LoginDestination.home);
        });
      });
    });

    group('Google でサインイン', () {
      setUp(setUpState);

      group('正常系', () {
        for (final (hasPermission, destination, description) in [
          (true, LoginDestination.home, '通知が許可済みならそのままホームへ進む'),
          (false, LoginDestination.notificationIntro, '通知が許可されていなければ通知の誘導を挟む'),
        ]) {
          test(description, () async {
            fakeNotificationService.checkPermissionResult = hasPermission;

            await viewModel.onClickSignInWithGoogle();

            expect(viewState.destination?.type, destination);
          });
        }

        test('サインインが 1 度だけ呼ばれる', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(fakeUserRepository.signInWithGoogleCount, 1);
        });

        test('ボタンが操作可能な状態に戻る', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(viewState.isSigningIn, false);
        });

        test('最終アクティブ日時が更新される', () async {
          await viewModel.onClickSignInWithGoogle();
          await Future<void>.delayed(Duration.zero);

          expect(fakeUserSettingsRepository.updateLastActiveAtCount, 1);
        });
      });

      // ユーザーが認証画面を閉じただけ。失敗ではない
      group('中断したとき', () {
        setUp(() {
          fakeUserRepository.cancelSignIn = true;
        });

        test('エラーは出さない', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(viewState.dialogMessage, isNull);
        });

        test('画面遷移しない', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(viewState.destination, isNull);
        });

        test('ボタンが操作可能な状態に戻る', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(viewState.isSigningIn, false);
        });
      });

      group('異常系', () {
        setUp(() {
          fakeUserRepository.shouldThrow = true;
        });

        test('エラーが通知される', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(viewState.dialogMessage, isA<SignInErrorMessage>());
        });

        test('画面遷移しない', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(viewState.destination, isNull);
        });

        test('ボタンが操作可能な状態に戻る', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(viewState.isSigningIn, false);
        });

        test('その場で再試行できる', () async {
          await viewModel.onClickSignInWithGoogle();
          fakeUserRepository.shouldThrow = false;

          viewState.dialogMessage?.primaryHandler?.call();
          await Future<void>.delayed(Duration.zero);

          expect(fakeUserRepository.signInWithGoogleCount, 2);
          expect(viewState.destination?.type, LoginDestination.home);
        });
      });
    });

    group('ゲストから昇格する', () {
      setUp(setUpPromotion);

      group('正常系', () {
        test('ゲストのデータを保ったままアカウントを結び付ける', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(fakeUserRepository.linkWithGoogleCount, 1);
          expect(fakeUserRepository.signInWithGoogleCount, 0);
        });

        // ゲストとして使っていた時点で通知の誘導は済んでいる
        test('通知の誘導を挟まず元の画面へ戻る', () async {
          fakeNotificationService.checkPermissionResult = false;

          await viewModel.onClickSignInWithGoogle();

          expect(viewState.destination?.type, LoginDestination.back);
        });

        test('通知の送信先が登録される', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(fakeNotificationService.registerTokenCount, 1);
        });

        test('最終アクティブ日時が更新される', () async {
          await viewModel.onClickSignInWithGoogle();
          await Future<void>.delayed(Duration.zero);

          expect(fakeUserSettingsRepository.updateLastActiveAtCount, 1);
        });

        test('ボタンが操作可能な状態に戻る', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(viewState.isSigningIn, false);
        });

        // 送信先の登録はサインインの成否とは別の話なので、ここで足を止めない
        test('通知の送信先を登録できなくても元の画面へ戻る', () async {
          fakeNotificationService.registerTokenShouldThrow = true;

          await viewModel.onClickSignInWithGoogle();

          expect(viewState.destination?.type, LoginDestination.back);
        });
      });

      // ユーザーが認証画面を閉じただけ。失敗ではない
      group('中断したとき', () {
        setUp(() {
          fakeUserRepository.cancelSignIn = true;
        });

        test('エラーは出さない', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(viewState.dialogMessage, isNull);
        });

        test('画面遷移しない', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(viewState.destination, isNull);
        });

        test('ボタンが操作可能な状態に戻る', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(viewState.isSigningIn, false);
        });
      });

      // 昇格先のアカウントが既にある場合。ゲストのデータは引き継げない
      group('アカウントが既に使われているとき', () {
        setUp(() {
          fakeUserRepository.credentialAlreadyInUse = true;
        });

        test('データが失われることを確認する', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(viewState.dialogMessage, isA<SwitchAccountConfirmMessage>());
        });

        test('了承するまでサインインしない', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(fakeUserRepository.signInWithLinkedCredentialCount, 0);
          expect(viewState.destination, isNull);
        });

        test('了承すると乗り換えて元の画面へ戻る', () async {
          await viewModel.onClickSignInWithGoogle();

          viewState.dialogMessage?.primaryHandler?.call();
          await pumpEventQueue();

          expect(fakeUserRepository.signInWithLinkedCredentialCount, 1);
          expect(viewState.destination?.type, LoginDestination.back);
        });

        // 捨てるアカウント宛の通知がこの端末に届き続けないようにする
        test('通知の送信先が乗り換え先のアカウントに移る', () async {
          await viewModel.onClickSignInWithGoogle();

          viewState.dialogMessage?.primaryHandler?.call();
          await pumpEventQueue();

          expect(fakeNotificationService.unregisterTokenCount, 1);
          expect(fakeNotificationService.registerTokenCount, 1);
        });

        test('乗り換えに失敗したらエラーが通知される', () async {
          await viewModel.onClickSignInWithGoogle();
          fakeUserRepository.shouldThrow = true;

          viewState.dialogMessage?.primaryHandler?.call();
          await pumpEventQueue();

          expect(viewState.dialogMessage, isA<SignInErrorMessage>());
          expect(viewState.destination, isNull);
          expect(viewState.isSigningIn, false);
        });
      });

      group('異常系', () {
        setUp(() {
          fakeUserRepository.shouldThrow = true;
        });

        test('エラーが通知される', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(viewState.dialogMessage, isA<SignInErrorMessage>());
        });

        test('画面遷移しない', () async {
          await viewModel.onClickSignInWithGoogle();

          expect(viewState.destination, isNull);
        });

        test('その場で再試行できる', () async {
          await viewModel.onClickSignInWithGoogle();
          fakeUserRepository.shouldThrow = false;

          viewState.dialogMessage?.primaryHandler?.call();
          await pumpEventQueue();

          expect(fakeUserRepository.linkWithGoogleCount, 2);
          expect(viewState.destination?.type, LoginDestination.back);
        });
      });
    });
  });
}
