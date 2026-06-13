import 'package:dawnbreaker/core/notification/notification_service.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/data/model/task_item.dart';

class TaskNotificationSync {
  const TaskNotificationSync(this._service);

  final NotificationService _service;

  Future<void> updateNotifications({
    required NotificationSetting setting,
    required List<TaskItem> previous,
    required List<TaskItem> current,
  }) async {
    if (!setting.enabled) {
      await _service.removeAllNotification();
      return;
    }

    final previousSet = previous.toSet();
    final currentSet = current.toSet();

    for (final task in previousSet.difference(currentSet)) {
      await _service.removeNotification(task);
    }

    for (final task in currentSet.difference(previousSet)) {
      if (task.scheduledAt != null) {
        await _service.registerNotification(
          task,
          notifyDay: setting.notifyDay,
          hour: setting.hour,
          minute: setting.minute,
        );
      } else {
        await _service.removeNotification(task);
      }
    }
  }
}
