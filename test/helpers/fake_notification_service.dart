import 'dart:async';

import 'package:dawnbreaker/core/notification/notification_service.dart';
import 'package:dawnbreaker/data/model/task_item.dart';

class FakeNotificationService implements NotificationService {
  FakeNotificationService({
    this.checkPermissionResult = true,
    this.permissionResult = true,
    this.canScheduleExactAlarmsResult = true,
  });

  bool checkPermissionResult;
  bool permissionResult;
  bool canScheduleExactAlarmsResult;
  bool checkPermissionCalled = false;
  bool requestPermissionCalled = false;
  bool syncExactAlarmPermissionCalled = false;
  final List<TaskItem> registered = [];
  final List<TaskItem> removed = [];
  bool callRemovedAll = false;

  final _exactAlarmController = StreamController<bool>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> checkPermission() async {
    checkPermissionCalled = true;
    return checkPermissionResult;
  }

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalled = true;
    return permissionResult;
  }

  @override
  Future<void> registerNotification(TaskItem task) async =>
      registered.add(task);

  @override
  Future<void> removeNotification(TaskItem task) async => removed.add(task);

  @override
  Future<void> removeAllNotification() async => callRemovedAll = true;

  @override
  Future<bool> canScheduleExactAlarms() async => canScheduleExactAlarmsResult;

  @override
  Stream<bool> watchCanScheduleExactAlarms() async* {
    yield canScheduleExactAlarmsResult;
    yield* _exactAlarmController.stream;
  }

  @override
  Future<void> syncExactAlarmPermission() async {
    syncExactAlarmPermissionCalled = true;
    _exactAlarmController.add(canScheduleExactAlarmsResult);
  }
}
