import 'package:app_settings/app_settings.dart';
import 'package:app_settings/app_settings_platform_interface.dart';
import 'package:dawnbreaker/core/notification/notification_service_impl.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_impl.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository_impl.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:dawnbreaker/ui/settings/viewmodel/settings_ui_state.dart';
import 'package:dawnbreaker/ui/settings/viewmodel/settings_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../helpers/fake_notification_service.dart';
import '../../../helpers/fake_onboarding_repository.dart';
import '../../../helpers/fake_settings_repository.dart';
import '../../../helpers/mock_app_settings_platform.dart';
import '../../../helpers/riverpod_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late SettingsViewModel viewModel;
  late SettingsUiState viewState;
  late FakeOnboardingRepository fakeOnboardingRepository;
  late FakeSettingsRepository fakeSettingsRepository;
  late FakeNotificationService fakeNotificationService;

  void setUpContainer({
    bool notificationEnabled = true,
    bool checkPermissionResult = true,
    bool permissionResult = true,
    bool canScheduleExactAlarmsResult = true,
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
      initialNotificationEnabled: notificationEnabled,
    );
    fakeNotificationService = FakeNotificationService(
      checkPermissionResult: checkPermissionResult,
      permissionResult: permissionResult,
      canScheduleExactAlarmsResult: canScheduleExactAlarmsResult,
    );
    container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(fakeSettingsRepository),
        onboardingRepositoryProvider.overrideWith(
          (_) => fakeOnboardingRepository,
        ),
        notificationServiceProvider.overrideWith(
          (_) async => fakeNotificationService,
        ),
      ],
    );
  }

  Future<void> setUpLoaded({
    bool notificationEnabled = true,
    bool checkPermissionResult = true,
    bool permissionResult = true,
    bool canScheduleExactAlarmsResult = true,
  }) async {
    setUpContainer(
      notificationEnabled: notificationEnabled,
      checkPermissionResult: checkPermissionResult,
      permissionResult: permissionResult,
      canScheduleExactAlarmsResult: canScheduleExactAlarmsResult,
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
          expect(viewState.notificationEnabled, true);
        });
      });

      group('通知が無効な場合', () {
        setUp(() async => setUpLoaded(notificationEnabled: false));

        test('通知が無効である', () {
          expect(viewState.notificationEnabled, false);
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
            expect(viewState.notificationEnabled, false);
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
              expect(viewState.notificationEnabled, true);
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
              expect(viewState.notificationEnabled, true);
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
              expect(viewState.notificationEnabled, false);
            });

            test('権限拒否ダイアログが表示される', () async {
              await viewModel.setNotificationEnabled(true);
              expect(
                viewState.dialogMessage,
                isA<NotificationPermissionDeniedMessage>(),
              );
            });

            test('ハンドラを呼び出すとアプリの通知設定が開かれる', () async {
              await viewModel.setNotificationEnabled(true);
              viewState.dialogMessage!.primaryHandler!();
              await pumpEventQueue();
              expect(mockAppSettings.openedType, AppSettingsType.notification);
            });
          });

          group('exactAlarmの許可が必要な場合', () {
            setUp(
              () async => setUpLoaded(
                notificationEnabled: false,
                checkPermissionResult: false,
                permissionResult: true,
                canScheduleExactAlarmsResult: false,
              ),
            );

            test('exactAlarm許可ダイアログが表示される', () async {
              await viewModel.setNotificationEnabled(true);
              expect(
                viewState.dialogMessage,
                isA<ExactAlarmPermissionRequestMessage>(),
              );
            });

            test('ハンドラを呼び出すとアラームとリマインダー設定が開かれる', () async {
              await viewModel.setNotificationEnabled(true);
              viewState.dialogMessage!.primaryHandler!.call();
              await pumpEventQueue();
              expect(
                fakeNotificationService.requestExactAlarmPermissionCalled,
                true,
              );
            });
          });
        });
      });

      group('通知設定の外部変更', () {
        setUp(() async => setUpLoaded());

        test('リポジトリの変更がstateに反映される', () async {
          await fakeSettingsRepository.setNotificationEnabled(false);
          await pumpEventQueue();
          expect(viewState.notificationEnabled, false);
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
    });
  });
}
