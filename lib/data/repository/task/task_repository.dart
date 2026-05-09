import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';

abstract interface class TaskRepository {
  Stream<List<TaskItem>> allTaskItems();

  Stream<TaskItem?> watchTaskById(int taskId);

  Future<TaskItem> findTaskById(int taskId);

  Future<int> addTask({
    required TaskType taskType,
    required String name,
    required String icon,
    required TaskColor color,
    int? scheduleValue,
    ScheduleUnit? scheduleUnit,
  });

  Future<void> updateTask({
    required int taskId,
    required TaskType taskType,
    required String name,
    required String icon,
    required TaskColor color,
    int? scheduleValue,
    ScheduleUnit? scheduleUnit,
  });

  Future<TaskHistory> recordExecution(
    int taskId, {
    required DateTime executedAt,
    String? comment,
  });

  Future<void> updateExecution(
    int executionId, {
    required DateTime executedAt,
    String? comment,
  });

  Future<void> deleteExecution(int executionId);

  Future<void> deleteTask(int taskId);

  Future<void> deleteAllTasks();

  Future<void> restoreTask(TaskItem taskItem);
}
