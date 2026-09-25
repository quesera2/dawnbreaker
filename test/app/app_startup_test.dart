import 'package:dawnbreaker/app/app_startup.dart';
import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:dawnbreaker/data/repository/user/firestore_user_settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_notification_service.dart';
import '../helpers/fake_user_repository.dart';
import '../helpers/fake_user_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late FakeNotificationService fakeNotificationService;

  void setUpContainer({AppUser user = const Guest('user-1')}) {
    fakeNotificationService = FakeNotificationService();
    final userRepository = FakeUserRepository(user);
    container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(userRepository),
        fcmNotificationServiceProvider.overrideWith(
          (_) => fakeNotificationService,
        ),
        userSettingsRepositoryProvider.overrideWith(
          (_) => FakeUserSettingsRepository(),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await userRepository.close();
    });
  }

  /// 起動処理を投げ、`unawaited` された処理が進むところまで待つ
  Future<void> startDeferredWork() async {
    AppStartup.startDeferredWork(container);
    await pumpEventQueue();
  }

  group('startDeferredWork', () {
    group('サインイン済みの場合', () {
      for (final (user, description) in [
        (const Guest('user-1'), '匿名アカウントの場合'),
        (const LoggedIn('user-1'), 'ソーシャルログイン済みの場合'),
      ]) {
        group(description, () {
          setUp(() => setUpContainer(user: user));

          test('通知先を登録する', () async {
            await startDeferredWork();
            expect(fakeNotificationService.registerTokenCount, 1);
          });
        });
      }
    });

    group('サインインしていない場合', () {
      setUp(() => setUpContainer(user: const NoLogin()));

      test('通知先を登録しない', () async {
        await startDeferredWork();
        expect(fakeNotificationService.registerTokenCount, 0);
      });
    });
  });
}
