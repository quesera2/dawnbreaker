import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_item.dart';

abstract interface class TaskRepository {
  Stream<List<TaskItem>> allTaskItems();

  Future<int> addPeriodTask({
    required String name,
    required String icon,
    required TaskColor color,
    required DateTime executedAt,
  });

  Future<int> addScheduledTask({
    required String name,
    required String icon,
    required TaskColor color,
    required int scheduleValue,
    required ScheduleUnit scheduleUnit,
    required DateTime executedAt,
  });

  Future<void> recordExecution(int taskId, {required DateTime executedAt});

  Future<void> deleteTask(int taskId);
}
