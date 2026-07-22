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
            (_) async => fakeNotificationService,
          ),
          userSettingsRepositoryProvider.overrideWith(
            (_) async => fakeUserSettingsRepository,
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

        // 断られたときは users/{uid} の初期値（通知 OFF）のままにする
        test('許可されなければ何も書かずにホームへ進む', () async {
          fakeNotificationService.permissionResult = false;

          await viewModel.onClickEnable();

          expect(fakeUserSettingsRepository.notificationSetting.enabled, false);
          expect(fakeNotificationService.registerTokenCount, 0);
          expect(viewState.completed, isNotNull);
        });

        test('ボタンが操作可能な状態に戻る', () async {
          await viewModel.onClickEnable();

          expect(viewState.isEnabling, false);
        });
      });

      group('異常系', () {
        setUp(() {
          fakeUserSettingsRepository.shouldThrow = true;
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
