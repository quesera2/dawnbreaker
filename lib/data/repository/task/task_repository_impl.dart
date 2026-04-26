import 'package:collection/collection.dart';
import 'package:dawnbreaker/core/util/furigana_translate.dart';
import 'package:dawnbreaker/data/database/app_database.dart';
import 'package:dawnbreaker/data/database/app_database_provider.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_repository_impl.g.dart';

@riverpod
TaskRepository taskRepository(Ref ref) {
  return TaskRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    furiganaTranslate: ref.watch(furiganaTranslateProvider),
  );
}

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({
    required AppDatabase db,
    required FuriganaTranslate furiganaTranslate,
  }) : _db = db,
       _furiganaTranslate = furiganaTranslate;

  final AppDatabase _db;
  final FuriganaTranslate _furiganaTranslate;

  @override
  Stream<List<TaskItem>> allTaskItems() {
    return _baseTaskQuery().watch().map(_buildAllTaskItemsFromRows);
  }

  @override
  Stream<TaskItem?> watchTaskById(int taskId) {
    return _baseTaskQuery(
      where: _db.taskDefinitions.id.equals(taskId),
    ).watch().map((rows) {
      if (rows.isEmpty) return null;
      return _buildTaskItemFromRows(rows);
    });
  }

  @override
  Future<TaskItem> findTaskById(int taskId) async {
    try {
      final rows = await _baseTaskQuery(
        where: _db.taskDefinitions.id.equals(taskId),
      ).get();
      if (rows.isEmpty) {
        throw TaskNotFoundException(taskId: taskId);
      }
      return _buildTaskItemFromRows(rows);
    } on TaskRepositoryException {
      rethrow;
    } catch (e) {
      throw TaskLoadException(e.toString());
    }
  }

  JoinedSelectStatement<HasResultSet, dynamic> _baseTaskQuery({
    Expression<bool>? where,
  }) {
    final query = _db.select(_db.taskDefinitions).join([
      leftOuterJoin(
        _db.taskScheduledConfigs,
        _db.taskScheduledConfigs.taskDefinitionId.equalsExp(
          _db.taskDefinitions.id,
        ),
      ),
      leftOuterJoin(
        _db.taskExecutions,
        _db.taskExecutions.taskDefinitionId.equalsExp(_db.taskDefinitions.id),
      ),
    ])..orderBy([OrderingTerm.asc(_db.taskExecutions.executedAt)]);
    if (where != null) {
      query.where(where);
    }
    return query;
  }

  List<TaskItem> _buildAllTaskItemsFromRows(List<TypedResult> rows) {
    final grouped = rows.groupListsBy(
      (row) => row.readTable(_db.taskDefinitions).id,
    );

    final items = grouped.values.map(_buildTaskItemFromRows).toList();

    items.sort((a, b) {
      final aDate = a.scheduledAt;
      final bDate = b.scheduledAt;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });

    return items;
  }

  TaskItem _buildTaskItemFromRows(List<TypedResult> rows) {
    final def = rows.first.readTable(_db.taskDefinitions);
    final config = rows.first.readTableOrNull(_db.taskScheduledConfigs);
    final taskHistory = rows
        .map((r) => r.readTableOrNull(_db.taskExecutions))
        .nonNulls
        .map(
          (e) => TaskHistory(
            id: e.id,
            executedAt: e.executedAt,
            comment: e.comment,
          ),
        )
        .toList();

    return switch (def.taskType) {
      TaskType.irregular => TaskItem.irregular(
        id: def.id,
        name: def.name,
        furigana: def.furigana,
        icon: def.icon,
        color: def.color,
        taskHistory: taskHistory,
      ),
      TaskType.period => TaskItem.period(
        id: def.id,
        name: def.name,
        furigana: def.furigana,
        icon: def.icon,
        color: def.color,
        taskHistory: taskHistory,
      ),
      TaskType.scheduled =>
        config != null
            ? TaskItem.scheduled(
                id: def.id,
                name: def.name,
                furigana: def.furigana,
                icon: def.icon,
                color: def.color,
                scheduleValue: config.scheduleValue,
                scheduleUnit: config.scheduleUnit,
                taskHistory: taskHistory,
              )
            : throw TaskNotFoundException(taskId: def.id),
    };
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
    if (taskType == TaskType.scheduled &&
        (scheduleValue == null || scheduleUnit == null)) {
      throw const TaskInvalidArgumentException(
        'scheduled タスクの追加には scheduleValue と scheduleUnit が必要です',
      );
    }
    try {
      final furigana = await _furiganaTranslate.translate(name);
      return await _db.transaction(() async {
        final id = await _db
            .into(_db.taskDefinitions)
            .insert(
              TaskDefinitionsCompanion.insert(
                taskType: taskType,
                name: name,
                furigana: furigana,
                icon: icon,
                color: color,
              ),
            );
        if (taskType == TaskType.scheduled) {
          await _db
              .into(_db.taskScheduledConfigs)
              .insert(
                TaskScheduledConfigsCompanion.insert(
                  taskDefinitionId: Value(id),
                  scheduleValue: scheduleValue!,
                  scheduleUnit: scheduleUnit!,
                ),
              );
        }
        await _db
            .into(_db.taskExecutions)
            .insert(
              TaskExecutionsCompanion.insert(
                taskDefinitionId: id,
                executedAt: executedAt,
              ),
            );
        return id;
      });
    } catch (e) {
      throw TaskSaveException(e.toString());
    }
  }

  @override
  Future<TaskHistory> recordExecution(
    int taskId, {
    required DateTime executedAt,
    String? comment,
  }) async {
    try {
      final id = await _db
          .into(_db.taskExecutions)
          .insert(
            TaskExecutionsCompanion.insert(
              taskDefinitionId: taskId,
              executedAt: executedAt,
              comment: Value(comment),
            ),
          );
      return TaskHistory(id: id, executedAt: executedAt, comment: comment);
    } catch (e) {
      throw TaskSaveException(e.toString());
    }
  }

  @override
  Future<void> deleteExecution(int executionId) async {
    try {
      await (_db.delete(
        _db.taskExecutions,
      )..where((t) => t.id.equals(executionId))).go();
    } catch (e) {
      throw TaskDeleteException(e.toString());
    }
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
    try {
      final furigana = await _furiganaTranslate.translate(name);
      await _db.transaction(() async {
        await (_db.update(
          _db.taskDefinitions,
        )..where((t) => t.id.equals(taskId))).write(
          TaskDefinitionsCompanion(
            taskType: Value(taskType),
            name: Value(name),
            furigana: Value(furigana),
            icon: Value(icon),
            color: Value(color),
          ),
        );
        switch (taskType) {
          case TaskType.irregular:
          case TaskType.period:
            await (_db.delete(
              _db.taskScheduledConfigs,
            )..where((t) => t.taskDefinitionId.equals(taskId))).go();
          case TaskType.scheduled:
            if (scheduleValue == null || scheduleUnit == null) {
              throw const TaskInvalidArgumentException(
                'scheduled タスクの更新には scheduleValue と scheduleUnit が必要です',
              );
            }
            await _db
                .into(_db.taskScheduledConfigs)
                .insertOnConflictUpdate(
                  TaskScheduledConfigsCompanion.insert(
                    taskDefinitionId: Value(taskId),
                    scheduleValue: scheduleValue,
                    scheduleUnit: scheduleUnit,
                  ),
                );
        }
      });
    } on TaskRepositoryException {
      rethrow;
    } catch (e) {
      throw TaskUpdateException(e.toString());
    }
  }

  @override
  Future<void> deleteTask(int taskId) async {
    try {
      await (_db.delete(
        _db.taskDefinitions,
      )..where((t) => t.id.equals(taskId))).go();
      // task_executions / task_scheduled_configs はカスケード削除
    } catch (e) {
      throw TaskDeleteException(e.toString());
    }
  }

  @override
  Future<void> restoreTask(TaskItem taskItem) async {
    try {
      await _db.transaction(() async {
        final id = await _db
            .into(_db.taskDefinitions)
            .insert(
              TaskDefinitionsCompanion.insert(
                taskType: taskItem.taskType,
                name: taskItem.name,
                furigana: taskItem.furigana,
                icon: taskItem.icon,
                color: taskItem.color,
              ),
            );
        if (taskItem.taskType == TaskType.scheduled) {
          await _db
              .into(_db.taskScheduledConfigs)
              .insert(
                TaskScheduledConfigsCompanion.insert(
                  taskDefinitionId: Value(id),
                  scheduleValue: taskItem.scheduleValueOrDefault,
                  scheduleUnit: taskItem.scheduleUnitOrDefault,
                ),
              );
        }
        await _db.batch((batch) {
          batch.insertAll(
            _db.taskExecutions,
            taskItem.taskHistory.map(
              (history) => TaskExecutionsCompanion.insert(
                taskDefinitionId: id,
                executedAt: history.executedAt,
              ),
            ),
          );
        });
      });
    } catch (e) {
      throw TaskSaveException(e.toString());
    }
  }
}
