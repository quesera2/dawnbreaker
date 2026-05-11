import 'package:dawnbreaker/core/notification/notification_service.dart';
import 'package:dawnbreaker/data/model/task_item.dart';

class FakeNotificationService implements NotificationService {
  final List<TaskItem> registered = [];
  final List<TaskItem> removed = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> registerNotification(TaskItem task) async =>
      registered.add(task);

  @override
  Future<void> removeNotification(TaskItem task) async => removed.add(task);
}
