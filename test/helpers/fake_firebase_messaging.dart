import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

/// FirebaseMessaging はメンバーが多く、FcmTokenService が使うのは
/// getNotificationSettings / getToken の 2 つだけなので、Fake で必要な分だけ実装する。
/// 実装していないメンバーを呼ぶと UnimplementedError になる。
class FakeFirebaseMessaging extends Fake implements FirebaseMessaging {
  FakeFirebaseMessaging({
    this.authorizationStatus = AuthorizationStatus.authorized,
    this.token = 'test-token',
  });

  AuthorizationStatus authorizationStatus;
  String? token;

  @override
  Future<NotificationSettings> getNotificationSettings() async =>
      NotificationSettings(
        alert: AppleNotificationSetting.enabled,
        announcement: AppleNotificationSetting.disabled,
        authorizationStatus: authorizationStatus,
        badge: AppleNotificationSetting.enabled,
        carPlay: AppleNotificationSetting.disabled,
        lockScreen: AppleNotificationSetting.enabled,
        notificationCenter: AppleNotificationSetting.enabled,
        showPreviews: AppleShowPreviewSetting.always,
        timeSensitive: AppleNotificationSetting.disabled,
        criticalAlert: AppleNotificationSetting.disabled,
        sound: AppleNotificationSetting.enabled,
        providesAppNotificationSettings: AppleNotificationSetting.disabled,
      );

  @override
  Future<String?> getToken({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) async => token;
}
