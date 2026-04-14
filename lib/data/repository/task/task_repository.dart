import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_item.dart';

abstract class TaskRepository {
  Stream<List<TaskItem>> watchAllTasks();

  Future<void> addPeriodTask({
    required String name,
    required TaskColor color,
  });

  Future<void> addScheduledTask({
    required String name,
    required TaskColor color,
    required int scheduleValue,
    required ScheduleUnit scheduleUnit,
  });

  Future<void> recordExecution(int taskId);

  Future<void> deleteTask(int taskId);
}
