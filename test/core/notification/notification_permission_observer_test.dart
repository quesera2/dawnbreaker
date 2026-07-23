import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
import 'package:dawnbreaker/core/notification/notification_permission_observer.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:dawnbreaker/data/repository/user/user_settings_repository_exception.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_notification_service.dart';
import '../../helpers/fake_user_repository.dart';
import '../../helpers/fake_user_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late FakeNotificationService fakeNotificationService;
  late FakeUserSettingsRepository fakeUserSettingsRepository;

  void setUpContainer({
    bool notificationEnabled = true,
    bool checkPermissionResult = true,
    bool repositoryUnavailable = false,
    AppUser user = const Guest('user-1'),
  }) {
    fakeNotificationService = FakeNotificationService(
      checkPermissionResult: checkPermissionResult,
    );
    fakeUserSettingsRepository = FakeUserSettingsRepository(
      notificationSetting: NotificationSetting(enabled: notificationEnabled),
    );
    final userRepository = FakeUserRepository(user);
    container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(userRepository),
        fcmNotificationServiceProvider.overrideWith(
          (_) async => fakeNotificationService,
        ),
        userSettingsRepositoryProvider.overrideWith((_) async {
          if (repositoryUnavailable) {
            throw const UserSettingsLoadException('テストエラー');
          }
          return fakeUserSettingsRepository;
        }),
      ],
    );
    addTearDown(userRepository.close);
  }

  /// レジュームを通知し、`unawaited` された同期処理が終わるまで待つ
  Future<void> resume() async {
    container
        .read(notificationPermissionObserverProvider.notifier)
        .didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
  }

  tearDown(() => container.dispose());

  group('NotificationPermissionObserver', () {
    group('通知権限がある場合', () {
      setUp(() => setUpContainer());

      test('通知設定は有効なままになる', () async {
        await resume();
        expect(fakeUserSettingsRepository.notificationSetting.enabled, true);
      });

      test('設定を読みに行かない', () async {
        await resume();
        expect(fakeUserSettingsRepository.fetchNotificationSettingCount, 0);
      });
    });

    group('通知権限がない場合', () {
      // もとの設定に関わらず、現在値を読まずに無効を書き込む。読んでから書くと、
      // 権限を許可していないユーザーにレジュームのたびの読み取りを課すことになる
      for (final (notificationEnabled, description) in [
        (true, '設定が有効だったとき'),
        (false, '設定がもともと無効だったとき'),
      ]) {
        group(description, () {
          setUp(
            () => setUpContainer(
              notificationEnabled: notificationEnabled,
              checkPermissionResult: false,
            ),
          );

          test('通知設定が無効になる', () async {
            await resume();
            expect(
              fakeUserSettingsRepository.notificationSetting.enabled,
              false,
            );
          });

          test('現在の設定を読まずに 1 回だけ書き込む', () async {
            await resume();
            expect(fakeUserSettingsRepository.fetchNotificationSettingCount, 0);
            expect(fakeUserSettingsRepository.setNotificationEnabledCount, 1);
          });
        });
      }

      group('保存に失敗した場合', () {
        setUp(() => setUpContainer(checkPermissionResult: false));

        test('未捕捉の例外にならない', () async {
          fakeUserSettingsRepository.saveShouldThrow = true;
          await resume();
        });
      });
    });

    group('サインインしていない場合', () {
      setUp(() => setUpContainer(user: const NoLogin()));

      test('同期する設定がないため権限を確認しない', () async {
        await resume();
        expect(fakeNotificationService.checkPermissionCalled, false);
      });
    });

    group('リポジトリを取得できない場合', () {
      setUp(
        () => setUpContainer(
          repositoryUnavailable: true,
          checkPermissionResult: false,
        ),
      );

      test('未捕捉の例外にならない', () async {
        await resume();
      });
    });
  });
}
