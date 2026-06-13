// coverage:ignore-file

import 'dart:async';
import 'dart:io';

import 'package:dawnbreaker/core/notification/notification_service.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
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

@Riverpod(keepAlive: true)
Future<NotificationService> notificationService(Ref ref) async {
  final appLocalizations = await ref.watch(appLocalizationsProvider.future);
  return NotificationServiceImpl(l10n: appLocalizations);
}

const _taskGroupId = 'task_notifications';
const taskChannelId = 'individual_task_notification';

class NotificationServiceImpl implements NotificationService {
  NotificationServiceImpl({required this._l10n});

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
    await _plugin.initialize(settings: settings);

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
  Future<void> registerNotification(
    TaskItem task, {
    required NotifyDay notifyDay,
    required int hour,
    required int minute,
  }) async {
    final scheduledAt = task.scheduledAt;
    if (scheduledAt == null) {
      await removeNotification(task);
      return;
    }

    final baseDate = scheduledAt.add(Duration(days: notifyDay.dayOffset));
    final notifyAt = tz.TZDateTime(
      tz.local,
      baseDate.year,
      baseDate.month,
      baseDate.day,
      hour,
      minute,
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
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: await _resolveAndroidScheduleMode(),
      payload: task.id.toString(),
    );
  }

  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    final canExact = await canScheduleExactAlarms();
    return canExact ? .alarmClock : .inexactAllowWhileIdle;
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
}
