import 'dart:io';

import 'package:dawnbreaker/core/notification/notification_service.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/l10n/app_localizations.dart';
import 'package:dawnbreaker/l10n/app_localizations_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;

part 'notification_service_impl.g.dart';

@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse details) {
  // TODO: バックグラウンド・アプリキル状態で受け取った通知のハンドリングを行う
}

@Riverpod(keepAlive: true)
Future<NotificationService> notificationService(Ref ref) async {
  final appLocalizations = await ref.watch(appLocalizationsProvider.future);
  return NotificationServiceImpl(localizations: appLocalizations);
}

const _taskGroupId = 'task_notifications';
const taskChannelId = 'individual_task_notification';

class NotificationServiceImpl implements NotificationService {
  NotificationServiceImpl({required AppLocalizations localizations})
    : _l10n = localizations;

  final AppLocalizations _l10n;

  static const _androidSettings = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  static const _iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  final _plugin = FlutterLocalNotificationsPlugin();

  AndroidFlutterLocalNotificationsPlugin? get _androidImplementation => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _iOSImplementation => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> initialize() async {
    const settings = InitializationSettings(
      android: _androidSettings,
      iOS: _iosSettings,
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    if (Platform.isAndroid) {
      await _androidImplementation?.createNotificationChannelGroup(
        AndroidNotificationChannelGroup(
          _taskGroupId,
          _l10n.notificationGroupTask,
        ),
      );
      await _androidImplementation?.createNotificationChannel(
        AndroidNotificationChannel(
          taskChannelId,
          _l10n.notificationChannelTask,
          groupId: _taskGroupId,
          importance: Importance.high,
        ),
      );
    }
  }

  @override
  Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      await _androidImplementation?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _iOSImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  static const _notifyHour = 9;

  @override
  Future<void> registerNotification(TaskItem task) async {
    final scheduledAt = task.scheduledAt;
    if (scheduledAt == null) {
      await removeNotification(task);
      return;
    }

    final notifyAt = tz.TZDateTime(
      tz.local,
      scheduledAt.year,
      scheduledAt.month,
      scheduledAt.day,
      _notifyHour,
    );
    if (notifyAt.isBefore(tz.TZDateTime.now(tz.local))) {
      await removeNotification(task);
      return;
    }

    await _plugin.cancel(id: task.id);
    await _plugin.zonedSchedule(
      id: task.id,
      title: task.name,
      body: _l10n.notificationTaskBody,
      scheduledDate: notifyAt,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          taskChannelId,
          _l10n.notificationChannelTask,
          importance: Importance.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: task.id.toString(),
    );
  }

  @override
  Future<void> removeNotification(TaskItem task) async {
    await _plugin.cancel(id: task.id);
  }

  void _onNotificationResponse(NotificationResponse details) {
    // TODO: フォアグラウンドで通知を受け取ったときの処理を行う
  }
}
