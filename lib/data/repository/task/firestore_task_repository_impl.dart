import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
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
typedef WriteData =
    List<(DocumentReference<Map<String, dynamic>>, Map<String, dynamic>)>;

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
  Future<TaskHistoryPage> fetchTaskHistory(
    String taskId, {
    TaskHistoryCursor? cursor,
    int limit = 10,
  }) async {
    try {
      var query = _executionsRef(taskId)
          .orderBy('executedAt', descending: true)
          .orderBy(FieldPath.documentId, descending: true);
      if (cursor != null) {
        query = query.startAfter([
          Timestamp.fromDate(cursor.executedAt),
          cursor.id,
        ]);
      }
      final snapshot = await query.limit(limit).get();
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
      final ascendingHistory = await _fetchAscendingHistory(taskId);
      await _taskDefinitionsRef()
          .doc(taskId)
          .update(
            _taskDefinitionData(
              taskType: taskType,
              name: name,
              furigana: furigana,
              icon: icon,
              color: color,
              scheduleValue: scheduleValue,
              scheduleUnit: scheduleUnit,
              taskHistory: ascendingHistory,
            ),
          );
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
      final newHistory = TaskHistory(
        id: id,
        executedAt: executedAt,
        comment: comment,
      );
      final currentHistory = await _fetchAscendingHistory(taskId);
      final (taskType, scheduleValue, scheduleUnit) =
          await _fetchScheduleConfig(taskId);

      final ascendingHistory = [...currentHistory, newHistory]
        ..sort((a, b) => a.executedAt.compareTo(b.executedAt));
      final schedule = _computeSchedule(
        taskType: taskType,
        ascendingHistory: ascendingHistory,
        scheduleValue: scheduleValue,
        scheduleUnit: scheduleUnit,
      );

      final batch = _firestore.batch();
      batch.set(
        _executionsRef(taskId).doc(id),
        _executionData(executedAt: executedAt, comment: comment),
      );
      batch.update(
        _taskDefinitionsRef().doc(taskId),
        _scheduleFieldsData(schedule),
      );
      await batch.commit();

      return newHistory;
    } on TaskRepositoryException {
      rethrow;
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
      final updatedHistory = TaskHistory(
        id: executionId,
        executedAt: executedAt,
        comment: comment,
      );
      final recentHistory = await _fetchAscendingHistory(
        taskId,
        limit: scheduleHistoryLimit + 1,
      );
      final (taskType, scheduleValue, scheduleUnit) =
          await _fetchScheduleConfig(taskId);

      final ascendingHistory = [
        ...recentHistory.where((history) => history.id != executionId),
        updatedHistory,
      ]..sort((a, b) => a.executedAt.compareTo(b.executedAt));
      final schedule = _computeSchedule(
        taskType: taskType,
        ascendingHistory: ascendingHistory,
        scheduleValue: scheduleValue,
        scheduleUnit: scheduleUnit,
      );

      final batch = _firestore.batch();
      batch.update(_executionsRef(taskId).doc(executionId), {
        'executedAt': Timestamp.fromDate(executedAt),
        'comment': comment,
      });
      batch.update(
        _taskDefinitionsRef().doc(taskId),
        _scheduleFieldsData(schedule),
      );
      await batch.commit();
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

      final recentHistory = await _fetchAscendingHistory(
        taskId,
        limit: scheduleHistoryLimit + 1,
      );
      final (taskType, scheduleValue, scheduleUnit) =
          await _fetchScheduleConfig(taskId);

      final ascendingHistory = recentHistory
          .where((history) => history.id != executionId)
          .toList();
      final schedule = _computeSchedule(
        taskType: taskType,
        ascendingHistory: ascendingHistory,
        scheduleValue: scheduleValue,
        scheduleUnit: scheduleUnit,
      );

      final batch = _firestore.batch();
      batch.delete(executionRef);
      batch.update(
        _taskDefinitionsRef().doc(taskId),
        _scheduleFieldsData(schedule),
      );
      await batch.commit();
    } on TaskRepositoryException {
      rethrow;
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
    List<(TaskItem, List<TaskHistory>)> taskItems,
  ) async {
    final writes = taskItems
        .expand((e) => _convertWriteData(e.$1, e.$2))
        .toList();
    try {
      for (var i = 0; i < writes.length; i += 500) {
        final batch = _firestore.batch();
        for (final (def, data) in writes.skip(i).take(500)) {
          batch.set(def, data);
        }
        await batch.commit();
      }
    } catch (e) {
      throw TaskSaveException(e.toString());
    }
  }

  WriteData _convertWriteData(
    TaskItem taskItem,
    List<TaskHistory> taskHistory,
  ) {
    final newId = _uuid.v4();
    return [
      (
        _taskDefinitionsRef().doc(newId),
        _taskDefinitionData(
          taskType: taskItem.taskType,
          name: taskItem.name,
          furigana: taskItem.furigana,
          icon: taskItem.icon,
          color: taskItem.color,
          scheduleValue: taskItem.scheduleValueOrDefault,
          scheduleUnit: taskItem.scheduleUnitOrDefault,
          taskHistory: taskHistory,
        ),
      ),
      for (final history in taskHistory)
        (
          _executionsRef(newId).doc(_uuid.v4()),
          _executionData(
            executedAt: history.executedAt,
            comment: history.comment,
          ),
        ),
    ];
  }

  Map<String, dynamic> _taskDefinitionData({
    required TaskType taskType,
    required String name,
    required String furigana,
    required String icon,
    required TaskColor color,
    int? scheduleValue,
    ScheduleUnit? scheduleUnit,
    List<TaskHistory> taskHistory = const [],
  }) {
    final ascendingHistory = taskHistory.sorted(
      (a, b) => a.executedAt.compareTo(b.executedAt),
    );
    final schedule = _computeSchedule(
      taskType: taskType,
      ascendingHistory: ascendingHistory,
      scheduleValue: scheduleValue,
      scheduleUnit: scheduleUnit,
    );
    return {
      'taskType': taskType.name,
      'name': name,
      'furigana': furigana,
      'icon': icon,
      'color': color.name,
      'scheduleConfig': taskType == TaskType.scheduled
          ? {'scheduleValue': scheduleValue, 'scheduleUnit': scheduleUnit!.name}
          : null,
      ..._scheduleFieldsData(schedule),
    };
  }

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

  // 直近 limit 件の実行履歴を昇順で取得する
  Future<List<TaskHistory>> _fetchAscendingHistory(
    String taskId, {
    int limit = scheduleHistoryLimit,
  }) async {
    final executionSnap = await _executionsRef(
      taskId,
    ).orderBy('executedAt').limitToLast(limit).get();
    return executionSnap.docs.map(_taskHistoryFromDoc).toList();
  }

  Future<(TaskType, int?, ScheduleUnit?)> _fetchScheduleConfig(
    String taskId,
  ) async {
    final taskDefinitionSnap = await _taskDefinitionsRef().doc(taskId).get();
    final taskDefData = taskDefinitionSnap.data();
    if (taskDefData == null) throw TaskNotFoundException(taskId: taskId);
    final taskType = TaskType.values.byName(taskDefData['taskType'] as String);
    final config = taskDefData['scheduleConfig'] as Map<String, dynamic>?;
    return (
      taskType,
      config?['scheduleValue'] as int?,
      config == null
          ? null
          : ScheduleUnit.values.byName(config['scheduleUnit'] as String),
    );
  }

  ({DateTime? lastExecutedAt, DateTime? scheduledAt}) _computeSchedule({
    required TaskType taskType,
    required List<TaskHistory> ascendingHistory,
    int? scheduleValue,
    ScheduleUnit? scheduleUnit,
  }) {
    final recentHistory = recentHistoryForSchedule(ascendingHistory);
    return (
      lastExecutedAt: computeLastExecutedAt(recentHistory),
      scheduledAt: computeScheduledAt(
        taskType: taskType,
        ascendingHistory: recentHistory,
        scheduleValue: scheduleValue,
        scheduleUnit: scheduleUnit,
      ),
    );
  }

  Map<String, dynamic> _scheduleFieldsData(
    ({DateTime? lastExecutedAt, DateTime? scheduledAt}) schedule,
  ) => {
    'lastExecutedAt': schedule.lastExecutedAt != null
        ? Timestamp.fromDate(schedule.lastExecutedAt!)
        : null,
    'nextScheduledAt': schedule.scheduledAt != null
        ? Timestamp.fromDate(schedule.scheduledAt!)
        : null,
  };
}
