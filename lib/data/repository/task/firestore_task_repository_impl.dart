import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dawnbreaker/core/util/date_util.dart';
import 'package:dawnbreaker/core/util/furigana_translate.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_history_cursor.dart';
import 'package:dawnbreaker/data/model/task_history_page.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_schedule.dart';
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

  static const _recentHistoryLimit = 10;

  final String userId;
  final FuriganaTranslate _furiganaTranslate;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _taskDefinitionsRef() =>
      _firestore.collection('users').doc(userId).collection('taskDefinitions');

  CollectionReference<Map<String, dynamic>> _executionsRef(String taskId) =>
      _taskDefinitionsRef().doc(taskId).collection('executions');

  @override
  Stream<List<TaskItem>> allTaskItems() {
    return _taskDefinitionsRef().snapshots().map((snapshot) {
      final items = snapshot.docs.map(_buildTaskItemFromCache).toList();
      return items
        ..sort((a, b) => compareNullableDateAsc(a.scheduledAt, b.scheduledAt));
    });
  }

  @override
  Stream<TaskItem?> watchTaskById(String taskId) {
    return _taskDefinitionsRef().doc(taskId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return _buildTaskItemFromCache(snapshot);
    });
  }

  @override
  Future<TaskItem> findTaskById(String taskId) async {
    try {
      final snapshot = await _taskDefinitionsRef().doc(taskId).get();
      if (!snapshot.exists) throw TaskNotFoundException(taskId: taskId);
      return _buildTaskItemFromCache(snapshot);
    } on TaskRepositoryException {
      rethrow;
    } catch (e) {
      throw TaskLoadException(e.toString());
    }
  }

  @override
  Stream<List<TaskHistory>> watchTaskHistory(String taskId) {
    return _executionsRef(taskId)
        .orderBy('executedAt')
        .limitToLast(_recentHistoryLimit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_taskHistoryFromDoc).toList());
  }

  @override
  Future<TaskHistoryPage> fetchOlderHistory(
    String taskId, {
    required TaskHistoryCursor cursor,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _executionsRef(taskId)
          .orderBy('executedAt', descending: true)
          .orderBy(FieldPath.documentId, descending: true)
          .startAfter([Timestamp.fromDate(cursor.executedAt), cursor.id])
          .limit(limit)
          .get();
      final items = snapshot.docs.map(_taskHistoryFromDoc).toList();
      return TaskHistoryPage(items: items, hasMore: items.length == limit);
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
      // taskType やスケジュール設定の変更で nextScheduledAt の算出方法が変わるため再計算する
      await _updateCache(taskId);
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
      return TaskHistory(id: id, executedAt: executedAt, comment: comment);
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
  Future<List<TaskHistory>> deleteTask(String taskId) async {
    try {
      final deletedHistory = await _deleteAllExecutions(taskId);
      await _taskDefinitionsRef().doc(taskId).delete();
      return deletedHistory;
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
  Future<void> restoreTask(
    TaskItem taskItem,
    List<TaskHistory> taskHistory,
  ) async {
    try {
      final newId = _uuid.v4();
      final batch = _firestore.batch();

      final ascendingHistory = [...taskHistory]
        ..sort((a, b) => a.executedAt.compareTo(b.executedAt));
      final lastExecutedAt = computeLastExecutedAt(ascendingHistory);
      final scheduledAt = computeScheduledAt(
        taskType: taskItem.taskType,
        ascendingHistory: ascendingHistory,
        scheduleValue: taskItem.taskType == TaskType.scheduled
            ? taskItem.scheduleValueOrDefault
            : null,
        scheduleUnit: taskItem.taskType == TaskType.scheduled
            ? taskItem.scheduleUnitOrDefault
            : null,
      );

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
        'nextScheduledAt': scheduledAt != null
            ? Timestamp.fromDate(scheduledAt)
            : null,
      });

      for (final history in taskHistory) {
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

  TaskHistory _taskHistoryFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return TaskHistory(
      id: doc.id,
      executedAt: (data['executedAt'] as Timestamp).toDate(),
      comment: data['comment'] as String?,
    );
  }

  TaskItem _buildTaskItemFromCache(DocumentSnapshot<Map<String, dynamic>> doc) {
    final taskId = doc.id;
    final data = doc.data();
    if (data == null) throw TaskNotFoundException(taskId: taskId);
    final taskType = TaskType.values.byName(data['taskType'] as String);
    final name = data['name'] as String;
    final furigana = data['furigana'] as String;
    final icon = data['icon'] as String;
    final color = TaskColor.values.byName(data['color'] as String);
    final lastExecutedAt = (data['lastExecutedAt'] as Timestamp?)?.toDate();
    final nextScheduledAt = (data['nextScheduledAt'] as Timestamp?)?.toDate();

    return switch (taskType) {
      TaskType.irregular => TaskItem.irregular(
        id: taskId,
        name: name,
        furigana: furigana,
        icon: icon,
        color: color,
        lastExecutedAt: lastExecutedAt,
      ),
      TaskType.period => TaskItem.period(
        id: taskId,
        name: name,
        furigana: furigana,
        icon: icon,
        color: color,
        lastExecutedAt: lastExecutedAt,
        cachedScheduledAt: nextScheduledAt,
      ),
      TaskType.scheduled => _buildScheduledItem(
        taskId: taskId,
        name: name,
        furigana: furigana,
        icon: icon,
        color: color,
        lastExecutedAt: lastExecutedAt,
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
    required DateTime? lastExecutedAt,
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
      lastExecutedAt: lastExecutedAt,
    );
  }

  Future<List<TaskHistory>> _deleteAllExecutions(String taskId) async {
    final executions = await _executionsRef(taskId).get();
    await Future.wait(executions.docs.map((doc) => doc.reference.delete()));
    return executions.docs.map(_taskHistoryFromDoc).toList();
  }

  Future<void> _updateCache(String taskId) async {
    final executionSnap = await _executionsRef(
      taskId,
    ).orderBy('executedAt').limitToLast(_recentHistoryLimit).get();
    final ascendingHistory = executionSnap.docs
        .map(_taskHistoryFromDoc)
        .toList();

    final taskDefinitionSnap = await _taskDefinitionsRef().doc(taskId).get();
    final taskDefData = taskDefinitionSnap.data();
    if (taskDefData == null) throw TaskNotFoundException(taskId: taskId);
    final taskType = TaskType.values.byName(taskDefData['taskType'] as String);
    final config = taskDefData['scheduleConfig'] as Map<String, dynamic>?;

    final lastExecutedAt = computeLastExecutedAt(ascendingHistory);
    final scheduledAt = computeScheduledAt(
      taskType: taskType,
      ascendingHistory: ascendingHistory,
      scheduleValue: config?['scheduleValue'] as int?,
      scheduleUnit: config == null
          ? null
          : ScheduleUnit.values.byName(config['scheduleUnit'] as String),
    );

    await _taskDefinitionsRef().doc(taskId).update({
      'lastExecutedAt': lastExecutedAt != null
          ? Timestamp.fromDate(lastExecutedAt)
          : null,
      'nextScheduledAt': scheduledAt != null
          ? Timestamp.fromDate(scheduledAt)
          : null,
    });
  }
}
