import 'package:dawnbreaker/core/notification/notification_service.dart';
import 'package:dawnbreaker/data/model/task_item.dart';

class FakeNotificationService implements NotificationService {
  FakeNotificationService({this.permissionResult = true});

  bool permissionResult;
  bool requestPermissionCalled = false;
  final List<TaskItem> registered = [];
  final List<TaskItem> removed = [];
  bool callRemovedAll = false;

  @override
  Future<void> initialize() async {}

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
}
