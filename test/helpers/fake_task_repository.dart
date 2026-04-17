import 'dart:async';

import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({List<TaskItem> initialTasks = const []})
    : _tasks = List.of(initialTasks);

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
  Future<int> addPeriodTask({
    required String name,
    required TaskColor color,
    required DateTime executedAt,
  }) async => _nextId++;

  @override
  Future<int> addScheduledTask({
    required String name,
    required TaskColor color,
    required int scheduleValue,
    required ScheduleUnit scheduleUnit,
    required DateTime executedAt,
  }) async => _nextId++;

  @override
  Future<void> recordExecution(
    int taskId, {
    required DateTime executedAt,
  }) async {}

  @override
  Future<void> deleteTask(int taskId) async {}

  void dispose() => _controller.close();
}
