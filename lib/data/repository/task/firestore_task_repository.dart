import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';

class FirestoreTaskRepository implements TaskRepository {
  FirestoreTaskRepository({required this.userId});

  final String userId;

  @override
  Stream<List<TaskItem>> allTaskItems() => throw UnimplementedError();

  @override
  Stream<TaskItem?> watchTaskById(String taskId) => throw UnimplementedError();

  @override
  Future<TaskItem> findTaskById(String taskId) => throw UnimplementedError();

  @override
  Future<String> addTask({
    required TaskType taskType,
    required String name,
    required String icon,
    required TaskColor color,
    int? scheduleValue,
    ScheduleUnit? scheduleUnit,
  }) => throw UnimplementedError();

  @override
  Future<void> updateTask({
    required String taskId,
    required TaskType taskType,
    required String name,
    required String icon,
    required TaskColor color,
    int? scheduleValue,
    ScheduleUnit? scheduleUnit,
  }) => throw UnimplementedError();

  @override
  Future<TaskHistory> recordExecution(
    String taskId, {
    required DateTime executedAt,
    String? comment,
  }) => throw UnimplementedError();

  @override
  Future<void> updateExecution(
    String executionId, {
    required DateTime executedAt,
    String? comment,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteExecution(String executionId) => throw UnimplementedError();

  @override
  Future<void> deleteTask(String taskId) => throw UnimplementedError();

  @override
  Future<void> deleteAllTasks() => throw UnimplementedError();

  @override
  Future<void> restoreTask(TaskItem taskItem) => throw UnimplementedError();
}
