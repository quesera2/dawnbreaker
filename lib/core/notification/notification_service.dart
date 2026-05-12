import 'package:dawnbreaker/data/model/task_item.dart';

abstract interface class NotificationService {
  Future<void> initialize();

  Future<void> requestPermission();

  Future<void> registerNotification(TaskItem task);

  Future<void> removeNotification(TaskItem task);

  Future<void> removeAllNotification();
}
