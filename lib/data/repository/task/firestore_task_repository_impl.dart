import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:dawnbreaker/core/util/date_util.dart';
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

class FirestoreTaskRepositoryImpl implements TaskRepository {
  FirestoreTaskRepositoryImpl({
    required this.userId,
    required this._furiganaTranslate,
    required this._firestore,
  });

  final String userId;
  final FuriganaTranslate _furiganaTranslate;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _taskDefinitionsRef() =>
      _firestore.collection('users').doc(userId).collection('taskDefinitions');

  CollectionReference<Map<String, dynamic>> _executionsRef(String taskId) =>
      _taskDefinitionsRef().doc(taskId).collection('executions');

  @override
  Stream<List<TaskItem>> allTaskItems() {
    return _taskDefinitionsRef().snapshots().asyncMap((snapshot) async {
      final items = await Future.wait(snapshot.docs.map(_buildTaskItem));
      return items
        ..sort((a, b) => compareNullableDateAsc(a.scheduledAt, b.scheduledAt));
    });
  }

  @override
  Stream<TaskItem?> watchTaskById(String taskId) {
    return _taskDefinitionsRef().doc(taskId).snapshots().asyncMap((
      snapshot,
    ) async {
      if (!snapshot.exists) return null;
      return _buildTaskItem(snapshot);
    });
  }

