// coverage:ignore-file

import 'dart:async';
import 'dart:io';

import 'package:dawnbreaker/core/notification/notification_service.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/l10n/app_localizations.dart';
import 'package:dawnbreaker/l10n/app_localizations_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;

part 'notification_service_impl.g.dart';

@riverpod
Stream<bool> canScheduleExactAlarms(Ref ref) async* {
  final service = await ref.watch(notificationServiceProvider.future);
  yield* service.watchCanScheduleExactAlarms();
}

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

  static const _notifyHour = 9;

  static const _androidSettings = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  static const _iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  final _plugin = FlutterLocalNotificationsPlugin();
  final _exactAlarmController = StreamController<bool>.broadcast();

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
  Future<bool> checkPermission() async {
    final isEnabled = switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        await _androidImplementation?.areNotificationsEnabled(),
      TargetPlatform.iOS => await _iOSImplementation?.checkPermissions().then(
        (p) => p?.isEnabled,
      ),
      _ => throw UnsupportedError(
        'Unsupported platform: $defaultTargetPlatform',
      ),
    };
    return isEnabled ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    final isGranted = switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        await _androidImplementation?.requestNotificationsPermission(),
      TargetPlatform.iOS => await _iOSImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ),
      _ => throw UnsupportedError(
        'Unsupported platform: $defaultTargetPlatform',
      ),
    };
    return isGranted ?? false;
  }

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
      androidScheduleMode: await _resolveAndroidScheduleMode(),
      payload: task.id.toString(),
    );
  }

  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    final canExact = await canScheduleExactAlarms();
    return canExact ? .exactAllowWhileIdle : .inexactAllowWhileIdle;
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    return await _androidImplementation?.canScheduleExactNotifications() ??
        false;
  }

  @override
  Stream<bool> watchCanScheduleExactAlarms() async* {
    yield await canScheduleExactAlarms();
    yield* _exactAlarmController.stream;
  }

  @override
  Future<void> syncExactAlarmPermission() async {
    _exactAlarmController.add(await canScheduleExactAlarms());
  }

  @override
  Future<void> requestExactAlarmPermission() async {
    await _androidImplementation?.requestExactAlarmsPermission();
  }

  @override
  Future<void> removeNotification(TaskItem task) async {
    await _plugin.cancel(id: task.id);
  }

  @override
  Future<void> removeAllNotification() async {
    await _plugin.cancelAll();
  }

  @override
  Future<void> logPendingNotifications() async {
    if (!kDebugMode) return;
    final pending = await _plugin.pendingNotificationRequests();
    debugPrint('=== Pending Notifications (${pending.length}) ===');
    for (final n in pending) {
      debugPrint('  id=${n.id}, title="${n.title}", payload="${n.payload}"');
    }
    debugPrint('================================================');
  }

  void _onNotificationResponse(NotificationResponse details) {
    // TODO: フォアグラウンドで通知を受け取ったときの処理を行う
  }
}
