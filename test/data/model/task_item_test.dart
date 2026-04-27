import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PeriodTaskItem.scheduledAt', () {
    test('履歴が0件のとき null を返す', () {
      expect(_periodTask().scheduledAt, isNull);
    });

    test('履歴が1件のとき null を返す', () {
      final task = _periodTask(
        taskHistory: [
          TaskHistory(id: 1, executedAt: DateTime(2025, 1, 1), comment: null),
        ],
      );
      expect(task.scheduledAt, isNull);
    });

    test('履歴が2件のとき 間隔の平均だけ後の日付を返す', () {
      // 間隔: 31日 → 平均31日 → 2/1 + 31日 = 3/4
      final task = _periodTask(
        taskHistory: [
          TaskHistory(id: 1, executedAt: DateTime(2025, 1, 1), comment: null),
          TaskHistory(id: 2, executedAt: DateTime(2025, 2, 1), comment: null),
        ],
      );
      expect(task.scheduledAt, DateTime(2025, 3, 4));
    });

    test('履歴が3件のとき 全間隔の平均を使う', () {
      // 間隔: 10日, 20日 → 平均15日 → 1/31 + 15日 = 2/15
      final task = _periodTask(
        taskHistory: [
          TaskHistory(id: 1, executedAt: DateTime(2025, 1, 1), comment: null),
          TaskHistory(id: 2, executedAt: DateTime(2025, 1, 11), comment: null),
          TaskHistory(id: 3, executedAt: DateTime(2025, 1, 31), comment: null),
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
        taskHistory: [
          TaskHistory(id: 1, executedAt: DateTime(2025, 1, 1), comment: null),
        ],
      );
      expect(task.scheduledAt, DateTime(2025, 1, 15));
    });

    test('ScheduleUnit.week: 最後の実行日 + n週', () {
      final task = _scheduledTask(
        scheduleValue: 2,
        scheduleUnit: ScheduleUnit.week,
        taskHistory: [
          TaskHistory(id: 1, executedAt: DateTime(2025, 1, 1), comment: null),
        ],
      );
      expect(task.scheduledAt, DateTime(2025, 1, 15));
    });

    test('ScheduleUnit.month: 最後の実行日 + nヶ月', () {
      final task = _scheduledTask(
        scheduleValue: 3,
        scheduleUnit: ScheduleUnit.month,
        taskHistory: [
          TaskHistory(id: 1, executedAt: DateTime(2025, 1, 10), comment: null),
        ],
      );
      expect(task.scheduledAt, DateTime(2025, 4, 10));
    });
  });

  group('PeriodTaskItem.executionIntervalDays', () {
    test('履歴が1件のとき空リストを返す', () {
      final task = _periodTask(
        taskHistory: [
          TaskHistory(id: 1, executedAt: DateTime(2025, 1, 1), comment: null),
        ],
      );
      expect(task.executionIntervalDays, isEmpty);
    });

    test('深夜0時の履歴: 1/1→2/1 は31日', () {
      final task = _periodTask(
        taskHistory: [
          TaskHistory(id: 1, executedAt: DateTime(2025, 1, 1), comment: null),
          TaskHistory(id: 2, executedAt: DateTime(2025, 2, 1), comment: null),
        ],
      );
      expect(task.executionIntervalDays, [31]);
    });

    test('夜遅い実行→翌朝実行でも1日としてカウントされる（22:00→翌08:00）', () {
      final task = _periodTask(
        taskHistory: [
          TaskHistory(
            id: 1,
            executedAt: DateTime(2025, 1, 1, 22, 0),
            comment: null,
          ),
          TaskHistory(
            id: 2,
            executedAt: DateTime(2025, 1, 2, 8, 0),
            comment: null,
          ),
        ],
      );
      expect(task.executionIntervalDays, [1]);
    });

    test('実行時刻が異なっても複数インターバルが正しく計算される', () {
      // 1/1 14:00 → 2/1 08:00 → 3/4 22:00
      // カレンダー日数: 31日, 31日
      final task = _periodTask(
        taskHistory: [
          TaskHistory(
            id: 1,
            executedAt: DateTime(2025, 1, 1, 14, 0),
            comment: null,
          ),
          TaskHistory(
            id: 2,
            executedAt: DateTime(2025, 2, 1, 8, 0),
            comment: null,
          ),
          TaskHistory(
            id: 3,
            executedAt: DateTime(2025, 3, 4, 22, 0),
            comment: null,
          ),
        ],
      );
      expect(task.executionIntervalDays, [31, 31]);
    });
  });

  group('TaskItem.computeProgress', () {
    test('履歴が空のとき NoDueDate を返す', () {
      expect(
        _periodTask().computeProgress(DateTime(2025, 2, 1)),
        isA<NoDueDate>(),
      );
    });

    test('scheduledAt が null のとき NoDueDate を返す', () {
      // PeriodTask で履歴1件 → scheduledAt が null
      final task = _periodTask(
        taskHistory: [
          TaskHistory(id: 1, executedAt: DateTime(2025, 1, 1), comment: null),
        ],
      );
      expect(task.computeProgress(DateTime(2025, 2, 1)), isA<NoDueDate>());
    });

    test('期限前: DueDate で isOverdue=false, daysRemaining が正', () {
      // lastExecutedAt=1/1, scheduledAt=3/4(+62日), now=2/1(+31日) → progress=0.5
      final task = _periodTask(
        taskHistory: [
          TaskHistory(id: 1, executedAt: DateTime(2025, 1, 1), comment: null),
          TaskHistory(id: 2, executedAt: DateTime(2025, 3, 4), comment: null),
        ],
      );
      // scheduledAt = 3/4 + 62日 = 5/5
      final progress = task.computeProgress(DateTime(2025, 4, 4));
      expect(progress, isA<DueDate>());
      final dueDate = progress as DueDate;
      expect(dueDate.isOverdue, false);
      expect(dueDate.daysRemaining, greaterThan(0));
    });

    test('期限超過: DueDate で isOverdue=true, daysRemaining が負', () {
      final task = _scheduledTask(
        scheduleValue: 30,
        scheduleUnit: ScheduleUnit.day,
        taskHistory: [
          TaskHistory(id: 1, executedAt: DateTime(2025, 1, 1), comment: null),
        ],
      );
      // scheduledAt = 1/31, now = 2/15 → 超過
      final progress = task.computeProgress(DateTime(2025, 2, 15));
      expect(progress, isA<DueDate>());
      final dueDate = progress as DueDate;
      expect(dueDate.isOverdue, true);
      expect(dueDate.daysRemaining, lessThan(0));
    });

    test('totalDays が 0 のとき DueDate で progress は 0.0', () {
      // lastExecutedAt と scheduledAt が同じ日
      final task = _scheduledTask(
        scheduleValue: 0,
        scheduleUnit: ScheduleUnit.day,
        taskHistory: [
          TaskHistory(id: 1, executedAt: DateTime(2025, 1, 1), comment: null),
        ],
      );
      final progress = task.computeProgress(DateTime(2025, 1, 1));
      expect(progress, isA<DueDate>());
      expect((progress as DueDate).progress, 0.0);
    });

    group('翌日期限タスクが今日と誤判定されない', () {
      // 毎日スケジュール: 4/23実行 → scheduledAt=4/24, 4/24実行 → scheduledAt=4/25
      test('scheduledAt=4/24, now=4/24 14:00: isToday=true', () {
        final task = _scheduledTask(
          scheduleValue: 1,
          scheduleUnit: ScheduleUnit.day,
          taskHistory: [
            TaskHistory(
              id: 1,
              executedAt: DateTime(2026, 4, 23),
              comment: null,
            ),
          ],
        );
        final p = task.computeProgress(DateTime(2026, 4, 24, 14, 0)) as DueDate;
        expect(p.isToday, true);
        expect(p.daysRemaining, 0);
      });

      test(
        'scheduledAt=4/25, now=4/24 14:00: isToday=false, daysRemaining=1',
        () {
          final task = _scheduledTask(
            scheduleValue: 1,
            scheduleUnit: ScheduleUnit.day,
            taskHistory: [
              TaskHistory(
                id: 1,
                executedAt: DateTime(2026, 4, 24),
                comment: null,
              ),
            ],
          );
          final p =
              task.computeProgress(DateTime(2026, 4, 24, 14, 0)) as DueDate;
          expect(p.isToday, false);
          expect(p.daysRemaining, 1);
        },
      );
    });

    group('lastExecutedAt に時刻が含まれていても progress が正しく計算される', () {
      // 30日スケジュール, 1/1 14:00に実行 → scheduledAt=1/31
      // totalDays は 30日のはず。1/16 00:00 時点で elapsed=15日 → progress≈0.5
      test('14:00実行でも totalDays=30, elapsed=15 → progress=0.5', () {
        final task = _scheduledTask(
          scheduleValue: 30,
          scheduleUnit: ScheduleUnit.day,
          taskHistory: [
            TaskHistory(
              id: 1,
              executedAt: DateTime(2025, 1, 1, 14, 0),
              comment: null,
            ),
          ],
        );
        final p = task.computeProgress(DateTime(2025, 1, 16)) as DueDate;
        expect(p.daysRemaining, 15); // 1/31 - 1/16 = 15日
        expect(p.progress, closeTo(0.5, 0.01));
      });
    });

    group('isOverdue / isToday 境界値', () {
      // scheduledAt = 1/31 (30日スケジュール, 実行日 1/1)
      TaskItem task30() => _scheduledTask(
        scheduleValue: 30,
        scheduleUnit: ScheduleUnit.day,
        taskHistory: [
          TaskHistory(id: 1, executedAt: DateTime(2025, 1, 1), comment: null),
        ],
      );

      test('scheduledAt の前日: isOverdue=false, daysRemaining=1', () {
        final p = task30().computeProgress(DateTime(2025, 1, 30)) as DueDate;
        expect(p.isOverdue, false);
        expect(p.daysRemaining, 1);
        expect(p.isToday, false);
      });

      test('scheduledAt 当日の 00:00: isOverdue=false, isToday=true', () {
        final p =
            task30().computeProgress(DateTime(2025, 1, 31, 0, 0)) as DueDate;
        expect(p.isOverdue, false);
        expect(p.isToday, true);
      });

      test('scheduledAt 当日の 12:00: isOverdue=false, isToday=true', () {
        final p =
            task30().computeProgress(DateTime(2025, 1, 31, 12, 0)) as DueDate;
        expect(p.isOverdue, false);
        expect(p.isToday, true);
      });

      test('scheduledAt 当日の 23:59: isOverdue=false, isToday=true', () {
        final p =
            task30().computeProgress(DateTime(2025, 1, 31, 23, 59)) as DueDate;
        expect(p.isOverdue, false);
        expect(p.isToday, true);
      });

      test('scheduledAt の翌日: isOverdue=true, daysRemaining=-1', () {
        final p = task30().computeProgress(DateTime(2025, 2, 1)) as DueDate;
        expect(p.isOverdue, true);
        expect(p.daysRemaining, -1);
      });
    });
  });
}

TaskItem _periodTask({List<TaskHistory> taskHistory = const []}) =>
    TaskItem.period(
      id: 1,
      name: 'テスト',
      furigana: 'てすと',
      icon: '📝',
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
  icon: '📝',
  color: TaskColor.none,
  scheduleValue: scheduleValue,
  scheduleUnit: scheduleUnit,
  taskHistory: taskHistory,
);
