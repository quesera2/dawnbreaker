import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dawnbreaker/core/util/furigana_translate.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class FirestoreTaskRepository implements TaskRepository {
  FirestoreTaskRepository({
    required this.userId,
    required this._furiganaTranslate,
    required this._firestore,
  });

  final String userId;
  final FuriganaTranslate _furiganaTranslate;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _taskDefsRef =>
      _firestore.collection('users').doc(userId).collection('taskDefinitions');

  CollectionReference<Map<String, dynamic>> _executionsRef(String taskId) =>
      _taskDefsRef.doc(taskId).collection('executions');

  @override
  Stream<List<TaskItem>> allTaskItems() {
    return _taskDefsRef.snapshots().asyncMap((snapshot) async {
      final items = await Future.wait(snapshot.docs.map(_buildTaskItem));
      return items..sort((a, b) {
        final aDate = a.scheduledAt;
        final bDate = b.scheduledAt;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });
    });
  }

  @override
  Stream<TaskItem?> watchTaskById(String taskId) {
    return _taskDefsRef.doc(taskId).snapshots().asyncMap((snap) async {
      if (!snap.exists) return null;
      return _buildTaskItem(snap);
    });
  }

  @override
  Future<TaskItem> findTaskById(String taskId) async {
    try {
      final snap = await _taskDefsRef.doc(taskId).get();
      if (!snap.exists) throw TaskNotFoundException(taskId: taskId);
      return _buildTaskItem(snap);
    } on TaskRepositoryException {
      rethrow;
    } catch (e) {
      throw TaskLoadException(e.toString());
    }
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
    if (taskType == TaskType.scheduled &&
        (scheduleValue == null || scheduleUnit == null)) {
      throw const TaskInvalidArgumentException(
        'scheduled タスクの追加には scheduleValue と scheduleUnit が必要です',
      );
    }
    try {
      final furigana = await _furiganaTranslate.translate(name);
      final id = _uuid.v4();
      await _taskDefsRef.doc(id).set({
        'taskType': taskType.name,
        'name': name,
        'furigana': furigana,
        'icon': icon,
        'color': color.name,
        if (taskType == TaskType.scheduled)
          'scheduleConfig': {
            'scheduleValue': scheduleValue,
            'scheduleUnit': scheduleUnit!.name,
          },
        'lastExecutedAt': null,
        'nextScheduledAt': null,
      });
      return id;
    } on TaskRepositoryException {
      rethrow;
    } catch (e) {
      throw TaskSaveException(e.toString());
    }
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
    if (taskType == TaskType.scheduled &&
        (scheduleValue == null || scheduleUnit == null)) {
      throw const TaskInvalidArgumentException(
        'scheduled タスクの更新には scheduleValue と scheduleUnit が必要です',
      );
    }
    try {
      final furigana = await _furiganaTranslate.translate(name);
      await _taskDefsRef.doc(taskId).update({
        'taskType': taskType.name,
        'name': name,
        'furigana': furigana,
        'icon': icon,
        'color': color.name,
        'scheduleConfig': taskType == TaskType.scheduled
            ? {
                'scheduleValue': scheduleValue,
                'scheduleUnit': scheduleUnit!.name,
              }
            : FieldValue.delete(),
      });
    } on TaskRepositoryException {
      rethrow;
    } catch (e) {
      throw TaskUpdateException(e.toString());
    }
  }

  @override
  Future<TaskHistory> recordExecution(
    String taskId, {
    required DateTime executedAt,
    String? comment,
  }) async {
    try {
      final id = _uuid.v4();
      await _executionsRef(taskId).doc(id).set({
        'executedAt': Timestamp.fromDate(executedAt),
        'comment': comment,
        'taskDefinitionId': taskId,
      });
      await _updateCache(taskId);
      return TaskHistory(id: id, executedAt: executedAt, comment: comment);
    } catch (e) {
      throw TaskSaveException(e.toString());
    }
  }

  @override
  Future<void> updateExecution(
    String executionId, {
    required DateTime executedAt,
    String? comment,
  }) async {
    try {
      final taskId = await _findTaskIdForExecution(executionId);
      if (taskId == null) throw TaskUpdateException('not found: $executionId');
      await _executionsRef(taskId).doc(executionId).update({
        'executedAt': Timestamp.fromDate(executedAt),
        'comment': comment,
      });
      await _updateCache(taskId);
    } on TaskRepositoryException {
      rethrow;
    } catch (e) {
      throw TaskUpdateException(e.toString());
    }
  }

  @override
  Future<void> deleteExecution(String executionId) async {
    try {
      final taskId = await _findTaskIdForExecution(executionId);
      if (taskId == null) return;
      await _executionsRef(taskId).doc(executionId).delete();
      await _updateCache(taskId);
    } catch (e) {
      throw TaskDeleteException(e.toString());
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      await _deleteAllExecutions(taskId);
      await _taskDefsRef.doc(taskId).delete();
    } catch (e) {
      throw TaskDeleteException(e.toString());
    }
  }

  @override
  Future<void> deleteAllTasks() async {
    try {
      final taskDefs = await _taskDefsRef.get();
      await Future.wait(
        taskDefs.docs.map((doc) async {
          await _deleteAllExecutions(doc.id);
          await doc.reference.delete();
        }),
      );
    } catch (e) {
      throw TaskDeleteException(e.toString());
    }
  }

  @override
  Future<void> restoreTask(TaskItem taskItem) async {
    try {
      final newId = _uuid.v4();
      final data = <String, dynamic>{
        'taskType': taskItem.taskType.name,
        'name': taskItem.name,
        'furigana': taskItem.furigana,
        'icon': taskItem.icon,
        'color': taskItem.color.name,
        'lastExecutedAt': null,
        'nextScheduledAt': null,
      };
      if (taskItem.taskType == TaskType.scheduled) {
        data['scheduleConfig'] = {
          'scheduleValue': taskItem.scheduleValueOrDefault,
          'scheduleUnit': taskItem.scheduleUnitOrDefault.name,
        };
      }
      await _taskDefsRef.doc(newId).set(data);

      for (final history in taskItem.taskHistory) {
        final execId = _uuid.v4();
        await _executionsRef(newId).doc(execId).set({
          'executedAt': Timestamp.fromDate(history.executedAt),
          'comment': history.comment,
          'taskDefinitionId': newId,
        });
      }
      if (taskItem.taskHistory.isNotEmpty) {
        await _updateCache(newId);
      }
    } catch (e) {
      throw TaskSaveException(e.toString());
    }
  }

  Future<TaskItem> _buildTaskItem(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final taskId = doc.id;
    final data = doc.data()!;
    final taskType = TaskType.values.byName(data['taskType'] as String);
    final name = data['name'] as String;
    final furigana = data['furigana'] as String;
    final icon = data['icon'] as String;
    final color = TaskColor.values.byName(data['color'] as String);

    final executionSnap = await _executionsRef(
      taskId,
    ).orderBy('executedAt').get();
    final taskHistory = executionSnap.docs.map((e) {
      final eData = e.data();
      return TaskHistory(
        id: e.id,
        executedAt: (eData['executedAt'] as Timestamp).toDate(),
        comment: eData['comment'] as String?,
      );
    }).toList();

    return switch (taskType) {
      TaskType.irregular => TaskItem.irregular(
        id: taskId,
        name: name,
        furigana: furigana,
        icon: icon,
        color: color,
        taskHistory: taskHistory,
      ),
      TaskType.period => TaskItem.period(
        id: taskId,
        name: name,
        furigana: furigana,
        icon: icon,
        color: color,
        taskHistory: taskHistory,
      ),
      TaskType.scheduled => _buildScheduledItem(
        taskId: taskId,
        name: name,
        furigana: furigana,
        icon: icon,
        color: color,
        taskHistory: taskHistory,
        data: data,
      ),
    };
  }

  TaskItem _buildScheduledItem({
    required String taskId,
    required String name,
    required String furigana,
    required String icon,
    required TaskColor color,
    required List<TaskHistory> taskHistory,
    required Map<String, dynamic> data,
  }) {
    final config = data['scheduleConfig'] as Map<String, dynamic>?;
    if (config == null) throw TaskNotFoundException(taskId: taskId);
    return TaskItem.scheduled(
      id: taskId,
      name: name,
      furigana: furigana,
      icon: icon,
      color: color,
      scheduleValue: config['scheduleValue'] as int,
      scheduleUnit: ScheduleUnit.values.byName(
        config['scheduleUnit'] as String,
      ),
      taskHistory: taskHistory,
    );
  }

  // O(n) scan across task definitions — acceptable for a personal app with few tasks.
  Future<String?> _findTaskIdForExecution(String executionId) async {
    final taskDefs = await _taskDefsRef.get();
    for (final taskDef in taskDefs.docs) {
      final execDoc = await _executionsRef(taskDef.id).doc(executionId).get();
      if (execDoc.exists) return taskDef.id;
    }
    return null;
  }

  Future<void> _deleteAllExecutions(String taskId) async {
    final executions = await _executionsRef(taskId).get();
    await Future.wait(executions.docs.map((doc) => doc.reference.delete()));
  }

  Future<void> _updateCache(String taskId) async {
    final executionSnap = await _executionsRef(
      taskId,
    ).orderBy('executedAt').get();

    if (executionSnap.docs.isEmpty) {
      await _taskDefsRef.doc(taskId).update({
        'lastExecutedAt': null,
        'nextScheduledAt': null,
      });
      return;
    }

    final taskHistory = executionSnap.docs.map((e) {
      final data = e.data();
      return TaskHistory(
        id: e.id,
        executedAt: (data['executedAt'] as Timestamp).toDate(),
        comment: data['comment'] as String?,
      );
    }).toList();

    final lastExecutedAt = taskHistory.last.executedAt;

    final taskDefSnap = await _taskDefsRef.doc(taskId).get();
    final taskType = TaskType.values.byName(
      taskDefSnap.data()!['taskType'] as String,
    );

    final DateTime? nextScheduledAt = switch (taskType) {
      TaskType.irregular => null,
      TaskType.period => _computePeriodNextAt(taskHistory),
      TaskType.scheduled => () {
        final config =
            taskDefSnap.data()!['scheduleConfig'] as Map<String, dynamic>?;
        if (config == null) return null;
        final value = config['scheduleValue'] as int;
        final unit = ScheduleUnit.values.byName(
          config['scheduleUnit'] as String,
        );
        return unit.addTo(lastExecutedAt, value);
      }(),
    };

    await _taskDefsRef.doc(taskId).update({
      'lastExecutedAt': Timestamp.fromDate(lastExecutedAt),
      'nextScheduledAt': nextScheduledAt != null
          ? Timestamp.fromDate(nextScheduledAt)
          : null,
    });
  }

  DateTime? _computePeriodNextAt(List<TaskHistory> taskHistory) {
    if (taskHistory.length < 2) return null;
    final intervals = taskHistory.skip(1).indexed.map((item) {
      final (index, current) = item;
      final a = taskHistory[index].executedAt;
      final b = current.executedAt;
      final aDate = DateTime(a.year, a.month, a.day);
      final bDate = DateTime(b.year, b.month, b.day);
      return bDate.difference(aDate).inDays;
    }).toList();
    final avgDays = intervals.reduce((a, b) => a + b) / intervals.length;
    return taskHistory.last.executedAt.add(Duration(days: avgDays.round()));
  }
}
