import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_item.freezed.dart';

enum TaskType {
  period,
  scheduled,
}

enum TaskColor {
  none,
  red,
  blue,
  yellow,
  green,
  orange,
}

@freezed
abstract class TaskItem with _$TaskItem {
  const factory TaskItem({
    required TaskType taskType,
    required String name,
    required TaskColor color,
    required DateTime registeredAt,
    DateTime? scheduledAt,
  }) = _TaskItem;
}