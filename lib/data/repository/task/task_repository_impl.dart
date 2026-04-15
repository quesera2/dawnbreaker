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
    return (_db.select(_db.taskDefinitions).join([
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
    ])..orderBy([OrderingTerm.asc(_db.taskExecutions.executedAt)])).watch().map(
      _buildAllTaskItemsFromRows,
    );
  }

  List<TaskItem> _buildAllTaskItemsFromRows(List<TypedResult> rows) {
    final grouped = <int, List<TypedResult>>{};
    for (final row in rows) {
      final id = row.readTable(_db.taskDefinitions).id;
      grouped.putIfAbsent(id, () => []).add(row);
    }

    final items = grouped.values.map((group) {
      final def = group.first.readTable(_db.taskDefinitions);
      final config = group.first.readTableOrNull(_db.taskScheduledConfigs);
      final executions = group
          .map((r) => r.readTableOrNull(_db.taskExecutions))
          .nonNulls
          .toList();
      final taskHistory = executions
          .map((e) => TaskHistory(id: e.id, executedAt: e.executedAt))
          .toList();
      final registeredAt =
          executions.isNotEmpty ? executions.first.executedAt : DateTime.now();

      return switch (def.taskType) {
        TaskType.period => TaskItem.period(
          id: def.id,
          name: def.name,
          furigana: def.furigana,
          color: def.color,
          registeredAt: registeredAt,
          taskHistory: taskHistory,
        ),
        TaskType.scheduled => TaskItem.scheduled(
          id: def.id,
          name: def.name,
          furigana: def.furigana,
          color: def.color,
          registeredAt: registeredAt,
          scheduleValue: config!.scheduleValue,
          scheduleUnit: config.scheduleUnit,
          taskHistory: taskHistory,
        ),
      };
    }).toList();

    items.sort((a, b) {
      final aDate = a.scheduledAt;
      final bDate = b.scheduledAt;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });

    return items;
  }

  @override
  Future<int> addPeriodTask({
    required String name,
    required TaskColor color,
  }) async {
    try {
      final furigana = await _furiganaTranslate.translate(name) ?? '';
      return _db.transaction(() async {
        final id = await _db
            .into(_db.taskDefinitions)
            .insert(
              TaskDefinitionsCompanion.insert(
                taskType: TaskType.period,
                name: name,
                furigana: furigana,
                color: color,
              ),
            );
        await _db
            .into(_db.taskExecutions)
            .insert(
              TaskExecutionsCompanion.insert(
                taskDefinitionId: id,
                executedAt: DateTime.now(),
              ),
            );
        return id;
      });
    } catch (e) {
      throw TaskRepositoryException('タスクの追加に失敗しました', cause: e);
    }
  }

  @override
  Future<int> addScheduledTask({
    required String name,
    required TaskColor color,
    required int scheduleValue,
    required ScheduleUnit scheduleUnit,
  }) async {
    try {
      final furigana = await _furiganaTranslate.translate(name) ?? '';
      return _db.transaction(() async {
        final id = await _db
            .into(_db.taskDefinitions)
            .insert(
              TaskDefinitionsCompanion.insert(
                taskType: TaskType.scheduled,
                name: name,
                furigana: furigana,
                color: color,
              ),
            );
        await _db
            .into(_db.taskScheduledConfigs)
            .insert(
              TaskScheduledConfigsCompanion.insert(
                taskDefinitionId: Value(id),
                scheduleValue: scheduleValue,
                scheduleUnit: scheduleUnit,
              ),
            );
        await _db
            .into(_db.taskExecutions)
            .insert(
              TaskExecutionsCompanion.insert(
                taskDefinitionId: id,
                executedAt: DateTime.now(),
              ),
            );
        return id;
      });
    } catch (e) {
      throw TaskRepositoryException('タスクの追加に失敗しました', cause: e);
    }
  }

  @override
  Future<void> recordExecution(int taskId, {DateTime? executedAt}) async {
    try {
      await _db
          .into(_db.taskExecutions)
          .insert(
            TaskExecutionsCompanion.insert(
              taskDefinitionId: taskId,
              executedAt: executedAt ?? DateTime.now(),
            ),
          );
    } catch (e) {
      throw TaskRepositoryException('実行記録の追加に失敗しました', cause: e);
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
      throw TaskRepositoryException('タスクの削除に失敗しました', cause: e);
    }
  }
}
