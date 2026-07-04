import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/ui/app_detail/viewmodel/app_detail_ui_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDetailUiState.updateHistory', () {
    test('historyStats と averageIntervalDays が再計算される', () {
      final state = const AppDetailUiState().updateHistory([
        TaskHistory(id: 'h-1', executedAt: DateTime(2025, 1, 1), comment: null),
        TaskHistory(id: 'h-2', executedAt: DateTime(2025, 2, 1), comment: null),
      ]);

      expect(state.history, hasLength(2));
      expect(state.historyStats?.historyAndInterval, hasLength(2));
      expect(state.averageIntervalDays, 31);
    });

    test('履歴が1件のとき averageIntervalDays は null', () {
      final state = const AppDetailUiState().updateHistory([
        TaskHistory(id: 'h-1', executedAt: DateTime(2025, 1, 1), comment: null),
      ]);

      expect(state.averageIntervalDays, isNull);
    });
  });

  group('AppDetailUiState.displayedHistoryAndInterval', () {
    test('history が空のとき空リストを返す', () {
      const state = AppDetailUiState();
      expect(state.displayedHistoryAndInterval, isEmpty);
    });

    test('新しい順に並び、連続する項目の間隔が計算される', () {
      final state = const AppDetailUiState().updateHistory([
        TaskHistory(id: 'h-1', executedAt: DateTime(2025, 1, 1), comment: null),
        TaskHistory(id: 'h-2', executedAt: DateTime(2025, 1, 8), comment: null),
      ]);

      final result = state.displayedHistoryAndInterval;
      expect(result.map((e) => e.$1.id), ['h-2', 'h-1']);
      expect(result[0].$2, 7);
      expect(result[1].$2, isNull);
    });
  });
}
