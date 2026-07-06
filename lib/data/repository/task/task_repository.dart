import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_history_cursor.dart';
import 'package:dawnbreaker/data/model/task_history_page.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';

// 実装は addTask/updateTask/recordExecution/updateExecution/deleteExecution/
// restoreTask で実行履歴やスケジュール設定が変わるたびに、TaskItem の
// lastExecutedAt/scheduledAt を最新の履歴から再計算して保持し続けること。
// ここを怠るとホーム画面のソート順や次回予定日の表示が古いまま残る
abstract interface class TaskRepository {
  Stream<List<TaskItem>> allTaskItems();

  Stream<TaskItem?> watchTaskById(String taskId);

  Future<TaskItem> findTaskById(String taskId);

  // 実行履歴を新しい方から遡ってページ単位で取得する（返却順は新しい順）。
  // cursor が null のときは最新のページを返す。詳細画面での表示専用で、
  // ホーム画面の一覧取得（allTaskItems）はこれを呼ばない
  Future<TaskHistoryPage> fetchTaskHistory(
    String taskId, {
    TaskHistoryCursor? cursor,
    int limit = 10,
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
  // 履歴を欠損なく復元できる
  Future<List<TaskHistory>> deleteTask(String taskId);

  Future<void> deleteAllTasks();

  Future<void> restoreTask(List<(TaskItem, List<TaskHistory>)> taskItems);
}
