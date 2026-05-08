import 'dart:async';

import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({
    List<TaskItem> initialTasks = const [],
    this.shouldThrow = false,
  }) : _tasks = List.of(initialTasks);

  bool shouldThrow;
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
  Stream<TaskItem?> watchTaskById(int taskId) {
    Future.microtask(() {
      if (!_controller.isClosed) _controller.add(List.of(_tasks));
    });
    return _controller.stream.map(
      (tasks) => tasks.where((t) => t.id == taskId).firstOrNull,
    );
  }

  @override
  Future<TaskItem> findTaskById(int taskId) async {
    if (shouldThrow) throw const TaskLoadException('テストエラー');
    final task = _tasks.where((t) => t.id == taskId).firstOrNull;
    if (task == null) throw TaskNotFoundException(taskId: taskId);
    return task;
  }

  @override
  Future<int> addTask({
    required TaskType taskType,
    required String name,
    required String icon,
    required TaskColor color,
    required DateTime executedAt,
    int? scheduleValue,
    ScheduleUnit? scheduleUnit,
  }) async {
    if (shouldThrow) throw const TaskSaveException('テストエラー');
    final id = _nextId++;
    final item = _buildTask(
      id: id,
      taskType: taskType,
      name: name,
      furigana: '',
      icon: icon,
      color: color,
      scheduleValue: scheduleValue,
      scheduleUnit: scheduleUnit,
      taskHistory: [],
    );
    _tasks.add(item);
    _notify();
    return id;
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
    if (shouldThrow) throw const TaskUpdateException('テストエラー');
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) throw TaskNotFoundException(taskId: taskId);
    final original = _tasks[index];
    _tasks[index] = _buildTask(
      id: taskId,
      taskType: taskType,
      name: name,
      furigana: '',
      icon: icon,
      color: color,
      scheduleValue: scheduleValue,
      scheduleUnit: scheduleUnit,
      taskHistory: original.taskHistory,
    );
    _notify();
  }

  String? lastRecordedComment;

  @override
  Future<TaskHistory> recordExecution(
    int taskId, {
    required DateTime executedAt,
    String? comment,
  }) async {
    if (shouldThrow) throw const TaskSaveException('テストエラー');
    lastRecordedComment = comment;
    return TaskHistory(id: _nextId++, executedAt: executedAt, comment: comment);
  }

  @override
  Future<void> updateExecution(
    int executionId, {
    required DateTime executedAt,
    String? comment,
  }) async {
    if (shouldThrow) throw const TaskUpdateException('テストエラー');
  }

  @override
  Future<void> deleteExecution(int executionId) async {
    if (shouldThrow) throw const TaskDeleteException('テストエラー');
  }

  @override
  Future<void> deleteTask(int taskId) async {
    if (shouldThrow) throw const TaskDeleteException('テストエラー');
    _tasks.removeWhere((t) => t.id == taskId);
    _notify();
  }

  @override
  Future<void> deleteAllTasks() async {
    if (shouldThrow) throw const TaskDeleteException('テストエラー');
    _tasks.clear();
    _notify();
  }

  @override
  Future<void> restoreTask(TaskItem taskItem) async {
    if (shouldThrow) throw const TaskSaveException('テストエラー');
    _tasks.add(taskItem);
    _notify();
  }

  void emitError(Object error) {
    if (!_controller.isClosed) _controller.addError(error);
  }

  bool containsTask(int taskId) => _tasks.any((t) => t.id == taskId);

  TaskItem? taskById(int taskId) =>
      _tasks.where((t) => t.id == taskId).firstOrNull;

  void dispose() => _controller.close();

  void _notify() {
    if (!_controller.isClosed) _controller.add(List.of(_tasks));
  }

  static TaskItem _buildTask({
    required int id,
    required TaskType taskType,
    required String name,
    required String furigana,
    required String icon,
    required TaskColor color,
    required int? scheduleValue,
    required ScheduleUnit? scheduleUnit,
    required List<TaskHistory> taskHistory,
  }) => switch (taskType) {
    TaskType.irregular => TaskItem.irregular(
      id: id,
      name: name,
      furigana: furigana,
      icon: icon,
      color: color,
      taskHistory: taskHistory,
    ),
    TaskType.period => TaskItem.period(
      id: id,
      name: name,
      furigana: furigana,
      icon: icon,
      color: color,
      taskHistory: taskHistory,
    ),
    TaskType.scheduled => TaskItem.scheduled(
      id: id,
      name: name,
      furigana: furigana,
      icon: icon,
      color: color,
      scheduleValue: scheduleValue!,
      scheduleUnit: scheduleUnit!,
      taskHistory: taskHistory,
    ),
  };
}
