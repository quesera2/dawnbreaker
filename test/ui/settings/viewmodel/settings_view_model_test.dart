import 'package:app_settings/app_settings.dart';
import 'package:app_settings/app_settings_platform_interface.dart';
import 'package:dawnbreaker/core/notification/fcm_token_service_impl.dart';
import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart'
    show NotificationSetting, NotifyDay;
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_impl.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository_impl.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/settings/viewmodel/settings_ui_state.dart';
import 'package:dawnbreaker/ui/settings/viewmodel/settings_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../helpers/fake_fcm_token_service.dart';
import '../../../helpers/fake_onboarding_repository.dart';
import '../../../helpers/fake_settings_repository.dart';
import '../../../helpers/fake_user_settings_repository.dart';
import '../../../helpers/mock_app_settings_platform.dart';
import '../../../helpers/riverpod_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late SettingsViewModel viewModel;
  late SettingsUiState viewState;
  late FakeOnboardingRepository fakeOnboardingRepository;
  late FakeSettingsRepository fakeSettingsRepository;
  late FakeFcmTokenService fakeFcmTokenService;
  late FakeUserSettingsRepository fakeUserSettingsRepository;

  void setUpContainer({
    bool notificationEnabled = true,
    bool checkPermissionResult = true,
    bool permissionResult = true,
    HomeDisplayMode initialDisplayMode = HomeDisplayMode.timeline,
    bool initialProgressBarAnimationEnabled = true,
  }) {
    PackageInfo.setMockInitialValues(
      appName: 'dawnbreaker',
      packageName: 'com.example.dawnbreaker',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: '',
    );
    fakeOnboardingRepository = FakeOnboardingRepository();
    fakeSettingsRepository = FakeSettingsRepository(
      initialDisplayMode: initialDisplayMode,
      initialProgressBarAnimationEnabled: initialProgressBarAnimationEnabled,
    );
    fakeUserSettingsRepository = FakeUserSettingsRepository(
      notificationSetting: NotificationSetting(enabled: notificationEnabled),
    );
    fakeFcmTokenService = FakeFcmTokenService(
      checkPermissionResult: checkPermissionResult,
      permissionResult: permissionResult,
    );
    container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(fakeSettingsRepository),
        onboardingRepositoryProvider.overrideWith(
          (_) => fakeOnboardingRepository,
        ),
        fcmTokenServiceProvider.overrideWith((_) async => fakeFcmTokenService),
        userSettingsRepositoryProvider.overrideWith(
          (_) async => fakeUserSettingsRepository,
        ),
      ],
    );
  }

  Future<void> setUpLoaded({
    bool notificationEnabled = true,
    bool checkPermissionResult = true,
    bool permissionResult = true,
    HomeDisplayMode initialDisplayMode = HomeDisplayMode.timeline,
    bool initialProgressBarAnimationEnabled = true,
  }) async {
    setUpContainer(
      notificationEnabled: notificationEnabled,
      checkPermissionResult: checkPermissionResult,
      permissionResult: permissionResult,
      initialDisplayMode: initialDisplayMode,
      initialProgressBarAnimationEnabled: initialProgressBarAnimationEnabled,
    );
    await waitUntil(container, settingsViewModelProvider, (s) => !s.isLoading);
    viewModel = container.read(settingsViewModelProvider.notifier);
    container.listen(
      settingsViewModelProvider,
      (_, next) => viewState = next,
      fireImmediately: true,
    );
  }

  tearDown(() => container.dispose());

  group('SettingsViewModel', () {
    group('初期状態', () {
      setUp(() => setUpContainer());

      test('読み込み中である', () {
        expect(container.read(settingsViewModelProvider).isLoading, true);
      });

      test('バージョンが空である', () {
        expect(container.read(settingsViewModelProvider).version, isEmpty);
      });
    });

    group('ロード後', () {
      group('通知が有効な場合', () {
        setUp(() async => setUpLoaded());

        test('読み込みが完了している', () {
          expect(viewState.isLoading, false);
        });

        test('バージョンが表示される', () {
          expect(viewState.version, '1.2.3');
        });

        test('通知が有効である', () {
          expect(viewState.notificationSetting.enabled, true);
        });
      });

      group('通知が無効な場合', () {
        setUp(() async => setUpLoaded(notificationEnabled: false));

        test('通知が無効である', () {
          expect(viewState.notificationSetting.enabled, false);
        });
      });

      group('setNotificationEnabled', () {
        group('falseの場合', () {
          setUp(() async => setUpLoaded());

          test('処理中はisNotificationUpdatingがtrueになる', () async {
            final future = viewModel.setNotificationEnabled(false);
            expect(viewState.isNotificationUpdating, true);
            await future;
            expect(viewState.isNotificationUpdating, false);
          });

          test('通知が無効になる', () async {
            await viewModel.setNotificationEnabled(false);
            expect(viewState.notificationSetting.enabled, false);
          });
        });

        group('保存がオフラインで完了しない場合', () {
          setUp(() async {
            await setUpLoaded();
            fakeUserSettingsRepository.neverCompletes = true;
          });

          test('保存を待たずにisNotificationUpdatingがfalseに戻る', () async {
            await viewModel.setNotificationEnabled(false);
            expect(viewState.isNotificationUpdating, false);
          });

          test('画面上は通知が無効になる', () async {
            await viewModel.setNotificationEnabled(false);
            expect(viewState.notificationSetting.enabled, false);
          });
        });

        group('保存に失敗した場合', () {
          setUp(() async {
            await setUpLoaded();
            fakeUserSettingsRepository.shouldThrow = true;
          });

          test('例外は呼び出し元に伝播しない', () async {
            await expectLater(
              viewModel.setNotificationEnabled(false),
              completes,
            );
          });

          test('isNotificationUpdatingがfalseに戻る', () async {
            await viewModel.setNotificationEnabled(false);
            expect(viewState.isNotificationUpdating, false);
          });
        });

        group('trueの場合', () {
          group('権限がある場合', () {
            setUp(
              () async => setUpLoaded(
                notificationEnabled: false,
                checkPermissionResult: true,
              ),
            );

            test('通知が有効になる', () async {
              await viewModel.setNotificationEnabled(true);
              expect(viewState.notificationSetting.enabled, true);
            });

            test('権限取得ダイアログを表示しない', () async {
              await viewModel.setNotificationEnabled(true);
              expect(viewState.dialogMessage, isNull);
            });
          });

          group('権限がなく取得に成功した場合', () {
            setUp(
              () async => setUpLoaded(
                notificationEnabled: false,
                checkPermissionResult: false,
                permissionResult: true,
              ),
            );

            test('通知が有効になる', () async {
              await viewModel.setNotificationEnabled(true);
              expect(viewState.notificationSetting.enabled, true);
            });

            test('通知先が登録される', () async {
              await viewModel.setNotificationEnabled(true);
              expect(fakeFcmTokenService.registerTokenCount, 1);
            });
          });

          group('権限がなく取得に失敗した場合', () {
            late FakeAppSettingsPlatform mockAppSettings;

            setUp(() async {
              AppSettings();
              mockAppSettings = FakeAppSettingsPlatform();
              AppSettingsPlatform.instance = mockAppSettings;
              await setUpLoaded(
                notificationEnabled: false,
                checkPermissionResult: false,
                permissionResult: false,
              );
            });

            test('通知がOFFのままになる', () async {
              await viewModel.setNotificationEnabled(true);
              expect(viewState.notificationSetting.enabled, false);
            });

            test('権限拒否ダイアログが表示される', () async {
              await viewModel.setNotificationEnabled(true);
              expect(
                viewState.dialogMessage,
                isA<NotificationPermissionDeniedMessage>(),
              );
            });

            test('通知先が登録されない', () async {
              await viewModel.setNotificationEnabled(true);
              expect(fakeFcmTokenService.registerTokenCount, 0);
            });

            test('ハンドラを呼び出すとアプリの通知設定が開かれる', () async {
              await viewModel.setNotificationEnabled(true);
              viewState.dialogMessage!.primaryHandler!();
              await pumpEventQueue();
              expect(mockAppSettings.openedType, AppSettingsType.notification);
            });
          });
        });
      });

      group('setNotificationTime', () {
        setUp(() async => setUpLoaded());

        test('通知時間が更新される', () async {
          await viewModel.setNotificationTime(
            notifyDay: NotifyDay.yesterday,
            hour: 20,
            minute: 30,
          );
          await pumpEventQueue();
          expect(viewState.notificationSetting.notifyDay, NotifyDay.yesterday);
          expect(viewState.notificationSetting.hour, 20);
          expect(viewState.notificationSetting.minute, 30);
        });

        test('通知のON/OFFは変わらない', () async {
          await viewModel.setNotificationTime(
            notifyDay: NotifyDay.today,
            hour: 8,
            minute: 0,
          );
          await pumpEventQueue();
          expect(viewState.notificationSetting.enabled, true);
        });

        test('リポジトリに保存される', () async {
          await viewModel.setNotificationTime(
            notifyDay: NotifyDay.yesterday,
            hour: 22,
            minute: 0,
          );
          expect(
            fakeUserSettingsRepository.notificationSetting.notifyDay,
            NotifyDay.yesterday,
          );
          expect(fakeUserSettingsRepository.notificationSetting.hour, 22);
        });
      });

      group('表示モードの初期値', () {
        group('タイムラインの場合', () {
          setUp(() async => setUpLoaded());

          test('表示モードがタイムラインである', () {
            expect(viewState.displayMode, HomeDisplayMode.timeline);
          });
        });

        group('カラーグループの場合', () {
          setUp(
            () async =>
                setUpLoaded(initialDisplayMode: HomeDisplayMode.byColor),
          );

          test('表示モードがカラーグループである', () {
            expect(viewState.displayMode, HomeDisplayMode.byColor);
          });
        });
      });

      group('表示モードの外部変更', () {
        setUp(() async => setUpLoaded());

        test('リポジトリの変更がstateに反映される', () async {
          await fakeSettingsRepository.setHomeDisplayMode(
            HomeDisplayMode.byColor,
          );
          await pumpEventQueue();
          expect(viewState.displayMode, HomeDisplayMode.byColor);
        });
      });

      group('通知設定の外部変更', () {
        setUp(() async => setUpLoaded());

        test('リポジトリの変更がstateに反映される', () async {
          await fakeUserSettingsRepository.setNotificationSetting(
            const NotificationSetting(enabled: false),
          );
          await pumpEventQueue();
          expect(viewState.notificationSetting.enabled, false);
        });
      });

      group('deleteTutorialFlag', () {
        setUp(() async => setUpLoaded());

        test('チュートリアルフラグが削除される', () async {
          await viewModel.deleteTutorialFlag();
          expect(fakeOnboardingRepository.removeCompletionCalled, true);
        });

        test('完了メッセージが表示される', () async {
          await viewModel.deleteTutorialFlag();
          expect(viewState.snackBarMessage, isA<TutorialFlagResetMessage>());
        });
      });

      group('プログレスバーアニメーションの初期値', () {
        for (final (enabled, label) in [(true, '有効'), (false, '無効')]) {
          test('$labelが正しく読み込まれる', () async {
            await setUpLoaded(initialProgressBarAnimationEnabled: enabled);
            expect(viewState.progressBarAnimationEnabled, enabled);
          });
        }
      });

      group('setProgressBarAnimationEnabled', () {
        setUp(() async => setUpLoaded());

        test('アニメーションが無効になる', () async {
          await viewModel.setProgressBarAnimationEnabled(false);
          await pumpEventQueue();
          expect(viewState.progressBarAnimationEnabled, false);
        });

        test('リポジトリに保存される', () async {
          await viewModel.setProgressBarAnimationEnabled(false);
          expect(fakeSettingsRepository.progressBarAnimationEnabled, false);
        });
      });

      group('プログレスバーアニメーションの外部変更', () {
        setUp(() async => setUpLoaded());

        test('リポジトリの変更がstateに反映される', () async {
          await fakeSettingsRepository.setProgressBarAnimationEnabled(false);
          await pumpEventQueue();
          expect(viewState.progressBarAnimationEnabled, false);
        });
      });
    });
  });
}
