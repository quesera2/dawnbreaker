import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_history_cursor.dart';
import 'package:dawnbreaker/data/model/task_history_page.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';

abstract interface class TaskRepository {
  Stream<List<TaskItem>> allTaskItems();

  Stream<TaskItem?> watchTaskById(String taskId);

  Future<TaskItem> findTaskById(String taskId);

  // 直近の実行履歴（新しい順ではなく実行日時の昇順）をストリームで返す。
  // 詳細画面での表示専用で、ホーム画面の一覧取得（allTaskItems）はこれを購読しない
  Stream<List<TaskHistory>> watchTaskHistory(String taskId);

  Future<TaskHistoryPage> fetchOlderHistory(
    String taskId, {
    required TaskHistoryCursor cursor,
    int limit = 20,
  });

  Future<String> addTask({
    required TaskType taskType,
    required String name,
    required String icon,
    required TaskColor color,
    int? scheduleValue,
    ScheduleUnit? scheduleUnit,
  });

  Future<void> updateTask({
    required String taskId,
    required TaskType taskType,
    required String name,
    required String icon,
    required TaskColor color,
    int? scheduleValue,
    ScheduleUnit? scheduleUnit,
  });

  Future<TaskHistory> recordExecution(
    String taskId, {
    required DateTime executedAt,
    String? comment,
  });

  Future<void> updateExecution(
    String executionId, {
    required String taskId,
    required DateTime executedAt,
    String? comment,
  });

  Future<void> deleteExecution(String executionId, {required String taskId});

  // 削除した実行履歴（全件）を返す。restoreTask にそのまま渡すことで
  // taskHistory が直近件数に絞られている場合でも履歴を欠損なく復元できる
  Future<List<TaskHistory>> deleteTask(String taskId);

  Future<void> deleteAllTasks();

  Future<void> restoreTask(TaskItem taskItem, List<TaskHistory> taskHistory);
}
