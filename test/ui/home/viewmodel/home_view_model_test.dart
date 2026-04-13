import 'dart:async';

import 'package:dawnbreaker/data/dummy/dummy_tasks.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeViewModel', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });
    tearDown(() async {
      await _waitUntilLoaded(container);
      container.dispose();
    });

    group('初期状態', () {
      test('isLoading: true でタスクが空', () {
        final state = container.read(homeViewModelProvider);
        expect(state.isLoading, true);
        expect(state.tasks, isEmpty);
        expect(state.searchQuery, '');
      });

      test('hasTasks は false', () {
        expect(container.read(homeViewModelProvider).hasTasks, false);
      });
    });

    group('ロード後', () {
      setUp(() async {
        await _waitUntilLoaded(container);
      });

      test('isLoading: false になりダミータスクが読み込まれる', () {
        final state = container.read(homeViewModelProvider);
        expect(state.isLoading, false);
        expect(state.tasks, dummyTasks);
      });

      test('hasTasks は true', () {
        expect(container.read(homeViewModelProvider).hasTasks, true);
      });

      test('searchQuery が空のとき filteredTasks は全タスクを返す', () {
        final state = container.read(homeViewModelProvider);
        expect(state.filteredTasks, dummyTasks);
      });

      test('updateSearchQuery で filteredTasks が絞り込まれる', () {
        container.read(homeViewModelProvider.notifier).updateSearchQuery('歯');
        final state = container.read(homeViewModelProvider);
        expect(state.filteredTasks.isNotEmpty, true);
        expect(state.filteredTasks.every((t) => t.name.contains('歯')), true);
      });

      test('一致しない searchQuery のとき filteredTasks は空', () {
        container.read(homeViewModelProvider.notifier).updateSearchQuery('zzz');
        expect(container.read(homeViewModelProvider).filteredTasks, isEmpty);
      });

      test('updateSearchQuery で searchQuery が更新される', () {
        container.read(homeViewModelProvider.notifier).updateSearchQuery('歯');
        expect(container.read(homeViewModelProvider).searchQuery, '歯');
      });

      test('updateSearchQuery に同じ値を渡してもステートが変わらない', () {
        container.read(homeViewModelProvider.notifier).updateSearchQuery('歯');
        final stateBefore = container.read(homeViewModelProvider);

        container.read(homeViewModelProvider.notifier).updateSearchQuery('歯');
        final stateAfter = container.read(homeViewModelProvider);

        expect(identical(stateBefore, stateAfter), true);
      });
    });
  });
}

/// isLoading が false になるまで待機するヘルパー
Future<void> _waitUntilLoaded(ProviderContainer container) async {
  final completer = Completer<void>();
  final sub = container.listen(homeViewModelProvider, (_, next) {
    if (!next.isLoading && !completer.isCompleted) completer.complete();
  }, fireImmediately: true);
  await completer.future;
  sub.close();
}
