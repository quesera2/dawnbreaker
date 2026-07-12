import 'dart:async';

import 'package:dawnbreaker/core/notification/fcm_token_service.dart';
import 'package:dawnbreaker/data/repository/user/firestore_notification_token_repository.dart';
import 'package:dawnbreaker/data/repository/user/notification_token_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fcm_token_service_impl.g.dart';

/// トークンは FCM の都合で作り直されることがあるため、`onTokenRefresh` を購読して追随する。
/// 購読はアプリの生存期間中つづける。起動時の登録は main() が明示的に呼ぶ。
@Riverpod(keepAlive: true)
Future<FcmTokenService> fcmTokenService(Ref ref) async {
  final repository = await ref.watch(
    notificationTokenRepositoryProvider.future,
  );
  final service = FcmTokenServiceImpl(repository: repository);

  final subscription = FirebaseMessaging.instance.onTokenRefresh.listen(
    (token) => unawaited(repository.addToken(token)),
  );
  ref.onDispose(subscription.cancel);

  return service;
}

class FcmTokenServiceImpl implements FcmTokenService {
  FcmTokenServiceImpl({required this._repository});

  final NotificationTokenRepository _repository;

  @override
  Future<void> registerToken() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.getNotificationSettings();
    if (!_isAuthorized(settings.authorizationStatus)) return;

    final token = await messaging.getToken();
    if (token == null) return;
    await _repository.addToken(token);
  }

  bool _isAuthorized(AuthorizationStatus status) => switch (status) {
    // provisional は静かな通知が届く状態なので、送信先として登録する
    .authorized || .provisional => true,
    .denied || .notDetermined => false,
  };
}
