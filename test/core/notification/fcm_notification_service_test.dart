import 'package:dawnbreaker/core/notification/fcm_notification_service_impl.dart';
import 'package:dawnbreaker/l10n/app_localizations_ja.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_firebase_messaging.dart';
import '../../helpers/fake_notification_token_repository.dart';

void main() {
  late FakeFirebaseMessaging messaging;
  late FakeNotificationTokenRepository repository;
  late FcmNotificationServiceImpl service;

  void setUpService({
    AuthorizationStatus authorizationStatus = AuthorizationStatus.authorized,
    String? token = 'test-token',
  }) {
    messaging = FakeFirebaseMessaging(
      authorizationStatus: authorizationStatus,
      token: token,
    );
    repository = FakeNotificationTokenRepository();
    service = FcmNotificationServiceImpl(
      repository: repository,
      messaging: messaging,
      l10n: AppLocalizationsJa(),
    );
  }

  group('registerToken', () {
    group('通知が許可されている場合', () {
      for (final (status, description) in [
        (AuthorizationStatus.authorized, '許可されているとき'),
        (AuthorizationStatus.provisional, '仮の許可のとき'),
      ]) {
        test('$description 通知先として登録される', () async {
          setUpService(authorizationStatus: status);
          await service.registerToken();
          expect(repository.addedTokens, ['test-token']);
        });
      }
    });

    group('通知が許可されていない場合', () {
      for (final (status, description) in [
        (AuthorizationStatus.denied, '拒否されているとき'),
        (AuthorizationStatus.notDetermined, 'まだ確認していないとき'),
      ]) {
        test('$description 通知先として登録されない', () async {
          setUpService(authorizationStatus: status);
          await service.registerToken();
          expect(repository.addedTokens, isEmpty);
        });
      }
    });

    group('トークンを取得できない場合', () {
      setUp(() => setUpService(token: null));

      test('通知先として登録されない', () async {
        await service.registerToken();
        expect(repository.addedTokens, isEmpty);
      });
    });
  });
}
