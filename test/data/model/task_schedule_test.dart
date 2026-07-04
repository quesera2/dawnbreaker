import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_schedule.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeLastExecutedAt', () {
    test('履歴が空のとき null を返す', () {
      expect(computeLastExecutedAt([]), isNull);
    });

    test('履歴があるとき最後の実行日を返す', () {
      final history = [
        TaskHistory(id: '1', executedAt: DateTime(2025, 1, 1), comment: null),
        TaskHistory(id: '2', executedAt: DateTime(2025, 2, 1), comment: null),
      ];
      expect(computeLastExecutedAt(history), DateTime(2025, 2, 1));
    });
  });

  group('computeScheduledAt', () {
    group('irregular タスク', () {
      test('常に null を返す', () {
        final history = [
          TaskHistory(id: '1', executedAt: DateTime(2025, 1, 1), comment: null),
        ];
        expect(
          computeScheduledAt(
            taskType: TaskType.irregular,
            ascendingHistory: history,
          ),
          isNull,
        );
      });
    });

    group('period タスク', () {
      test('履歴が0件のとき null を返す', () {
        expect(
          computeScheduledAt(taskType: TaskType.period, ascendingHistory: []),
          isNull,
        );
      });

      test('履歴が1件のとき null を返す', () {
        final history = [
          TaskHistory(id: '1', executedAt: DateTime(2025, 1, 1), comment: null),
        ];
        expect(
          computeScheduledAt(
            taskType: TaskType.period,
            ascendingHistory: history,
          ),
          isNull,
        );
      });

      test('履歴が2件のとき 間隔の平均だけ後の日付を返す', () {
        // 間隔: 31日 → 平均31日 → 2/1 + 31日 = 3/4
        final history = [
          TaskHistory(id: '1', executedAt: DateTime(2025, 1, 1), comment: null),
          TaskHistory(id: '2', executedAt: DateTime(2025, 2, 1), comment: null),
        ];
        expect(
          computeScheduledAt(
            taskType: TaskType.period,
            ascendingHistory: history,
          ),
          DateTime(2025, 3, 4),
        );
      });

      test('履歴が3件のとき 全間隔の平均を使う', () {
        // 間隔: 10日, 20日 → 平均15日 → 1/31 + 15日 = 2/15
        final history = [
          TaskHistory(id: '1', executedAt: DateTime(2025, 1, 1), comment: null),
          TaskHistory(
            id: '2',
            executedAt: DateTime(2025, 1, 11),
            comment: null,
          ),
          TaskHistory(
            id: '3',
            executedAt: DateTime(2025, 1, 31),
            comment: null,
          ),
        ];
        expect(
          computeScheduledAt(
            taskType: TaskType.period,
            ascendingHistory: history,
          ),
          DateTime(2025, 2, 15),
        );
      });
    });

    group('scheduled タスク', () {
      test('履歴が0件のとき null を返す', () {
        expect(
          computeScheduledAt(
            taskType: TaskType.scheduled,
            ascendingHistory: [],
            scheduleValue: 1,
            scheduleUnit: ScheduleUnit.month,
          ),
          isNull,
        );
      });

      test('ScheduleUnit.day: 最後の実行日 + n日', () {
        final history = [
          TaskHistory(id: '1', executedAt: DateTime(2025, 1, 1), comment: null),
        ];
        expect(
          computeScheduledAt(
            taskType: TaskType.scheduled,
            ascendingHistory: history,
            scheduleValue: 14,
            scheduleUnit: ScheduleUnit.day,
          ),
          DateTime(2025, 1, 15),
        );
      });

      test('ScheduleUnit.week: 最後の実行日 + n週', () {
        final history = [
          TaskHistory(id: '1', executedAt: DateTime(2025, 1, 1), comment: null),
        ];
        expect(
          computeScheduledAt(
            taskType: TaskType.scheduled,
            ascendingHistory: history,
            scheduleValue: 2,
            scheduleUnit: ScheduleUnit.week,
          ),
          DateTime(2025, 1, 15),
        );
      });

      test('ScheduleUnit.month: 最後の実行日 + nヶ月', () {
        final history = [
          TaskHistory(
            id: '1',
            executedAt: DateTime(2025, 1, 10),
            comment: null,
          ),
        ];
        expect(
          computeScheduledAt(
            taskType: TaskType.scheduled,
            ascendingHistory: history,
            scheduleValue: 3,
            scheduleUnit: ScheduleUnit.month,
          ),
          DateTime(2025, 4, 10),
        );
      });

      test('scheduleValue/scheduleUnit が欠損しているとき null を返す', () {
        final history = [
          TaskHistory(id: '1', executedAt: DateTime(2025, 1, 1), comment: null),
        ];
        expect(
          computeScheduledAt(
            taskType: TaskType.scheduled,
            ascendingHistory: history,
          ),
          isNull,
        );
      });
    });
  });
}
