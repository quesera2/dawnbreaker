import 'dart:io';

import 'package:dawnbreaker/core/notification/notification_service.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;

part 'notification_service_impl.g.dart';

@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse details) {
  // TODO: バックグラウンド・アプリキル状態で受け取った通知のハンドリングを行う
}

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) => NotificationServiceImpl();

const _taskGroupId = 'task_notifications';
const taskChannelId = 'individual_task_notification';

class NotificationServiceImpl implements NotificationService {
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
  }

  @override
  Future<void> setupChannels(BuildContext context) async {
    if (!Platform.isAndroid) return;
    final l10n = context.l10n;
    await _androidImplementation?.createNotificationChannelGroup(
      AndroidNotificationChannelGroup(_taskGroupId, l10n.notificationGroupTask),
    );
    await _androidImplementation?.createNotificationChannel(
      AndroidNotificationChannel(
        taskChannelId,
        l10n.notificationChannelTask,
        groupId: _taskGroupId,
        importance: Importance.high,
      ),
    );
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
  static const _notificationBody = '予定日になりました';

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
      body: _notificationBody,
      scheduledDate: notifyAt,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          taskChannelId,
          taskChannelId,
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
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
