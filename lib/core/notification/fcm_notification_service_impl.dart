import 'dart:async';
import 'dart:io';

import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/core/notification/notification_service.dart';
import 'package:dawnbreaker/data/repository/user/firestore_notification_token_repository.dart';
import 'package:dawnbreaker/data/repository/user/notification_token_repository.dart';
import 'package:dawnbreaker/l10n/app_localizations.dart';
import 'package:dawnbreaker/l10n/app_localizations_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fcm_notification_service_impl.g.dart';

@Riverpod(keepAlive: true)
Future<NotificationService> fcmNotificationService(Ref ref) async {
  final repository = await ref.watch(
    notificationTokenRepositoryProvider.future,
  );
  final messaging = FirebaseMessaging.instance;
  final appLocalizations = await ref.watch(appLocalizationsProvider.future);
  final service = FcmNotificationServiceImpl(
    repository: repository,
    messaging: messaging,
    l10n: appLocalizations,
  );

  // 初期化処理を行う
  await service.initialize();

  // トークンは FCM の都合で作り直されることがあるため、`onTokenRefresh` を購読して追随する。
  final onTokenRefreshSubscription = messaging.onTokenRefresh.listen(
    (token) => unawaited(
      repository.addToken(token).onError((e, s) {
        logger.e('write token failed.', error: e, stackTrace: s);
      }),
    ),
  );
  ref.onDispose(onTokenRefreshSubscription.cancel);

  // フォアグラウンド通知を受け取ったときに表示を行う
  final onMessageSubscription = FirebaseMessaging.onMessage.listen(
    (message) => unawaited(
      service.show(message).onError((e, s) {
        logger.e('show foreground message failed.', error: e, stackTrace: s);
      }),
    ),
  );
  ref.onDispose(onMessageSubscription.cancel);

  return service;
}

class FcmNotificationServiceImpl implements NotificationService {
  FcmNotificationServiceImpl({
    required this._repository,
    required this._messaging,
    required this._l10n,
  });

  final NotificationTokenRepository _repository;
  final FirebaseMessaging _messaging;
  final AppLocalizations _l10n;

  static const _androidSettings = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );
  static const _taskGroupId = 'task_notifications';
  static const _taskChannelId = 'individual_task_notification';

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (Platform.isIOS) {
      await _initializeIOS();
    } else if (Platform.isAndroid) {
      await _initializeAndroid();
    }
  }

  Future<void> _initializeIOS() async {
    // iOS は OS 自身にフォアグラウンド表示を許可させる。
    // flutter_local_notifications 側でも表示すると二重表示になるため注意。
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _initializeAndroid() async {
    await _plugin.initialize(
      settings: const InitializationSettings(android: _androidSettings),
    );

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.createNotificationChannelGroup(
      AndroidNotificationChannelGroup(
        _taskGroupId,
        _l10n.notificationGroupTask,
      ),
    );
    await androidImplementation?.createNotificationChannel(
      AndroidNotificationChannel(
        _taskChannelId,
        _l10n.notificationChannelTask,
        groupId: _taskGroupId,
        importance: Importance.high,
      ),
    );
  }

  @override
  Future<bool> checkPermission() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus.isAuthorized;
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus.isAuthorized;
  }

  @override
  Future<void> registerToken() async {
    if (!await checkPermission()) {
      return;
    }

    final token = await _messaging.getToken();
    if (token == null) return;
    await _repository.addToken(token);
  }

  Future<void> show(RemoteMessage message) async {
    if (!Platform.isAndroid) return;

    final notification = message.notification;
    if (notification == null) return;

    // Dart の Int は 64bit でそのまま渡すと Android の Int の範囲をオーバーするため上位ビットを刈る
    final messageId = message.hashCode & 0x7FFFFFFF;
    await _plugin.show(
      id: messageId,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _taskChannelId,
          _l10n.notificationChannelTask,
          importance: Importance.high,
        ),
      ),
    );
  }
}

extension on AuthorizationStatus {
  /// 通知を送ってよい状態か。
  ///
  /// `provisional` は静かな通知が届く状態なので、送信先として登録してよい。
  bool get isAuthorized => switch (this) {
    .authorized || .provisional => true,
    .denied || .notDetermined => false,
  };
}
