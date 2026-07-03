import 'dart:async';

import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_history_cursor.dart';
import 'package:dawnbreaker/data/model/task_history_page.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({
    List<TaskItem> initialTasks = const [],
    Map<String, List<TaskHistory>> initialHistory = const {},
    this.shouldThrow = false,
  }) : _tasks = List.of(initialTasks),
       _history = {
         for (final entry in initialHistory.entries)
           entry.key: List.of(entry.value),
       };

  bool shouldThrow;
  final List<TaskItem> _tasks;
  final Map<String, List<TaskHistory>> _history;
  final _controller = StreamController<List<TaskItem>>.broadcast();
  int _nextId = 100;

  @override
  Stream<List<TaskItem>> allTaskItems() {
    unawaited(
      Future.microtask(() {
        if (!_controller.isClosed) _controller.add(List.of(_tasks));
      }),
    );
    return _controller.stream;
  }

  @override
  Stream<TaskItem?> watchTaskById(String taskId) {
    unawaited(
      Future.microtask(() {
        if (!_controller.isClosed) _controller.add(List.of(_tasks));
      }),
    );
    return _controller.stream.map(
      (tasks) => tasks.where((t) => t.id == taskId).firstOrNull,
    );
  }

  @override
  Future<TaskItem> findTaskById(String taskId) async {
    if (shouldThrow) throw const TaskLoadException('テストエラー');
    final task = _tasks.where((t) => t.id == taskId).firstOrNull;
    if (task == null) throw TaskNotFoundException(taskId: taskId);
    return task;
  }

  @override
  Future<TaskHistoryPage> fetchTaskHistory(
    String taskId, {
    TaskHistoryCursor? cursor,
    int limit = 20,
  }) async {
    final descending = <TaskHistory>[...?_history[taskId]]
      ..sort((a, b) => b.executedAt.compareTo(a.executedAt));
    final startIndex = cursor == null
        ? 0
        : descending.indexWhere((h) => h.id == cursor.id) + 1;
    final page = descending.skip(startIndex).take(limit).toList();
    return TaskHistoryPage(
      items: page,
      hasMore: startIndex + page.length < descending.length,
    );
  }

  @override
  Future<String> addTask({
    required TaskType taskType,
    required String name,
    required String icon,
    required TaskColor color,
    int? scheduleValue,
    ScheduleUnit? scheduleUnit,
  }) async {
    if (shouldThrow) throw const TaskSaveException('テストエラー');
    final id = _nextId++;
    final item = _buildTask(
      id: id.toString(),
      taskType: taskType,
      name: name,
      furigana: '',
      icon: icon,
      color: color,
      scheduleValue: scheduleValue,
      scheduleUnit: scheduleUnit,
      lastExecutedAt: null,
      cachedScheduledAt: null,
    );
    _tasks.add(item);
    _notify();
    return id.toString();
  }

  @override
  Future<void> updateTask({
    required String taskId,
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
      lastExecutedAt: original.lastExecutedAt,
      cachedScheduledAt: original.scheduledAt,
    );
    _notify();
  }

  String? lastRecordedComment;

  @override
  Future<TaskHistory> recordExecution(
    String taskId, {
    required DateTime executedAt,
    String? comment,
  }) async {
    if (shouldThrow) throw const TaskSaveException('テストエラー');
    lastRecordedComment = comment;
    final newTaskId = _nextId++;
    return TaskHistory(
      id: newTaskId.toString(),
      executedAt: executedAt,
      comment: comment,
    );
  }

  @override
  Future<void> updateExecution(
    String executionId, {
    required String taskId,
    required DateTime executedAt,
    String? comment,
  }) async {
    if (shouldThrow) throw const TaskUpdateException('テストエラー');
  }

  @override
  Future<void> deleteExecution(
    String executionId, {
    required String taskId,
  }) async {
    if (shouldThrow) throw const TaskDeleteException('テストエラー');
  }

  @override
  Future<List<TaskHistory>> deleteTask(String taskId) async {
    if (shouldThrow) throw const TaskDeleteException('テストエラー');
    final history = _history.remove(taskId) ?? [];
    _tasks.removeWhere((t) => t.id == taskId);
    _notify();
    return history;
  }

  @override
  Future<void> deleteAllTasks() async {
    if (shouldThrow) throw const TaskDeleteException('テストエラー');
    _tasks.clear();
    _notify();
  }

  @override
  Future<void> restoreTask(
    TaskItem taskItem,
    List<TaskHistory> taskHistory,
  ) async {
    if (shouldThrow) throw const TaskSaveException('テストエラー');
    _tasks.add(taskItem);
    _history[taskItem.id] = List.of(taskHistory);
    _notify();
  }

  void emitError(Object error) {
    if (!_controller.isClosed) _controller.addError(error);
  }

  bool containsTask(String taskId) => _tasks.any((t) => t.id == taskId);

  TaskItem? taskById(String taskId) =>
      _tasks.where((t) => t.id == taskId).firstOrNull;

  void dispose() {
    unawaited(_controller.close());
  }

  void _notify() {
    if (!_controller.isClosed) _controller.add(List.of(_tasks));
  }

  static TaskItem _buildTask({
    required String id,
    required TaskType taskType,
    required String name,
    required String furigana,
    required String icon,
    required TaskColor color,
    required int? scheduleValue,
    required ScheduleUnit? scheduleUnit,
    required DateTime? lastExecutedAt,
    required DateTime? cachedScheduledAt,
  }) => switch (taskType) {
    TaskType.irregular => TaskItem.irregular(
      id: id,
      name: name,
      furigana: furigana,
      icon: icon,
      color: color,
      lastExecutedAt: lastExecutedAt,
    ),
    TaskType.period => TaskItem.period(
      id: id,
      name: name,
      furigana: furigana,
      icon: icon,
      color: color,
      lastExecutedAt: lastExecutedAt,
      cachedScheduledAt: cachedScheduledAt,
    ),
    TaskType.scheduled => TaskItem.scheduled(
      id: id,
      name: name,
      furigana: furigana,
      icon: icon,
      color: color,
      scheduleValue: scheduleValue!,
      scheduleUnit: scheduleUnit!,
      lastExecutedAt: lastExecutedAt,
    ),
  };
}
