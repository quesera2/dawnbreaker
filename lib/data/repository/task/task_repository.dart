import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';

abstract interface class TaskRepository {
  Stream<List<TaskItem>> allTaskItems();

  Stream<TaskItem?> watchTaskById(String taskId);

  Future<TaskItem> findTaskById(String taskId);

  Future<String> addTask({
    required TaskType taskType,
    required String name,
    required String icon,
    required TaskColor color,
    int? scheduleValue,
    ScheduleUnit? scheduleUnit,
  });

  Future<void> updateTask({
    required String taskId,
    required TaskType taskType,
    required String name,
    required String icon,
    required TaskColor color,
    int? scheduleValue,
    ScheduleUnit? scheduleUnit,
  });

  Future<TaskHistory> recordExecution(
    String taskId, {
    required DateTime executedAt,
    String? comment,
  });

  Future<void> updateExecution(
    String executionId, {
    required String taskId,
    required DateTime executedAt,
    String? comment,
  });

  Future<void> deleteExecution(String executionId, {required String taskId});

  Future<void> deleteTask(String taskId);

  Future<void> deleteAllTasks();

  Future<void> restoreTask(TaskItem taskItem);
}
