import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:flutter/widgets.dart';

abstract interface class NotificationService {
  Future<void> initialize();

  Future<void> setupChannels(BuildContext context);

  Future<void> requestPermission();

  Future<void> registerNotification(TaskItem task);

  Future<void> removeNotification(TaskItem task);
}
