import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_item.dart';

abstract class TaskRepository {
  Stream<List<TaskItem>> watchAllTasks();

  Future<int> addPeriodTask({
    required String name,
    required TaskColor color,
  });

  Future<int> addScheduledTask({
    required String name,
    required TaskColor color,
    required int scheduleValue,
    required ScheduleUnit scheduleUnit,
  });

  Future<void> recordExecution(int taskId, {DateTime? executedAt});

  Future<void> deleteTask(int taskId);
}