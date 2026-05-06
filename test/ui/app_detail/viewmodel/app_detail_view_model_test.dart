import 'dart:async';

import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:dawnbreaker/ui/app_detail/viewmodel/app_detail_view_model.dart';
import 'package:dawnbreaker/ui/common/dialog_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_task_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppDetailViewModel', () {
    late ProviderContainer container;
    late FakeTaskRepository fakeRepository;

    void setUpContainer() {
      fakeRepository = FakeTaskRepository(initialTasks: _testTasks);
      container = ProviderContainer(
        overrides: [taskRepositoryProvider.overrideWith((_) => fakeRepository)],
      );
    }

    tearDown(() {
      container.dispose();
      fakeRepository.dispose();
    });

    group('初期状態', () {
      setUp(setUpContainer);

      test('データ取得前はローディング中でタスクは表示されない', () {
        final state = container.read(
          appDetailViewModelProvider(taskId: _taskOneHistory.id),
        );
        expect(state.isLoading, true);
        expect(state.task, isNull);
        expect(state.historyStats, isNull);
        expect(state.shouldPop, false);
      });
    });

    group('ロード後', () {
      group('履歴なしのタスク', () {
        setUp(() async {
          setUpContainer();
          await _waitUntilLoaded(container, taskId: _taskNoHistory.id);
        });

        test('タスクの内容が表示できる状態になる', () {
          final state = container.read(
            appDetailViewModelProvider(taskId: _taskNoHistory.id),
          );
          expect(state.isLoading, false);
          expect(state.task, _taskNoHistory);
        });

        test('履歴がないため実行記録が含まれない', () {
          final stats = container
              .read(appDetailViewModelProvider(taskId: _taskNoHistory.id))
              .historyStats;
          expect(stats, isNotNull);
          expect(stats!.historyAndInterval, isEmpty);
        });

        test('一度も実行されていないため経過日数は算出されない', () {
          expect(
            container
                .read(appDetailViewModelProvider(taskId: _taskNoHistory.id))
                .daysSinceLastExecution,
            isNull,
          );
        });

        test('インターバル計算には2件以上の履歴が必要なため平均インターバルは算出されない', () {
          expect(
            container
                .read(appDetailViewModelProvider(taskId: _taskNoHistory.id))
                .averageIntervalDays,
            isNull,
          );
        });
      });

      group('履歴1件のタスク', () {
        setUp(() async {
          setUpContainer();
          await _waitUntilLoaded(container, taskId: _taskOneHistory.id);
        });

        test('タスクの内容が表示できる状態になる', () {
          expect(
            container
                .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                .task,
            _taskOneHistory,
          );
        });

        test('最終実行日からの経過日数が計算される', () {
          expect(
            container
                .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                .daysSinceLastExecution,
            isNotNull,
          );
        });

        test('インターバル計算には2件以上の履歴が必要なため平均インターバルは算出されない', () {
          expect(
            container
                .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                .averageIntervalDays,
            isNull,
          );
        });

        test('すべての履歴エントリが一覧に含まれる', () {
          final stats = container
              .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
              .historyStats;
          expect(stats!.historyAndInterval, hasLength(1));
        });
      });

      group('複数履歴のタスク', () {
        setUp(() async {
          setUpContainer();
          await _waitUntilLoaded(container, taskId: _taskMultiHistory.id);
        });

        test('タスクの内容が表示できる状態になる', () {
          expect(
            container
                .read(appDetailViewModelProvider(taskId: _taskMultiHistory.id))
                .task,
            _taskMultiHistory,
          );
        });

        test('すべての履歴エントリが一覧に含まれる', () {
          final stats = container
              .read(appDetailViewModelProvider(taskId: _taskMultiHistory.id))
              .historyStats;
          expect(stats!.historyAndInterval, hasLength(3));
        });

        test('実行インターバルの平均が正しく計算される', () {
          expect(
            container
                .read(appDetailViewModelProvider(taskId: _taskMultiHistory.id))
                .averageIntervalDays,
            31,
          );
        });

        test('最終実行日からの経過日数が計算される', () {
          expect(
            container
                .read(appDetailViewModelProvider(taskId: _taskMultiHistory.id))
                .daysSinceLastExecution,
            isNotNull,
          );
        });
      });

      group('タスクが外部で更新されたとき', () {
        setUp(() async {
          setUpContainer();
          await _waitUntilLoaded(container, taskId: _taskOneHistory.id);
        });

        test('編集内容がリアルタイムで画面に反映される', () async {
          await fakeRepository.updateTask(
            taskId: _taskOneHistory.id,
            taskType: TaskType.period,
            name: '更新後の名前',
            icon: '✂️',
            color: TaskColor.green,
          );
          final state = container.read(
            appDetailViewModelProvider(taskId: _taskOneHistory.id),
          );
          expect(state.task?.name, '更新後の名前');
          expect(state.task?.icon, '✂️');
          expect(state.task?.color, TaskColor.green);
        });

        test('タスク更新後も履歴情報が正しく表示される', () async {
          await fakeRepository.updateTask(
            taskId: _taskOneHistory.id,
            taskType: TaskType.period,
            name: '更新後の名前',
            icon: '📝',
            color: TaskColor.none,
          );
          final stats = container
              .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
              .historyStats;
          expect(stats, isNotNull);
          expect(stats!.historyAndInterval, hasLength(1));
        });
      });

      group('タスクデータの取得中にエラーが発生したとき', () {
        setUp(() async {
          setUpContainer();
          await _waitUntilLoaded(container, taskId: _taskOneHistory.id);
        });

        test('画面を閉じる状態になる', () async {
          fakeRepository.emitError(const TaskLoadException('stream error'));
          await Future.microtask(() {});
          expect(
            container
                .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                .shouldPop,
            true,
          );
        });

        test('ローディング状態が解除される', () async {
          fakeRepository.emitError(const TaskLoadException('stream error'));
          await Future.microtask(() {});
          expect(
            container
                .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                .isLoading,
            false,
          );
        });
      });

      group('updateExecution', () {
        group('正常系', () {
          setUp(() async {
            setUpContainer();
            await _waitUntilLoaded(container, taskId: _taskOneHistory.id);
          });

          test('成功時はエラーなし', () async {
            await container
                .read(
                  appDetailViewModelProvider(
                    taskId: _taskOneHistory.id,
                  ).notifier,
                )
                .updateExecution(
                  _taskOneHistory.taskHistory.first,
                  executedAt: DateTime(2026, 2, 1),
                );
            expect(
              container
                  .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                  .dialogMessage,
              isNull,
            );
          });

          test('コメントありで更新してもエラーなし', () async {
            await container
                .read(
                  appDetailViewModelProvider(
                    taskId: _taskOneHistory.id,
                  ).notifier,
                )
                .updateExecution(
                  _taskOneHistory.taskHistory.first,
                  executedAt: DateTime(2026, 2, 1),
                  comment: '更新コメント',
                );
            expect(
              container
                  .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                  .dialogMessage,
              isNull,
            );
          });

          test('成功時に更新完了の通知がセットされる', () async {
            await container
                .read(
                  appDetailViewModelProvider(
                    taskId: _taskOneHistory.id,
                  ).notifier,
                )
                .updateExecution(
                  _taskOneHistory.taskHistory.first,
                  executedAt: DateTime(2026, 2, 1),
                );
            expect(
              container
                  .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                  .snackBarMessage,
              isA<TaskExecutionUpdateSuccess>(),
            );
          });

          test('undo ハンドラを呼び出すと元の日時・コメントで再更新される', () async {
            final original = _taskOneHistory.taskHistory.first;
            await container
                .read(
                  appDetailViewModelProvider(
                    taskId: _taskOneHistory.id,
                  ).notifier,
                )
                .updateExecution(
                  original,
                  executedAt: DateTime(2026, 2, 1),
                  comment: '変更後',
                );

            final handler = container
                .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                .snackBarMessage
                ?.handler;
            expect(handler, isNotNull);
            await handler!();

            expect(
              container
                  .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                  .dialogMessage,
              isNull,
            );
          });
        });

        group('異常系', () {
          setUp(() async {
            fakeRepository = FakeTaskRepository(
              initialTasks: _testTasks,
              shouldThrow: true,
            );
            container = ProviderContainer(
              overrides: [
                taskRepositoryProvider.overrideWith((_) => fakeRepository),
              ],
            );
            await _waitUntilLoaded(container, taskId: _taskOneHistory.id);
          });

          test('失敗時に更新エラーの通知がセットされる', () async {
            await container
                .read(
                  appDetailViewModelProvider(
                    taskId: _taskOneHistory.id,
                  ).notifier,
                )
                .updateExecution(
                  _taskOneHistory.taskHistory.first,
                  executedAt: DateTime(2026, 2, 1),
                );
            expect(
              container
                  .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                  .dialogMessage,
              isA<TaskUpdateErrorMessage>(),
            );
          });

          test('失敗時に再試行できる', () async {
            await container
                .read(
                  appDetailViewModelProvider(
                    taskId: _taskOneHistory.id,
                  ).notifier,
                )
                .updateExecution(
                  _taskOneHistory.taskHistory.first,
                  executedAt: DateTime(2026, 2, 1),
                );
            expect(
              container
                  .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                  .dialogMessage
                  ?.handler,
              isNotNull,
            );
          });
        });
      });

      group('showDeleteTaskDialog', () {
        setUp(() async {
          setUpContainer();
          await _waitUntilLoaded(container, taskId: _taskOneHistory.id);
        });

        test('確認ダイアログが表示される', () {
          container
              .read(
                appDetailViewModelProvider(taskId: _taskOneHistory.id).notifier,
              )
              .showDeleteTaskDialog();
          expect(
            container
                .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                .dialogMessage,
            isA<DeleteTaskConfirmMessage>(),
          );
        });

        test('ダイアログにタスク名が表示される', () {
          container
              .read(
                appDetailViewModelProvider(taskId: _taskOneHistory.id).notifier,
              )
              .showDeleteTaskDialog();
          final msg =
              container
                      .read(
                        appDetailViewModelProvider(taskId: _taskOneHistory.id),
                      )
                      .dialogMessage
                  as DeleteTaskConfirmMessage?;
          expect(msg?.taskName, _taskOneHistory.name);
        });

        test('ダイアログのハンドラを呼び出すとタスクが削除される', () async {
          container
              .read(
                appDetailViewModelProvider(taskId: _taskOneHistory.id).notifier,
              )
              .showDeleteTaskDialog();
          final handler = container
              .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
              .dialogMessage
              ?.handler;
          expect(handler, isNotNull);
          handler!();
          await Future.microtask(() {});
          expect(fakeRepository.containsTask(_taskOneHistory.id), false);
        });
      });

      group('deleteTask', () {
        group('正常系', () {
          setUp(() async {
            setUpContainer();
            await _waitUntilLoaded(container, taskId: _taskOneHistory.id);
          });

          test('前の画面に戻る', () async {
            await container
                .read(
                  appDetailViewModelProvider(
                    taskId: _taskOneHistory.id,
                  ).notifier,
                )
                .deleteTask();
            expect(
              container
                  .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                  .shouldPop,
              true,
            );
          });

          test('削除成功の通知がタスク名付きで表示される', () async {
            await container
                .read(
                  appDetailViewModelProvider(
                    taskId: _taskOneHistory.id,
                  ).notifier,
                )
                .deleteTask();
            final msg = container
                .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                .snackBarMessage;
            expect(msg, isA<TaskDeleteSuccess>());
            expect((msg as TaskDeleteSuccess).taskName, _taskOneHistory.name);
          });

          test('削除を取り消せる', () async {
            await container
                .read(
                  appDetailViewModelProvider(
                    taskId: _taskOneHistory.id,
                  ).notifier,
                )
                .deleteTask();
            expect(
              container
                  .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                  .snackBarMessage
                  ?.handler,
              isNotNull,
            );
          });

          // 削除によりストリームが null を流すため clearTaskItem が呼ばれる
          test('タスクデータがクリアされる', () async {
            await container
                .read(
                  appDetailViewModelProvider(
                    taskId: _taskOneHistory.id,
                  ).notifier,
                )
                .deleteTask();
            expect(
              container
                  .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                  .task,
              isNull,
            );
          });

          test('undo ハンドラを呼び出すとタスクが復元される', () async {
            await container
                .read(
                  appDetailViewModelProvider(
                    taskId: _taskOneHistory.id,
                  ).notifier,
                )
                .deleteTask();

            expect(fakeRepository.containsTask(_taskOneHistory.id), false);

            final handler = container
                .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                .snackBarMessage
                ?.handler;
            await handler!();

            expect(fakeRepository.containsTask(_taskOneHistory.id), true);
          });
        });

        group('異常系', () {
          setUp(() async {
            fakeRepository = FakeTaskRepository(
              initialTasks: _testTasks,
              shouldThrow: true,
            );
            container = ProviderContainer(
              overrides: [
                taskRepositoryProvider.overrideWith((_) => fakeRepository),
              ],
            );
            await _waitUntilLoaded(container, taskId: _taskOneHistory.id);
          });

          test('削除失敗のエラーが通知される', () async {
            await container
                .read(
                  appDetailViewModelProvider(
                    taskId: _taskOneHistory.id,
                  ).notifier,
                )
                .deleteTask();
            expect(
              container
                  .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                  .dialogMessage,
              isA<TaskDeleteErrorMessage>(),
            );
          });

          test('削除を再試行できる', () async {
            await container
                .read(
                  appDetailViewModelProvider(
                    taskId: _taskOneHistory.id,
                  ).notifier,
                )
                .deleteTask();
            expect(
              container
                  .read(appDetailViewModelProvider(taskId: _taskOneHistory.id))
                  .dialogMessage
                  ?.handler,
              isNotNull,
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

Future<void> _waitUntilLoaded(
  ProviderContainer container, {
  required int taskId,
}) async {
  final completer = Completer<void>();
  final sub = container.listen(appDetailViewModelProvider(taskId: taskId), (
    _,
    next,
  ) {
    if (!next.isLoading && !completer.isCompleted) completer.complete();
  }, fireImmediately: true);
  await completer.future;
  sub.close();
}
