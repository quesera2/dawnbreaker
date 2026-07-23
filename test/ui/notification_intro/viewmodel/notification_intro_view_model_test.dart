import 'dart:async';

import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/notification_intro/viewmodel/notification_intro_ui_state.dart';
import 'package:dawnbreaker/ui/notification_intro/viewmodel/notification_intro_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_notification_service.dart';
import '../../../helpers/fake_user_settings_repository.dart';

void main() {
  group('NotificationIntroViewModel', () {
    late ProviderContainer container;
    late FakeNotificationService fakeNotificationService;
    late FakeUserSettingsRepository fakeUserSettingsRepository;
    late NotificationIntroViewModel viewModel;
    late NotificationIntroUiState viewState;

    void setUpState() {
      viewModel = container.read(notificationIntroViewModelProvider.notifier);
      container.listen(
        notificationIntroViewModelProvider,
        (_, next) => viewState = next,
        fireImmediately: true,
      );
    }

    setUp(() {
      fakeNotificationService = FakeNotificationService();
      fakeUserSettingsRepository = FakeUserSettingsRepository();
      container = ProviderContainer(
        overrides: [
          fcmNotificationServiceProvider.overrideWith(
            (_) => fakeNotificationService,
          ),
          userSettingsRepositoryProvider.overrideWith(
            (_) => fakeUserSettingsRepository,
          ),
        ],
      );
      setUpState();
    });

    tearDown(() => container.dispose());

    group('初期状態', () {
      test('ボタンが操作可能な状態である', () {
        expect(viewState.isEnabling, false);
      });

      test('ホームへ進まない', () {
        expect(viewState.completed, isNull);
      });
    });

    group('通知を有効にする', () {
      group('正常系', () {
        test('許可されたら通知設定が有効になり通知先が登録される', () async {
          await viewModel.onClickEnable();

          expect(fakeUserSettingsRepository.notificationSetting.enabled, true);
          expect(fakeNotificationService.registerTokenCount, 1);
          expect(viewState.completed, isNotNull);
        });

        // 既存アカウントで別端末からサインインするとこの画面を通る
        test('設定済みの通知時刻を保ったまま有効になる', () async {
          fakeUserSettingsRepository.notificationSetting =
              const NotificationSetting(
                hour: 7,
                minute: 30,
                notifyDay: .yesterday,
              );

          await viewModel.onClickEnable();

          final saved = fakeUserSettingsRepository.notificationSetting;
          expect(saved.enabled, true);
          expect(saved.hour, 7);
          expect(saved.minute, 30);
          expect(saved.notifyDay, NotifyDay.yesterday);
        });

        test('ボタンが操作可能な状態に戻る', () async {
          await viewModel.onClickEnable();

          expect(viewState.isEnabling, false);
        });
      });

      group('許可されなかった場合', () {
        setUp(() {
          fakeNotificationService.permissionResult = false;
        });

        // users/{uid} の初期値（通知 OFF）のままにする
        test('何も書かない', () async {
          await viewModel.onClickEnable();

          expect(fakeUserSettingsRepository.notificationSetting.enabled, false);
          expect(fakeNotificationService.registerTokenCount, 0);
        });

        // 一度断った端末では OS がダイアログを出さないため、設定アプリへ誘導する
        test('OS の設定へ誘導される', () async {
          await viewModel.onClickEnable();

          expect(
            viewState.dialogMessage,
            isA<NotificationPermissionDeniedMessage>(),
          );
        });

        test('ホームへ進まない', () async {
          await viewModel.onClickEnable();

          expect(viewState.completed, isNull);
        });

        test('ボタンが操作可能な状態に戻る', () async {
          await viewModel.onClickEnable();

          expect(viewState.isEnabling, false);
        });
      });

      // OS の許可も通知先の登録も済んでいるのに設定だけ書けない状態。ホームへ進めると
      // 通知が有効になったと誤解させたまま、実際には配信されない
      group('異常系', () {
        group('設定を保存できない場合', () {
          setUp(() {
            fakeUserSettingsRepository.saveShouldThrow = true;
          });

          test('エラーが通知される', () async {
            await viewModel.onClickEnable();

            expect(
              viewState.dialogMessage,
              isA<NotificationEnableErrorMessage>(),
            );
          });

          test('ホームへ進まない', () async {
            await viewModel.onClickEnable();

            expect(viewState.completed, isNull);
          });

          test('ボタンが操作可能な状態に戻る', () async {
            await viewModel.onClickEnable();

            expect(viewState.isEnabling, false);
          });

          test('通知設定は無効なままになる', () async {
            await viewModel.onClickEnable();

            expect(
              fakeUserSettingsRepository.notificationSetting.enabled,
              false,
            );
          });
        });
      });
    });

    group('あとで', () {
      test('何も書かずにホームへ進む', () {
        viewModel.onSkip();

        expect(fakeUserSettingsRepository.notificationSetting.enabled, false);
        expect(fakeNotificationService.requestPermissionCalled, false);
        expect(viewState.completed, isNotNull);
      });

      // 戻る操作もここを通る。書き込みの結果を捨てて画面を降りさせない
      test('有効化の最中は受け付けない', () async {
        fakeUserSettingsRepository.neverCompletes = true;
        unawaited(viewModel.onClickEnable());
        await Future<void>.delayed(Duration.zero);

        viewModel.onSkip();

        expect(viewState.completed, isNull);
      });
    });
  });
}
