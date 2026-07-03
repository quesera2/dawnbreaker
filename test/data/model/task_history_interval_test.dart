import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_history_interval.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('intervalDaysForHistory', () {
    test('履歴が1件のとき空リストを返す', () {
      final history = [
        TaskHistory(id: '1', executedAt: DateTime(2025, 1, 1), comment: null),
      ];
      expect(intervalDaysForHistory(history), isEmpty);
    });

    test('深夜0時の履歴: 1/1→2/1 は31日', () {
      final history = [
        TaskHistory(id: '1', executedAt: DateTime(2025, 1, 1), comment: null),
        TaskHistory(id: '2', executedAt: DateTime(2025, 2, 1), comment: null),
      ];
      expect(intervalDaysForHistory(history), [31]);
    });

    test('夜遅い実行→翌朝実行でも1日としてカウントされる（22:00→翌08:00）', () {
      final history = [
        TaskHistory(
          id: '1',
          executedAt: DateTime(2025, 1, 1, 22, 0),
          comment: null,
        ),
        TaskHistory(
          id: '2',
          executedAt: DateTime(2025, 1, 2, 8, 0),
          comment: null,
        ),
      ];
      expect(intervalDaysForHistory(history), [1]);
    });

    test('実行時刻が異なっても複数インターバルが正しく計算される', () {
      // 1/1 14:00 → 2/1 08:00 → 3/4 22:00
      // カレンダー日数: 31日, 31日
      final history = [
        TaskHistory(
          id: '1',
          executedAt: DateTime(2025, 1, 1, 14, 0),
          comment: null,
        ),
        TaskHistory(
          id: '2',
          executedAt: DateTime(2025, 2, 1, 8, 0),
          comment: null,
        ),
        TaskHistory(
          id: '3',
          executedAt: DateTime(2025, 3, 4, 22, 0),
          comment: null,
        ),
      ];
      expect(intervalDaysForHistory(history), [31, 31]);
    });
  });
}
