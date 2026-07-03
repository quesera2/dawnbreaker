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
  final _historyControllers = <String, StreamController<List<TaskHistory>>>{};
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
  Stream<List<TaskHistory>> watchTaskHistory(String taskId) {
    final controller = _historyControllerFor(taskId);
    unawaited(
      Future.microtask(() {
        if (!controller.isClosed) {
          controller.add(List.of(_history[taskId] ?? []));
        }
      }),
    );
    return controller.stream;
  }

  // watchTaskHistory に全件を乗せているため、続きのページは存在しない
  @override
  Future<TaskHistoryPage> fetchOlderHistory(
    String taskId, {
    required TaskHistoryCursor cursor,
    int limit = 20,
  }) async => const TaskHistoryPage(items: [], hasMore: false);

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
    _notifyHistory(taskItem.id);
  }

  void emitError(Object error) {
    if (!_controller.isClosed) _controller.addError(error);
  }

  // Firestore の limitToLast のように、直近件数のみに絞られた履歴で
  // watchTaskHistory が再emitされる状況を再現する
  void replaceTaskHistory(String taskId, List<TaskHistory> taskHistory) {
    _history[taskId] = List.of(taskHistory);
    _notifyHistory(taskId);
  }

  bool containsTask(String taskId) => _tasks.any((t) => t.id == taskId);

  TaskItem? taskById(String taskId) =>
      _tasks.where((t) => t.id == taskId).firstOrNull;

  void dispose() {
    unawaited(_controller.close());
    for (final controller in _historyControllers.values) {
      unawaited(controller.close());
    }
  }

  void _notify() {
    if (!_controller.isClosed) _controller.add(List.of(_tasks));
  }

  void _notifyHistory(String taskId) {
    final controller = _historyControllers[taskId];
    if (controller != null && !controller.isClosed) {
      controller.add(List.of(_history[taskId] ?? []));
    }
  }

  StreamController<List<TaskHistory>> _historyControllerFor(String taskId) =>
      _historyControllers.putIfAbsent(
        taskId,
        () => StreamController<List<TaskHistory>>.broadcast(),
      );

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
