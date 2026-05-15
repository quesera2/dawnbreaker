import 'package:dawnbreaker/data/model/task_item.dart';

abstract interface class NotificationService {
  Future<void> initialize();

  Future<bool> checkPermission();

  Future<bool> requestPermission();

  Future<void> registerNotification(TaskItem task);

  Future<void> removeNotification(TaskItem task);

  Future<void> removeAllNotification();

  Future<bool> canScheduleExactAlarms();

  Stream<bool> watchCanScheduleExactAlarms();

  Future<void> syncExactAlarmPermission();

  Future<void> requestExactAlarmPermission();
}
