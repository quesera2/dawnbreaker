import 'package:dawnbreaker/core/notification/notification_permission_observer.dart';
import 'package:dawnbreaker/core/notification/notification_service_impl.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:dawnbreaker/data/repository/user/user_settings_repository_exception.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_notification_service.dart';
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
  }) {
    fakeNotificationService = FakeNotificationService(
      checkPermissionResult: checkPermissionResult,
    );
    fakeUserSettingsRepository = FakeUserSettingsRepository(
      notificationSetting: NotificationSetting(enabled: notificationEnabled),
    );
    container = ProviderContainer(
      overrides: [
        notificationServiceProvider.overrideWith(
          (_) async => fakeNotificationService,
        ),
        userSettingsRepositoryProvider.overrideWith((_) async {
          if (repositoryUnavailable) {
            throw const UnsupportedUserException('テストエラー');
          }
          return fakeUserSettingsRepository;
        }),
      ],
    );
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
    group('通知が有効な場合', () {
      group('通知権限がある場合', () {
        setUp(() => setUpContainer());

        test('通知設定は有効なままになる', () async {
          await resume();
          expect(fakeUserSettingsRepository.notificationSetting.enabled, true);
        });

        test('exactAlarmの権限が同期される', () async {
          await resume();
          expect(fakeNotificationService.syncExactAlarmPermissionCalled, true);
        });
      });

      group('通知権限が剥奪された場合', () {
        setUp(() => setUpContainer(checkPermissionResult: false));

        test('通知設定が無効になる', () async {
          await resume();
          expect(fakeUserSettingsRepository.notificationSetting.enabled, false);
        });

        test('exactAlarmの権限が同期される', () async {
          await resume();
          expect(fakeNotificationService.syncExactAlarmPermissionCalled, true);
        });

        test('保存が失敗しても未捕捉の例外にならない', () async {
          fakeUserSettingsRepository.shouldThrow = true;
          await resume();
          expect(fakeNotificationService.syncExactAlarmPermissionCalled, true);
        });

        test('保存がオフラインで完了しなくてもexactAlarmの同期に進む', () async {
          fakeUserSettingsRepository.neverCompletes = true;
          await resume();
          expect(fakeNotificationService.syncExactAlarmPermissionCalled, true);
        });
      });
    });

    group('通知が無効な場合', () {
      setUp(() => setUpContainer(notificationEnabled: false));

      test('権限を確認しない', () async {
        await resume();
        expect(fakeNotificationService.checkPermissionCalled, false);
      });
    });

    group('リポジトリの取得に失敗した場合', () {
      setUp(() => setUpContainer(repositoryUnavailable: true));

      test('未捕捉の例外にならず権限確認も行われない', () async {
        await resume();
        expect(fakeNotificationService.checkPermissionCalled, false);
      });
    });
  });
}
