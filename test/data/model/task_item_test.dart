import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PeriodTaskItem.scheduledAt', () {
    test('履歴が0件のとき null を返す', () {
      expect(_periodTask().scheduledAt, isNull);
    });

    test('履歴が1件のとき null を返す', () {
      final task = _periodTask(
        taskHistory: [TaskHistory(id: 1, executedAt: DateTime(2025, 1, 1))],
      );
      expect(task.scheduledAt, isNull);
    });

    test('履歴が2件のとき 間隔の平均だけ後の日付を返す', () {
      // 間隔: 31日 → 平均31日 → 2/1 + 31日 = 3/4
      final task = _periodTask(
        taskHistory: [
          TaskHistory(id: 1, executedAt: DateTime(2025, 1, 1)),
          TaskHistory(id: 2, executedAt: DateTime(2025, 2, 1)),
        ],
      );
      expect(task.scheduledAt, DateTime(2025, 3, 4));
    });

    test('履歴が3件のとき 全間隔の平均を使う', () {
      // 間隔: 10日, 20日 → 平均15日 → 1/31 + 15日 = 2/15
      final task = _periodTask(
        taskHistory: [
          TaskHistory(id: 1, executedAt: DateTime(2025, 1, 1)),
          TaskHistory(id: 2, executedAt: DateTime(2025, 1, 11)),
          TaskHistory(id: 3, executedAt: DateTime(2025, 1, 31)),
        ],
      );
      expect(task.scheduledAt, DateTime(2025, 2, 15));
    });
  });

  group('ScheduledTaskItem.scheduledAt', () {
    test('履歴が0件のとき null を返す', () {
      final task = _scheduledTask(
        scheduleValue: 1,
        scheduleUnit: ScheduleUnit.month,
      );
      expect(task.scheduledAt, isNull);
    });

    test('ScheduleUnit.day: 最後の実行日 + n日', () {
      final task = _scheduledTask(
        scheduleValue: 14,
        scheduleUnit: ScheduleUnit.day,
        taskHistory: [TaskHistory(id: 1, executedAt: DateTime(2025, 1, 1))],
      );
      expect(task.scheduledAt, DateTime(2025, 1, 15));
    });

    test('ScheduleUnit.week: 最後の実行日 + n週', () {
      final task = _scheduledTask(
        scheduleValue: 2,
        scheduleUnit: ScheduleUnit.week,
        taskHistory: [TaskHistory(id: 1, executedAt: DateTime(2025, 1, 1))],
      );
      expect(task.scheduledAt, DateTime(2025, 1, 15));
    });

    test('ScheduleUnit.month: 最後の実行日 + nヶ月', () {
      final task = _scheduledTask(
        scheduleValue: 3,
        scheduleUnit: ScheduleUnit.month,
        taskHistory: [TaskHistory(id: 1, executedAt: DateTime(2025, 1, 10))],
      );
      expect(task.scheduledAt, DateTime(2025, 4, 10));
    });
  });
}

TaskItem _periodTask({List<TaskHistory> taskHistory = const []}) =>
    TaskItem.period(
      id: 1,
      name: 'テスト',
      furigana: 'てすと',
      color: TaskColor.none,
      taskHistory: taskHistory,
    );

TaskItem _scheduledTask({
  required int scheduleValue,
  required ScheduleUnit scheduleUnit,
  List<TaskHistory> taskHistory = const [],
}) => TaskItem.scheduled(
  id: 1,
  name: 'テスト',
  furigana: 'てすと',
  color: TaskColor.none,
  scheduleValue: scheduleValue,
  scheduleUnit: scheduleUnit,
  taskHistory: taskHistory,
);