  @override
  Future<TaskItem> findTaskById(String taskId) async {
    try {
      final snapshot = await _taskDefinitionsRef().doc(taskId).get();
      if (!snapshot.exists) throw TaskNotFoundException(taskId: taskId);
      return _buildTaskItem(snapshot);
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
      await _taskDefinitionsRef()
          .doc(id)
          .set(
            _taskDefinitionData(
              taskType: taskType,
              name: name,
              furigana: furigana,
              icon: icon,
              color: color,
              scheduleValue: scheduleValue,
              scheduleUnit: scheduleUnit,
            ),
          );
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
      await _taskDefinitionsRef().doc(taskId).update({
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
      await _executionsRef(
        taskId,
      ).doc(id).set(_executionData(executedAt: executedAt, comment: comment));
      await _updateCache(taskId);
      return TaskHistory(
        id: id,
        taskId: taskId,
        executedAt: executedAt,
        comment: comment,
      );
    } catch (e) {
      throw TaskSaveException(e.toString());
    }
  }

  @override
  Future<void> updateExecution(
    String executionId, {
    required String taskId,
    required DateTime executedAt,
    String? comment,
  }) async {
    try {
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
  Future<void> deleteExecution(
    String executionId, {
    required String taskId,
  }) async {
    try {
      final executionRef = _executionsRef(taskId).doc(executionId);
      if (!(await executionRef.get()).exists) return;
      await executionRef.delete();
      await _updateCache(taskId);
    } catch (e) {
      throw TaskDeleteException(e.toString());
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      await _deleteAllExecutions(taskId);
      await _taskDefinitionsRef().doc(taskId).delete();
    } catch (e) {
      throw TaskDeleteException(e.toString());
    }
  }

  @override
  Future<void> deleteAllTasks() async {
    try {
      final taskDefinitions = await _taskDefinitionsRef().get();
      final executionSnapshots = await Future.wait(
        taskDefinitions.docs.map((doc) => _executionsRef(doc.id).get()),
      );

      final allReferences = [
        ...taskDefinitions.docs.map((d) => d.reference),
        for (final snapshot in executionSnapshots)
          ...snapshot.docs.map((d) => d.reference),
      ];

      for (var i = 0; i < allReferences.length; i += 500) {
        final batch = _firestore.batch();
        for (final reference in allReferences.skip(i).take(500)) {
          batch.delete(reference);
        }
        await batch.commit();
      }
    } catch (e) {
      throw TaskDeleteException(e.toString());
    }
  }

  @override
  Future<void> restoreTask(TaskItem taskItem) async {
    try {
      final newId = _uuid.v4();
      final batch = _firestore.batch();

      final lastExecutedAt = taskItem.taskHistory.isEmpty
          ? null
          : taskItem.taskHistory.last.executedAt;

      batch.set(_taskDefinitionsRef().doc(newId), {
        ..._taskDefinitionData(
          taskType: taskItem.taskType,
          name: taskItem.name,
          furigana: taskItem.furigana,
          icon: taskItem.icon,
          color: taskItem.color,
          scheduleValue: taskItem.taskType == TaskType.scheduled
              ? taskItem.scheduleValueOrDefault
              : null,
          scheduleUnit: taskItem.taskType == TaskType.scheduled
              ? taskItem.scheduleUnitOrDefault
              : null,
        ),
        'lastExecutedAt': lastExecutedAt != null
            ? Timestamp.fromDate(lastExecutedAt)
            : null,
        'nextScheduledAt': taskItem.scheduledAt != null
            ? Timestamp.fromDate(taskItem.scheduledAt!)
            : null,
      });

      for (final history in taskItem.taskHistory) {
        batch.set(
          _executionsRef(newId).doc(_uuid.v4()),
          _executionData(
            executedAt: history.executedAt,
            comment: history.comment,
          ),
        );
      }

      await batch.commit();
    } catch (e) {
      throw TaskSaveException(e.toString());
    }
  }

  Map<String, dynamic> _taskDefinitionData({
    required TaskType taskType,
    required String name,
    required String furigana,
    required String icon,
    required TaskColor color,
    int? scheduleValue,
    ScheduleUnit? scheduleUnit,
  }) => {
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
  };

  Map<String, dynamic> _executionData({
    required DateTime executedAt,
    String? comment,
  }) => {'executedAt': Timestamp.fromDate(executedAt), 'comment': comment};

  Future<TaskItem> _buildTaskItem(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final taskId = doc.id;
    final data = doc.data();
    if (data == null) throw TaskNotFoundException(taskId: taskId);
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
        taskId: taskId,
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

  Future<void> _deleteAllExecutions(String taskId) async {
    final executions = await _executionsRef(taskId).get();
    await Future.wait(executions.docs.map((doc) => doc.reference.delete()));
  }

  Future<void> _updateCache(String taskId) async {
    final executionSnap = await _executionsRef(
      taskId,
    ).orderBy('executedAt').get();

    if (executionSnap.docs.isEmpty) {
      await _taskDefinitionsRef().doc(taskId).update({
        'lastExecutedAt': null,
        'nextScheduledAt': null,
      });
      return;
    }

    final taskHistory = executionSnap.docs.map((e) {
      final data = e.data();
      return TaskHistory(
        id: e.id,
        taskId: taskId,
        executedAt: (data['executedAt'] as Timestamp).toDate(),
        comment: data['comment'] as String?,
      );
    }).toList();

    final lastExecutedAt = taskHistory.last.executedAt;

    final taskDefinitionSnap = await _taskDefinitionsRef().doc(taskId).get();
    final taskDefData = taskDefinitionSnap.data();
    if (taskDefData == null) throw TaskNotFoundException(taskId: taskId);
    final taskType = TaskType.values.byName(taskDefData['taskType'] as String);

    final DateTime? nextScheduledAt = switch (taskType) {
      TaskType.irregular => null,
      TaskType.period => _computePeriodNextAt(taskHistory),
      TaskType.scheduled => () {
        final config = taskDefData['scheduleConfig'] as Map<String, dynamic>?;
        if (config == null) return null;
        final value = config['scheduleValue'] as int;
        final unit = ScheduleUnit.values.byName(
          config['scheduleUnit'] as String,
        );
        return unit.addTo(lastExecutedAt, value);
      }(),
    };

    await _taskDefinitionsRef().doc(taskId).update({
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
      final aDate = taskHistory[index].executedAt.truncateTime;
      final bDate = current.executedAt.truncateTime;
      return bDate.difference(aDate).inDays;
    }).toList();
    final avgDays = intervals.average.round();
    return taskHistory.last.executedAt.add(Duration(days: avgDays));
  }
}
