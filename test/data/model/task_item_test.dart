import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScheduledTaskItem.scheduledAt', () {
    test('lastExecutedAt が null のとき null を返す', () {
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
        lastExecutedAt: DateTime(2025, 1, 1),
      );
      expect(task.scheduledAt, DateTime(2025, 1, 15));
    });

    test('ScheduleUnit.week: 最後の実行日 + n週', () {
      final task = _scheduledTask(
        scheduleValue: 2,
        scheduleUnit: ScheduleUnit.week,
        lastExecutedAt: DateTime(2025, 1, 1),
      );
      expect(task.scheduledAt, DateTime(2025, 1, 15));
    });

    test('ScheduleUnit.month: 最後の実行日 + nヶ月', () {
      final task = _scheduledTask(
        scheduleValue: 3,
        scheduleUnit: ScheduleUnit.month,
        lastExecutedAt: DateTime(2025, 1, 10),
      );
      expect(task.scheduledAt, DateTime(2025, 4, 10));
    });
  });

  group('TaskItem.computeProgress', () {
    test('履歴が空のとき 期日が未定になる', () {
      expect(
        _periodTask().computeProgress(DateTime(2025, 2, 1)),
        isA<NoDueDate>(),
      );
    });

    test('履歴が1件のとき（次回予定日が未算出）期日が未定になる', () {
      final task = _periodTask(lastExecutedAt: DateTime(2025, 1, 1));
      expect(task.computeProgress(DateTime(2025, 2, 1)), isA<NoDueDate>());
    });

    test('期限前: 超過していない、残日数がある', () {
      final lastExecutedAt = DateTime(2025, 3, 4);
      final scheduledAt = lastExecutedAt.add(const Duration(days: 62));
      final task = _periodTask(
        lastExecutedAt: lastExecutedAt,
        scheduledAt: scheduledAt,
      );
      final progress = task.computeProgress(DateTime(2025, 4, 4));
      expect(progress, isA<DueDate>());
      final dueDate = progress as DueDate;
      expect(dueDate.isOverdue, false);
      expect(dueDate.daysRemaining, greaterThan(0));
    });

    test('期限超過: 超過している、残日数が負', () {
      final task = _scheduledTask(
        scheduleValue: 30,
        scheduleUnit: ScheduleUnit.day,
        lastExecutedAt: DateTime(2025, 1, 1),
      );
      // scheduledAt = 1/31, now = 2/15 → 超過
      final progress = task.computeProgress(DateTime(2025, 2, 15));
      expect(progress, isA<DueDate>());
      final dueDate = progress as DueDate;
      expect(dueDate.isOverdue, true);
      expect(dueDate.daysRemaining, lessThan(0));
    });

    test('スケジュール間隔が0日のとき 進捗は0.0', () {
      // lastExecutedAt と scheduledAt が同じ日
      final task = _scheduledTask(
        scheduleValue: 0,
        scheduleUnit: ScheduleUnit.day,
        lastExecutedAt: DateTime(2025, 1, 1),
      );
      final progress = task.computeProgress(DateTime(2025, 1, 1));
      expect(progress, isA<DueDate>());
      expect((progress as DueDate).progress, 0.0);
    });

    group('翌日期限タスクが今日と誤判定されない', () {
      // 毎日スケジュール: 4/23実行 → 期日=4/24, 4/24実行 → 期日=4/25
      test('期日当日14:00: 当日扱いになる', () {
        final task = _scheduledTask(
          scheduleValue: 1,
          scheduleUnit: ScheduleUnit.day,
          lastExecutedAt: DateTime(2026, 4, 23),
        );
        final p = task.computeProgress(DateTime(2026, 4, 24, 14, 0)) as DueDate;
        expect(p.isToday, true);
        expect(p.daysRemaining, 0);
      });

      test('翌日が期日の14:00: 当日扱いにならない', () {
        final task = _scheduledTask(
          scheduleValue: 1,
          scheduleUnit: ScheduleUnit.day,
          lastExecutedAt: DateTime(2026, 4, 24),
        );
        final p = task.computeProgress(DateTime(2026, 4, 24, 14, 0)) as DueDate;
        expect(p.isToday, false);
        expect(p.daysRemaining, 1);
      });
    });

    group('実行時刻を含む場合でも進捗が正しく計算される', () {
      // 30日スケジュール, 1/1 14:00に実行 → 期日=1/31
      // 総日数は 30日のはず。1/16 00:00 時点で経過=15日 → progress≈0.5
      test('14:00実行でも進捗0.5が正しく算出される', () {
        final task = _scheduledTask(
          scheduleValue: 30,
          scheduleUnit: ScheduleUnit.day,
          lastExecutedAt: DateTime(2025, 1, 1, 14, 0),
        );
        final p = task.computeProgress(DateTime(2025, 1, 16)) as DueDate;
        expect(p.daysRemaining, 15); // 1/31 - 1/16 = 15日
        expect(p.progress, closeTo(0.5, 0.01));
      });
    });

    group('超過・当日の境界値', () {
      // 期日 = 1/31 (30日スケジュール, 実行日 1/1)
      TaskItem task30() => _scheduledTask(
        scheduleValue: 30,
        scheduleUnit: ScheduleUnit.day,
        lastExecutedAt: DateTime(2025, 1, 1),
      );

      test('期日の前日: 超過していない、残1日', () {
        final p = task30().computeProgress(DateTime(2025, 1, 30)) as DueDate;
        expect(p.isOverdue, false);
        expect(p.daysRemaining, 1);
        expect(p.isToday, false);
      });

      test('期日当日 00:00: 超過していない、当日扱い', () {
        final p =
            task30().computeProgress(DateTime(2025, 1, 31, 0, 0)) as DueDate;
        expect(p.isOverdue, false);
        expect(p.isToday, true);
      });

      test('期日当日 12:00: 超過していない、当日扱い', () {
        final p =
            task30().computeProgress(DateTime(2025, 1, 31, 12, 0)) as DueDate;
        expect(p.isOverdue, false);
        expect(p.isToday, true);
      });

      test('期日当日 23:59: 超過していない、当日扱い', () {
        final p =
            task30().computeProgress(DateTime(2025, 1, 31, 23, 59)) as DueDate;
        expect(p.isOverdue, false);
        expect(p.isToday, true);
      });

      test('期日の翌日: 超過している、残-1日', () {
        final p = task30().computeProgress(DateTime(2025, 2, 1)) as DueDate;
        expect(p.isOverdue, true);
        expect(p.daysRemaining, -1);
      });
    });
  });
}

TaskItem _periodTask({DateTime? lastExecutedAt, DateTime? scheduledAt}) =>
    TaskItem.period(
      id: '1',
      name: 'テスト',
      furigana: 'てすと',
      icon: '📝',
      color: TaskColor.none,
      lastExecutedAt: lastExecutedAt,
      cachedScheduledAt: scheduledAt,
    );

TaskItem _scheduledTask({
  required int scheduleValue,
  required ScheduleUnit scheduleUnit,
  DateTime? lastExecutedAt,
}) => TaskItem.scheduled(
  id: '1',
  name: 'テスト',
  furigana: 'てすと',
  icon: '📝',
  color: TaskColor.none,
  scheduleValue: scheduleValue,
  scheduleUnit: scheduleUnit,
  lastExecutedAt: lastExecutedAt,
);
