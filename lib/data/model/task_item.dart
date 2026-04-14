import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_item.freezed.dart';

@freezed
abstract class TaskItem with _$TaskItem {
  const factory TaskItem({
    required int id,
    required TaskType taskType,
    required String name,
    required String furigana,
    required TaskColor color,
    required DateTime registeredAt,
    DateTime? scheduledAt,
  }) = _TaskItem;
}