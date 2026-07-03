import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/app_detail/viewmodel/app_detail_ui_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDetailUiState.mergedAscendingHistory', () {
    test('task が null のとき空リストを返す', () {
      const state = AppDetailUiState();
      expect(state.mergedAscendingHistory, isEmpty);
    });

    test('olderHistory が空のとき recentHistory がそのまま返る', () {
      final state = AppDetailUiState(
        task: _task,
        recentHistory: [
          TaskHistory(
            id: 'h-1',
            executedAt: DateTime(2025, 1, 1),
            comment: null,
          ),
          TaskHistory(
            id: 'h-2',
            executedAt: DateTime(2025, 1, 3),
            comment: null,
          ),
        ],
      );

      expect(state.mergedAscendingHistory.map((h) => h.id), ['h-1', 'h-2']);
    });

    test('olderHistory と recentHistory を日付順にマージする', () {
      final state = AppDetailUiState(
        task: _task,
        recentHistory: [
          TaskHistory(
            id: 'h-3',
            executedAt: DateTime(2025, 1, 10),
            comment: null,
          ),
          TaskHistory(
            id: 'h-4',
            executedAt: DateTime(2025, 1, 12),
            comment: null,
          ),
        ],
        olderHistory: [
          TaskHistory(
            id: 'h-1',
            executedAt: DateTime(2025, 1, 1),
            comment: null,
          ),
          TaskHistory(
            id: 'h-2',
            executedAt: DateTime(2025, 1, 5),
            comment: null,
          ),
        ],
      );

      expect(state.mergedAscendingHistory.map((h) => h.id), [
        'h-1',
        'h-2',
        'h-3',
        'h-4',
      ]);
    });

    test('olderHistory の日付が recentHistory の範囲に食い込んでも正しい順序になる', () {
      // updateExecution で olderHistory 側の項目の日付が head の範囲に
      // 入り込んだ場合を想定（境界をまたぐケース）
      final state = AppDetailUiState(
        task: _task,
        recentHistory: [
          TaskHistory(
            id: 'h-2',
            executedAt: DateTime(2025, 1, 5),
            comment: null,
          ),
          TaskHistory(
            id: 'h-3',
            executedAt: DateTime(2025, 1, 10),
            comment: null,
          ),
        ],
        olderHistory: [
          // 編集により日付が 1/8 になったが、配列としては olderHistory に残っている
          TaskHistory(
            id: 'h-1',
            executedAt: DateTime(2025, 1, 8),
            comment: null,
          ),
        ],
      );

      expect(state.mergedAscendingHistory.map((h) => h.id), [
        'h-2',
        'h-1',
        'h-3',
      ]);
    });

    test('同じ id が両方に存在する場合は重複排除され1件になる', () {
      final state = AppDetailUiState(
        task: _task,
        recentHistory: [
          TaskHistory(
            id: 'h-1',
            executedAt: DateTime(2025, 1, 1),
            comment: '最新の内容',
          ),
        ],
        olderHistory: [
          TaskHistory(
            id: 'h-1',
            executedAt: DateTime(2025, 1, 1),
            comment: null,
          ),
        ],
      );

      expect(state.mergedAscendingHistory, hasLength(1));
      expect(state.mergedAscendingHistory.first.comment, '最新の内容');
    });
  });

  group('AppDetailUiState.displayedHistoryAndInterval', () {
    test('新しい順に並び、連続する項目の間隔が計算される', () {
      final state = AppDetailUiState(
        task: _task,
        recentHistory: [
          TaskHistory(
            id: 'h-1',
            executedAt: DateTime(2025, 1, 1),
            comment: null,
          ),
          TaskHistory(
            id: 'h-2',
            executedAt: DateTime(2025, 1, 8),
            comment: null,
          ),
        ],
      );

      final result = state.displayedHistoryAndInterval;
      expect(result.map((e) => e.$1.id), ['h-2', 'h-1']);
      expect(result[0].$2, 7);
      expect(result[1].$2, isNull);
    });
  });
}

const _task = TaskItem.period(
  id: 'task-1',
  name: 'タスク',
  furigana: 'たすく',
  icon: '📝',
  color: TaskColor.none,
  lastExecutedAt: null,
  cachedScheduledAt: null,
);
