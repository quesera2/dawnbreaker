import 'dart:async';

import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({
    List<TaskItem> initialTasks = const [],
    this.shouldThrow = false,
  }) : _tasks = List.of(initialTasks);

  final bool shouldThrow;
  final List<TaskItem> _tasks;
  final _controller = StreamController<List<TaskItem>>.broadcast();
  int _nextId = 100;

  @override
  Stream<List<TaskItem>> allTaskItems() {
    Future.microtask(() {
      if (!_controller.isClosed) _controller.add(List.of(_tasks));
    });
    return _controller.stream;
  }

  @override
  Future<TaskItem> findTaskById(int taskId) async {
    if (shouldThrow) throw TaskRepositoryException('テストエラー');
    return _tasks.firstWhere((t) => t.id == taskId);
  }

  @override
  Future<int> addPeriodTask({
    required String name,
    required String icon,
    required TaskColor color,
    required DateTime executedAt,
  }) async {
    if (shouldThrow) throw TaskRepositoryException('テストエラー');
    return _nextId++;
  }

  @override
  Future<int> addScheduledTask({
    required String name,
    required String icon,
    required TaskColor color,
    required int scheduleValue,
    required ScheduleUnit scheduleUnit,
    required DateTime executedAt,
  }) async {
    if (shouldThrow) throw TaskRepositoryException('テストエラー');
    return _nextId++;
  }

  @override
  Future<void> updateTask({
    required int taskId,
    required TaskType taskType,
    required String name,
    required String icon,
    required TaskColor color,
    int? scheduleValue,
    ScheduleUnit? scheduleUnit,
  }) async {
    if (shouldThrow) throw TaskRepositoryException('テストエラー');
  }

  @override
  Future<void> recordExecution(
    int taskId, {
    required DateTime executedAt,
  }) async {
    if (shouldThrow) throw TaskRepositoryException('テストエラー');
  }

  @override
  Future<void> deleteTask(int taskId) async {
    if (shouldThrow) throw TaskRepositoryException('テストエラー');
  }

  void dispose() => _controller.close();
}
