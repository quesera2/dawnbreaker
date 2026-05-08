import 'dart:async';

import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:dawnbreaker/ui/app_detail/viewmodel/app_detail_ui_state.dart';
import 'package:dawnbreaker/ui/app_detail/viewmodel/app_detail_view_model.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_task_repository.dart';
import '../../../helpers/riverpod_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppDetailViewModel', () {
    late ProviderContainer container;
    late FakeTaskRepository fakeRepository;
    late AppDetailViewModelProvider provider;
    late AppDetailViewModel viewModel;
    late AppDetailUiState viewState;

    void setUpContainer({int? taskId}) {
      fakeRepository = FakeTaskRepository(initialTasks: _testTasks);
      container = ProviderContainer(
        overrides: [taskRepositoryProvider.overrideWith((_) => fakeRepository)],
      );
      provider = appDetailViewModelProvider(
        taskId: taskId ?? _taskOneHistory.id,
      );
    }

    Future<void> setUpLoaded({int? taskId}) async {
      final id = taskId ?? _taskOneHistory.id;
      setUpContainer(taskId: id);
      await waitUntil(container, provider, (s) => !s.isLoading);
      viewModel = container.read(provider.notifier);
      container.listen(
        provider,
        (_, next) => viewState = next,
        fireImmediately: true,
      );
    }

    Future<void> setUpLoadedWithThrow() async {
      setUpContainer();
      fakeRepository.shouldThrow = true;
      await waitUntil(container, provider, (s) => !s.isLoading);
      viewModel = container.read(provider.notifier);
      container.listen(
        provider,
        (_, next) => viewState = next,
        fireImmediately: true,
      );
    }

    tearDown(() {
      container.dispose();
      fakeRepository.dispose();
    });

    group('初期状態', () {
      setUp(setUpContainer);

      test('データ取得前はローディング中でタスクは表示されない', () {
        final state = container.read(provider);
        expect(state.isLoading, true);
        expect(state.task, isNull);
        expect(state.historyStats, isNull);
        expect(state.shouldPop, false);
      });
    });

    group('ロード後', () {
      group('履歴なしのタスク', () {
        setUp(() async {
          await setUpLoaded(taskId: _taskNoHistory.id);
        });

        test('タスクの内容が表示できる状態になる', () {
          expect(viewState.isLoading, false);
          expect(viewState.task, _taskNoHistory);
        });

        test('履歴がないため実行記録が含まれない', () {
          expect(viewState.historyStats, isNotNull);
          expect(viewState.historyStats!.historyAndInterval, isEmpty);
        });

        test('一度も実行されていないため経過日数は算出されない', () {
          expect(viewState.daysSinceLastExecution, isNull);
        });

        test('インターバル計算には2件以上の履歴が必要なため平均インターバルは算出されない', () {
          expect(viewState.averageIntervalDays, isNull);
        });
      });

      group('履歴1件のタスク', () {
        setUp(() async {
          await setUpLoaded();
        });

        test('タスクの内容が表示できる状態になる', () {
          expect(viewState.task, _taskOneHistory);
        });

        test('最終実行日からの経過日数が計算される', () {
          expect(viewState.daysSinceLastExecution, isNotNull);
        });

        test('インターバル計算には2件以上の履歴が必要なため平均インターバルは算出されない', () {
          expect(viewState.averageIntervalDays, isNull);
        });

        test('すべての履歴エントリが一覧に含まれる', () {
          expect(viewState.historyStats!.historyAndInterval, hasLength(1));
        });
      });

      group('複数履歴のタスク', () {
        setUp(() async {
          await setUpLoaded(taskId: _taskMultiHistory.id);
        });

        test('タスクの内容が表示できる状態になる', () {
          expect(viewState.task, _taskMultiHistory);
        });

        test('すべての履歴エントリが一覧に含まれる', () {
          expect(viewState.historyStats!.historyAndInterval, hasLength(3));
        });

        test('実行インターバルの平均が正しく計算される', () {
          expect(viewState.averageIntervalDays, 31);
        });

        test('最終実行日からの経過日数が計算される', () {
          expect(viewState.daysSinceLastExecution, isNotNull);
        });
      });

      group('タスクが外部で更新されたとき', () {
        setUp(() async {
          await setUpLoaded();
        });

        test('編集内容がリアルタイムで画面に反映される', () async {
          await fakeRepository.updateTask(
            taskId: _taskOneHistory.id,
            taskType: TaskType.period,
            name: '更新後の名前',
            icon: '✂️',
            color: TaskColor.green,
          );
          expect(viewState.task?.name, '更新後の名前');
          expect(viewState.task?.icon, '✂️');
          expect(viewState.task?.color, TaskColor.green);
        });

        test('タスク更新後も履歴情報が正しく表示される', () async {
          await fakeRepository.updateTask(
            taskId: _taskOneHistory.id,
            taskType: TaskType.period,
            name: '更新後の名前',
            icon: '📝',
            color: TaskColor.none,
          );
          expect(viewState.historyStats, isNotNull);
          expect(viewState.historyStats!.historyAndInterval, hasLength(1));
        });
      });

      group('タスクデータの取得中にエラーが発生したとき', () {
        setUp(() async {
          await setUpLoaded();
        });

        test('画面を閉じる状態になる', () async {
          fakeRepository.emitError(const TaskLoadException('stream error'));
          await Future.microtask(() {});
          expect(viewState.shouldPop, true);
        });

        test('ローディング状態が解除される', () async {
          fakeRepository.emitError(const TaskLoadException('stream error'));
          await Future.microtask(() {});
          expect(viewState.isLoading, false);
        });
      });

      group('updateExecution', () {
        group('正常系', () {
          setUp(() async {
            await setUpLoaded();
          });

          test('成功時はエラーなし', () async {
            await viewModel.updateExecution(
              _taskOneHistory.taskHistory.first,
              executedAt: DateTime(2026, 2, 1),
            );
            expect(viewState.dialogMessage, isNull);
          });

          test('コメントありで更新してもエラーなし', () async {
            await viewModel.updateExecution(
              _taskOneHistory.taskHistory.first,
              executedAt: DateTime(2026, 2, 1),
              comment: '更新コメント',
            );
            expect(viewState.dialogMessage, isNull);
          });

          test('成功時に更新完了の通知がセットされる', () async {
            await viewModel.updateExecution(
              _taskOneHistory.taskHistory.first,
              executedAt: DateTime(2026, 2, 1),
            );
            expect(
              viewState.snackBarMessage,
              isA<TaskExecutionUpdateSuccess>(),
            );
          });

          test('undo ハンドラを呼び出すと元の日時・コメントで再更新される', () async {
            await viewModel.updateExecution(
              _taskOneHistory.taskHistory.first,
              executedAt: DateTime(2026, 2, 1),
              comment: '変更後',
            );
            final handler = viewState.snackBarMessage?.handler;
            expect(handler, isNotNull);
            await handler!();
            expect(viewState.dialogMessage, isNull);
          });
        });

        group('異常系', () {
          setUp(() async {
            await setUpLoadedWithThrow();
          });

          test('失敗時に更新エラーの通知がセットされる', () async {
            await viewModel.updateExecution(
              _taskOneHistory.taskHistory.first,
              executedAt: DateTime(2026, 2, 1),
            );
            expect(viewState.dialogMessage, isA<TaskUpdateErrorMessage>());
          });

          test('失敗時に再試行できる', () async {
            await viewModel.updateExecution(
              _taskOneHistory.taskHistory.first,
              executedAt: DateTime(2026, 2, 1),
            );
            expect(viewState.dialogMessage?.handler, isNotNull);
          });
        });
      });

      group('recordExecution', () {
        group('正常系', () {
          setUp(() async {
            await setUpLoaded();
          });

          test('成功時はエラーなし', () async {
            await viewModel.recordExecution(
              _taskOneHistory,
              DateTime(2026, 4, 1),
              null,
            );
            expect(viewState.dialogMessage, isNull);
          });

          test('成功時に実行完了の通知がセットされる', () async {
            await viewModel.recordExecution(
              _taskOneHistory,
              DateTime(2026, 4, 1),
              null,
            );
            final msg = viewState.snackBarMessage;
            expect(msg, isA<TaskCompleteSuccess>());
            expect((msg as TaskCompleteSuccess).taskName, _taskOneHistory.name);
          });

          test('成功時の通知に undo ハンドラがある', () async {
            await viewModel.recordExecution(
              _taskOneHistory,
              DateTime(2026, 4, 1),
              null,
            );
            expect(viewState.snackBarMessage?.handler, isNotNull);
          });

          test('undo ハンドラを呼び出してもエラーが発生しない', () async {
            await viewModel.recordExecution(
              _taskOneHistory,
              DateTime(2026, 4, 1),
              null,
            );
            final handler = viewState.snackBarMessage?.handler;
            expect(handler, isNotNull);
            await handler!();
            expect(viewState.dialogMessage, isNull);
          });

          for (final (comment, expectedComment, description) in [
            (null, null, 'コメントなし'),
            ('良い感じ', '良い感じ', 'コメントあり'),
          ]) {
            test('$descriptionで記録するとリポジトリにコメントが渡される', () async {
              await viewModel.recordExecution(
                _taskOneHistory,
                DateTime(2026, 4, 1),
                comment,
              );
              expect(fakeRepository.lastRecordedComment, expectedComment);
              expect(viewState.snackBarMessage, isA<TaskCompleteSuccess>());
            });
          }
        });

        group('異常系', () {
          setUp(() async {
            await setUpLoadedWithThrow();
          });

          test('リポジトリがエラーを返すと dialogMessage がセットされる', () async {
            await viewModel.recordExecution(
              _taskOneHistory,
              DateTime(2026, 4, 1),
              null,
            );
            expect(viewState.dialogMessage, isA<TaskSaveErrorMessage>());
          });

          test('失敗時に再試行できる', () async {
            await viewModel.recordExecution(
              _taskOneHistory,
              DateTime(2026, 4, 1),
              null,
            );
            expect(viewState.dialogMessage?.handler, isNotNull);
          });
        });
      });

      group('showDeleteTaskDialog', () {
        setUp(() async {
          await setUpLoaded();
        });

        test('確認ダイアログが表示される', () {
          viewModel.showDeleteTaskDialog();
          expect(viewState.dialogMessage, isA<DeleteTaskConfirmMessage>());
        });

        test('ダイアログにタスク名が表示される', () {
          viewModel.showDeleteTaskDialog();
          final msg = viewState.dialogMessage as DeleteTaskConfirmMessage?;
          expect(msg?.taskName, _taskOneHistory.name);
        });

        test('ダイアログのハンドラを呼び出すとタスクが削除される', () async {
          viewModel.showDeleteTaskDialog();
          final handler = viewState.dialogMessage?.handler;
          expect(handler, isNotNull);
          handler!();
          await Future.microtask(() {});
          expect(fakeRepository.containsTask(_taskOneHistory.id), false);
        });
      });

      group('deleteTask', () {
        group('正常系', () {
          setUp(() async {
            await setUpLoaded();
          });

          test('前の画面に戻る', () async {
            await viewModel.deleteTask();
            expect(viewState.shouldPop, true);
          });

          test('削除成功の通知がタスク名付きで表示される', () async {
            await viewModel.deleteTask();
            final msg = viewState.snackBarMessage;
            expect(msg, isA<TaskDeleteSuccess>());
            expect((msg as TaskDeleteSuccess).taskName, _taskOneHistory.name);
          });

          test('削除を取り消せる', () async {
            await viewModel.deleteTask();
            expect(viewState.snackBarMessage?.handler, isNotNull);
          });

          // 削除によりストリームが null を流すため clearTaskItem が呼ばれる
          test('タスクデータがクリアされる', () async {
            await viewModel.deleteTask();
            expect(viewState.task, isNull);
          });

          test('undo ハンドラを呼び出すとタスクが復元される', () async {
            await viewModel.deleteTask();
            expect(fakeRepository.containsTask(_taskOneHistory.id), false);
            final handler = viewState.snackBarMessage?.handler;
            await handler!();
            expect(fakeRepository.containsTask(_taskOneHistory.id), true);
          });
        });

        group('異常系', () {
          setUp(() async {
            await setUpLoadedWithThrow();
          });

          test('削除失敗のエラーが通知される', () async {
            await viewModel.deleteTask();
            expect(viewState.dialogMessage, isA<TaskDeleteErrorMessage>());
          });

          test('削除を再試行できる', () async {
            await viewModel.deleteTask();
            expect(viewState.dialogMessage?.handler, isNotNull);
          });
        });
      });

      group('deleteExecution', () {
        group('正常系', () {
          setUp(() async {
            await setUpLoaded();
          });

          test('成功時はエラーなし', () async {
            await viewModel.deleteExecution(
              _taskOneHistory,
              _taskOneHistory.taskHistory.first,
            );
            expect(viewState.dialogMessage, isNull);
          });

          test('成功時に削除完了の通知がセットされる', () async {
            await viewModel.deleteExecution(
              _taskOneHistory,
              _taskOneHistory.taskHistory.first,
            );
            expect(
              viewState.snackBarMessage,
              isA<TaskExecutionDeleteSuccess>(),
            );
          });

          test('成功時の通知に undo ハンドラがある', () async {
            await viewModel.deleteExecution(
              _taskOneHistory,
              _taskOneHistory.taskHistory.first,
            );
            expect(viewState.snackBarMessage?.handler, isNotNull);
          });

          test('undo ハンドラを呼び出してもエラーが発生しない', () async {
            await viewModel.deleteExecution(
              _taskOneHistory,
              _taskOneHistory.taskHistory.first,
            );
            final handler = viewState.snackBarMessage?.handler;
            expect(handler, isNotNull);
            await handler!();
            expect(viewState.dialogMessage, isNull);
          });

          for (final (comment, expectedComment, description) in [
            (null, null, 'コメントなし'),
            ('メモあり', 'メモあり', 'コメントあり'),
          ]) {
            test('$descriptionの履歴を削除後 undo で元のコメントが再作成される', () async {
              final history = TaskHistory(
                id: 1,
                executedAt: DateTime(2026, 1, 1),
                comment: comment,
              );
              await viewModel.deleteExecution(_taskOneHistory, history);
              final handler = viewState.snackBarMessage?.handler;
              await handler!();
              expect(fakeRepository.lastRecordedComment, expectedComment);
            });
          }
        });

        group('異常系', () {
          setUp(() async {
            await setUpLoadedWithThrow();
          });

          test('失敗時に削除エラーの通知がセットされる', () async {
            await viewModel.deleteExecution(
              _taskOneHistory,
              _taskOneHistory.taskHistory.first,
            );
            expect(
              viewState.dialogMessage,
              isA<TaskExecutionDeleteErrorMessage>(),
            );
          });

          test('失敗時に再試行できる', () async {
            await viewModel.deleteExecution(
              _taskOneHistory,
              _taskOneHistory.taskHistory.first,
            );
            expect(viewState.dialogMessage?.handler, isNotNull);
          });

          test('リトライハンドラを呼び出すと再度削除が試みられ成功する', () async {
            await viewModel.deleteExecution(
              _taskOneHistory,
              _taskOneHistory.taskHistory.first,
            );
            final handler = viewState.dialogMessage?.handler;
            expect(handler, isNotNull);

            fakeRepository.shouldThrow = false;
            handler!();
            await Future.microtask(() {});

            expect(
              viewState.snackBarMessage,
              isA<TaskExecutionDeleteSuccess>(),
            );
          });
        });
      });
    });
  });
}

// Jan 1, Feb 1 (31 days), Mar 4 (31 days) → averageIntervalDays = 31
const _taskNoHistory = TaskItem.period(
  id: 1,
  name: 'タスク（履歴なし）',
  furigana: 'たすく',
  icon: '📝',
  color: TaskColor.none,
  taskHistory: [],
);

final _taskOneHistory = TaskItem.period(
  id: 2,
  name: 'タスク（履歴1件）',
  furigana: 'たすく',
  icon: '📝',
  color: TaskColor.blue,
  taskHistory: [
    TaskHistory(id: 1, executedAt: DateTime(2026, 1, 1), comment: null),
  ],
);

final _taskMultiHistory = TaskItem.period(
  id: 3,
  name: 'タスク（複数履歴）',
  furigana: 'たすく',
  icon: '📝',
  color: TaskColor.green,
  taskHistory: [
    TaskHistory(id: 1, executedAt: DateTime(2026, 1, 1), comment: null),
    TaskHistory(id: 2, executedAt: DateTime(2026, 2, 1), comment: null),
    TaskHistory(id: 3, executedAt: DateTime(2026, 3, 4), comment: null),
  ],
);

final _testTasks = [_taskNoHistory, _taskOneHistory, _taskMultiHistory];
