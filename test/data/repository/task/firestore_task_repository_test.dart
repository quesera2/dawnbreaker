import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/data/repository/task/firestore_task_repository_impl.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_furigana_translate.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late TaskRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreTaskRepositoryImpl(
      userId: 'test-user',
      furiganaTranslate: const FakeFuriganaTranslate({
        '散髪': 'さんぱつ',
        '歯ブラシ交換': 'はぶらしこうかん',
        '虫避け交換': 'むしよけこうかん',
        '散髪(更新)': 'さんぱつこうしん',
      }),
      firestore: firestore,
    );
  });

  // lastExecutedAt/nextScheduledAt は Cloud Functions が executions への書き込みを
  // トリガーに再計算してキャッシュするフィールドのため、fake_cloud_firestore では
  // トリガーが発火しない。Cloud Functions が計算済みの状態を模してテスト用に直接書き込む
  Future<void> setScheduleCache(
    String taskId, {
    DateTime? lastExecutedAt,
    DateTime? nextScheduledAt,
  }) => firestore
      .collection('users')
      .doc('test-user')
      .collection('taskDefinitions')
      .doc(taskId)
      .update({
        'lastExecutedAt': lastExecutedAt != null
            ? Timestamp.fromDate(lastExecutedAt)
            : null,
        'nextScheduledAt': nextScheduledAt != null
            ? Timestamp.fromDate(nextScheduledAt)
            : null,
      });

  group('allTaskItems', () {
    group('ソート順', () {
      group('次回予定日が異なる場合', () {
        setUp(() async {
          final idB = await repository.addTask(
            taskType: TaskType.scheduled,
            name: 'タスクB',
            icon: '📝',
            color: TaskColor.none,
            scheduleValue: 7,
            scheduleUnit: ScheduleUnit.day,
          );
          await repository.recordExecution(
            idB,
            executedAt: DateTime(2025, 1, 15),
          );
          await setScheduleCache(idB, lastExecutedAt: DateTime(2025, 1, 15));
          // scheduledAt = 1/22

          final idA = await repository.addTask(
            taskType: TaskType.scheduled,
            name: 'タスクA',
            icon: '📝',
            color: TaskColor.none,
            scheduleValue: 7,
            scheduleUnit: ScheduleUnit.day,
          );
          await repository.recordExecution(
            idA,
            executedAt: DateTime(2025, 1, 1),
          );
          await setScheduleCache(idA, lastExecutedAt: DateTime(2025, 1, 1));
          // scheduledAt = 1/8
        });

        test('次回予定日が早いタスクが先に来る', () async {
          final tasks = await repository.allTaskItems().first;
          expect(tasks[0].name, 'タスクA');
          expect(tasks[1].name, 'タスクB');
        });
      });

      group('次回予定日がないタスクが混在する場合', () {
        setUp(() async {
          await repository.addTask(
            taskType: TaskType.period,
            name: '不定期タスク',
            icon: '📝',
            color: TaskColor.none,
          );
          final idS = await repository.addTask(
            taskType: TaskType.scheduled,
            name: '定期タスク',
            icon: '📝',
            color: TaskColor.none,
            scheduleValue: 7,
            scheduleUnit: ScheduleUnit.day,
          );
          await repository.recordExecution(
            idS,
            executedAt: DateTime(2025, 1, 1),
          );
          await setScheduleCache(idS, lastExecutedAt: DateTime(2025, 1, 1));
        });

        test('次回予定日がないタスクは末尾に来る', () async {
          final tasks = await repository.allTaskItems().first;
          expect(tasks[0].name, '定期タスク');
          expect(tasks[1].name, '不定期タスク');
        });
      });
    });
  });

  group('addTask', () {
    test('period タスクを追加できる', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
      );
      final tasks = await repository.allTaskItems().first;

      expect(tasks, hasLength(1));
      final task = tasks.first;
      expect(task, isA<PeriodTaskItem>());
      expect(task.name, '散髪');
      expect(task.furigana, 'さんぱつ');
      expect(task.color, TaskColor.none);
      expect((await repository.fetchTaskHistory(id)).items, isEmpty);
    });

    test('scheduled タスクを追加できる', () async {
      final id = await repository.addTask(
        taskType: TaskType.scheduled,
        name: '虫避け交換',
        icon: '📝',
        color: TaskColor.orange,
        scheduleValue: 2,
        scheduleUnit: ScheduleUnit.week,
      );
      final tasks = await repository.allTaskItems().first;

      expect(tasks, hasLength(1));
      final task = tasks.first as ScheduledTaskItem;
      expect(task.name, '虫避け交換');
      expect(task.furigana, 'むしよけこうかん');
      expect(task.scheduleValue, 2);
      expect(task.scheduleUnit, ScheduleUnit.week);
      expect((await repository.fetchTaskHistory(id)).items, isEmpty);
    });

    test('irregular タスクを追加できる', () async {
      await repository.addTask(
        taskType: TaskType.irregular,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
      );
      final tasks = await repository.allTaskItems().first;

      expect(tasks, hasLength(1));
      final task = tasks.first;
      expect(task, isA<IrregularTaskItem>());
      expect(task.name, '散髪');
      expect(task.scheduledAt, isNull);
    });

    test('scheduled タイプでスケジュール設定がないとき追加できない', () {
      expect(
        () => repository.addTask(
          taskType: TaskType.scheduled,
          name: '虫避け交換',
          icon: '📝',
          color: TaskColor.orange,
        ),
        throwsA(isA<TaskRepositoryException>()),
      );
    });
  });

  group('findTaskById', () {
    test('指定した ID の PeriodTaskItem を取得できる', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '✂️',
        color: TaskColor.none,
      );

      final task = await repository.findTaskById(id);
      expect(task, isA<PeriodTaskItem>());
      expect(task.id, id);
      expect(task.name, '散髪');
      expect(task.icon, '✂️');
    });

    test('指定した ID の ScheduledTaskItem を取得できる', () async {
      final id = await repository.addTask(
        taskType: TaskType.scheduled,
        name: '虫避け交換',
        icon: '📝',
        color: TaskColor.orange,
        scheduleValue: 2,
        scheduleUnit: ScheduleUnit.week,
      );

      final task = await repository.findTaskById(id) as ScheduledTaskItem;
      expect(task.id, id);
      expect(task.scheduleValue, 2);
      expect(task.scheduleUnit, ScheduleUnit.week);
    });

    test('存在しないタスクは取得できない', () {
      expect(
        () => repository.findTaskById('non-existent'),
        throwsA(isA<TaskRepositoryException>()),
      );
    });
  });

  group('recordExecution', () {
    test('実行履歴が追加される', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
      );
      await repository.recordExecution(id, executedAt: DateTime(2025, 6, 1));

      expect((await repository.fetchTaskHistory(id)).items, hasLength(1));
    });

    test('コメントなしで記録すると戻り値にコメントは含まれない', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
      );
      final history = await repository.recordExecution(
        id,
        executedAt: DateTime(2025, 6, 1),
      );

      expect(history.comment, isNull);
    });

    test('コメントありで記録すると履歴にコメントが保持される', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
      );
      final history = await repository.recordExecution(
        id,
        executedAt: DateTime(2025, 6, 1),
        comment: '良い感じ',
      );

      final taskHistory = (await repository.fetchTaskHistory(id)).items;
      final recorded = taskHistory.firstWhere((h) => h.id == history.id);
      expect(recorded.comment, '良い感じ');
    });
  });

  group('updateExecution', () {
    late String taskId;

    setUp(() async {
      taskId = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
      );
    });

    group('コメントなしの場合', () {
      late String executionId;

      setUp(() async {
        final history = await repository.recordExecution(
          taskId,
          executedAt: DateTime(2025, 6, 1),
          comment: null,
        );
        executionId = history.id;
      });

      test('日付を更新できる', () async {
        await repository.updateExecution(
          executionId,
          taskId: taskId,
          executedAt: DateTime(2025, 7, 1),
        );

        final taskHistory = (await repository.fetchTaskHistory(taskId)).items;
        final updated = taskHistory.firstWhere((h) => h.id == executionId);
        expect(updated.executedAt, DateTime(2025, 7, 1));
      });

      test('コメントを追加できる', () async {
        await repository.updateExecution(
          executionId,
          taskId: taskId,
          executedAt: DateTime(2025, 6, 1),
          comment: '更新コメント',
        );

        final taskHistory = (await repository.fetchTaskHistory(taskId)).items;
        final updated = taskHistory.firstWhere((h) => h.id == executionId);
        expect(updated.comment, '更新コメント');
      });
    });

    group('コメントありの場合', () {
      late String executionId;

      setUp(() async {
        final history = await repository.recordExecution(
          taskId,
          executedAt: DateTime(2025, 6, 1),
          comment: '元のコメント',
        );
        executionId = history.id;
      });

      test('コメントを削除できる', () async {
        await repository.updateExecution(
          executionId,
          taskId: taskId,
          executedAt: DateTime(2025, 6, 1),
        );

        final taskHistory = (await repository.fetchTaskHistory(taskId)).items;
        final updated = taskHistory.firstWhere((h) => h.id == executionId);
        expect(updated.comment, isNull);
      });
    });
  });

  group('updateTask', () {
    test('period タスクの name/icon/color を更新できる', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
      );
      await repository.updateTask(
        taskId: id,
        taskType: TaskType.period,
        name: '散髪(更新)',
        icon: '✂️',
        color: TaskColor.blue,
      );

      final task = await repository.findTaskById(id);
      expect(task, isA<PeriodTaskItem>());
      expect(task.name, '散髪(更新)');
      expect(task.furigana, 'さんぱつこうしん');
      expect(task.icon, '✂️');
      expect(task.color, TaskColor.blue);
    });

    test('scheduled タスクのスケジュール設定を更新できる', () async {
      final id = await repository.addTask(
        taskType: TaskType.scheduled,
        name: '虫避け交換',
        icon: '📝',
        color: TaskColor.orange,
        scheduleValue: 2,
        scheduleUnit: ScheduleUnit.week,
      );
      await repository.updateTask(
        taskId: id,
        taskType: TaskType.scheduled,
        name: '虫避け交換',
        icon: '📝',
        color: TaskColor.orange,
        scheduleValue: 1,
        scheduleUnit: ScheduleUnit.month,
      );

      final task = await repository.findTaskById(id) as ScheduledTaskItem;
      expect(task.scheduleValue, 1);
      expect(task.scheduleUnit, ScheduleUnit.month);
    });

    test('period タイプに変更すると scheduleConfig が削除される', () async {
      final id = await repository.addTask(
        taskType: TaskType.scheduled,
        name: '虫避け交換',
        icon: '📝',
        color: TaskColor.orange,
        scheduleValue: 2,
        scheduleUnit: ScheduleUnit.week,
      );
      await repository.updateTask(
        taskId: id,
        taskType: TaskType.period,
        name: '虫避け交換',
        icon: '📝',
        color: TaskColor.orange,
      );

      final task = await repository.findTaskById(id);
      expect(task, isA<PeriodTaskItem>());
    });

    test('scheduled タイプでスケジュール設定がないとき更新できない', () async {
      final id = await repository.addTask(
        taskType: TaskType.scheduled,
        name: '虫避け交換',
        icon: '📝',
        color: TaskColor.orange,
        scheduleValue: 2,
        scheduleUnit: ScheduleUnit.week,
      );

      expect(
        () => repository.updateTask(
          taskId: id,
          taskType: TaskType.scheduled,
          name: '虫避け交換',
          icon: '📝',
          color: TaskColor.orange,
        ),
        throwsA(isA<TaskRepositoryException>()),
      );
    });

    test('scheduled タイプの間隔を変更するとキャッシュされた次回予定日も更新される', () async {
      final id = await repository.addTask(
        taskType: TaskType.scheduled,
        name: '虫避け交換',
        icon: '📝',
        color: TaskColor.orange,
        scheduleValue: 7,
        scheduleUnit: ScheduleUnit.day,
      );
      await repository.recordExecution(id, executedAt: DateTime(2025, 1, 1));
      await setScheduleCache(id, lastExecutedAt: DateTime(2025, 1, 1));

      await repository.updateTask(
        taskId: id,
        taskType: TaskType.scheduled,
        name: '虫避け交換',
        icon: '📝',
        color: TaskColor.orange,
        scheduleValue: 14,
        scheduleUnit: ScheduleUnit.day,
      );

      final tasks = await repository.allTaskItems().first;
      expect(tasks.first.scheduledAt, DateTime(2025, 1, 15));
    });
  });

  group('watchTaskById', () {
    test('存在するタスクを emit する', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '✂️',
        color: TaskColor.none,
      );

      final task = await repository.watchTaskById(id).first;
      expect(task, isNotNull);
      expect(task!.id, id);
      expect(task.name, '散髪');
    });

    test('存在しない ID のとき null を emit する', () async {
      final result = await repository.watchTaskById('non-existent').first;
      expect(result, isNull);
    });
  });

  group('deleteExecution', () {
    test('指定した実行履歴が削除される', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
      );
      await repository.recordExecution(id, executedAt: DateTime(2025, 1, 1));
      final target = await repository.recordExecution(
        id,
        executedAt: DateTime(2025, 6, 1),
      );

      await repository.deleteExecution(target.id, taskId: id);

      final taskHistory = (await repository.fetchTaskHistory(id)).items;
      expect(taskHistory, hasLength(1));
      expect(taskHistory.first.executedAt, DateTime(2025, 1, 1));
    });

    test('他の履歴には影響しない', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
      );
      await repository.recordExecution(id, executedAt: DateTime(2025, 3, 1));
      final target = await repository.recordExecution(
        id,
        executedAt: DateTime(2025, 6, 1),
      );
      await repository.recordExecution(id, executedAt: DateTime(2025, 9, 1));

      await repository.deleteExecution(target.id, taskId: id);

      final taskHistory = (await repository.fetchTaskHistory(id)).items;
      expect(taskHistory, hasLength(2));
      expect(
        taskHistory.map((h) => h.executedAt),
        isNot(contains(DateTime(2025, 6, 1))),
      );
    });

    test('誤った taskId を渡しても実行履歴は削除されない', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
      );
      final target = await repository.recordExecution(
        id,
        executedAt: DateTime(2025, 6, 1),
      );

      await repository.deleteExecution(target.id, taskId: 'wrong-task-id');

      final taskHistory = (await repository.fetchTaskHistory(id)).items;
      expect(taskHistory, hasLength(1));
    });
  });

  group('deleteTask', () {
    test('指定したタスクが削除される', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
      );
      await repository.deleteTask(id);

      final tasks = await repository.allTaskItems().first;
      expect(tasks, isEmpty);
    });

    test('削除した実行履歴が戻り値として返る', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
      );
      await repository.recordExecution(id, executedAt: DateTime(2025, 1, 1));

      final deletedHistory = await repository.deleteTask(id);

      expect(deletedHistory, hasLength(1));
      expect(deletedHistory.first.executedAt, DateTime(2025, 1, 1));
    });

    // executions サブコレクション自体の削除は Cloud Functions
    // (onTaskDefinitionDeleted) の責務であり、fake_cloud_firestore は
    // 親ドキュメント削除時にサブコレクションも見かけ上消えてしまう（実際の
    // Firestore と異なりカスケード削除される）ため、ここではテストできない

    test('複数タスクのうち指定したものだけ削除される', () async {
      final id1 = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
      );
      await repository.addTask(
        taskType: TaskType.period,
        name: '歯ブラシ交換',
        icon: '📝',
        color: TaskColor.blue,
      );
      await repository.deleteTask(id1);

      final tasks = await repository.allTaskItems().first;
      expect(tasks, hasLength(1));
      expect(tasks.first.name, '歯ブラシ交換');
    });
  });

  group('restoreTask', () {
    test('削除した period タスクを履歴ごと復元できる', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '✂️',
        color: TaskColor.none,
      );
      await repository.recordExecution(id, executedAt: DateTime(2025, 1, 1));
      await repository.recordExecution(id, executedAt: DateTime(2025, 6, 1));
      final deleted = await repository.findTaskById(id);
      final deletedHistory = await repository.deleteTask(id);

      await repository.restoreTask([(deleted, deletedHistory)]);

      final tasks = await repository.allTaskItems().first;
      expect(tasks, hasLength(1));
      final restored = tasks.first;
      expect(restored, isA<PeriodTaskItem>());
      expect(restored.name, '散髪');
      expect(restored.icon, '✂️');
      expect(
        (await repository.fetchTaskHistory(restored.id)).items,
        hasLength(2),
      );
    });

    test('削除した scheduled タスクを scheduleConfig ごと復元できる', () async {
      final id = await repository.addTask(
        taskType: TaskType.scheduled,
        name: '虫避け交換',
        icon: '📝',
        color: TaskColor.orange,
        scheduleValue: 2,
        scheduleUnit: ScheduleUnit.week,
      );
      final deleted = await repository.findTaskById(id) as ScheduledTaskItem;
      final deletedHistory = await repository.deleteTask(id);

      await repository.restoreTask([(deleted, deletedHistory)]);

      final tasks = await repository.allTaskItems().first;
      expect(tasks, hasLength(1));
      final restored = tasks.first as ScheduledTaskItem;
      expect(restored.scheduleValue, 2);
      expect(restored.scheduleUnit, ScheduleUnit.week);
    });

    test('deleteTask が返す履歴で復元すると直近保持件数を超えても欠損しない', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '✂️',
        color: TaskColor.none,
      );
      for (var i = 1; i <= 12; i++) {
        await repository.recordExecution(id, executedAt: DateTime(2025, 1, i));
      }
      final deleted = await repository.findTaskById(id);
      final deletedHistory = await repository.deleteTask(id);
      expect(deletedHistory, hasLength(12));

      await repository.restoreTask([(deleted, deletedHistory)]);

      final restoredId = (await repository.allTaskItems().first).first.id;
      final executions = await firestore
          .collection('users')
          .doc('test-user')
          .collection('taskDefinitions')
          .doc(restoredId)
          .collection('executions')
          .get();
      expect(executions.docs, hasLength(12));
    });

    test('書き込み件数が500件を超えるタスクをまとめて復元してもすべて保存される', () async {
      final taskItems = [
        for (var i = 0; i < 501; i++)
          (
            TaskItem.irregular(
              id: 'dummy-$i',
              name: 'タスク$i',
              furigana: '',
              icon: '📝',
              color: TaskColor.none,
              lastExecutedAt: null,
            ),
            const <TaskHistory>[],
          ),
      ];

      await repository.restoreTask(taskItems);

      final tasks = await repository.allTaskItems().first;
      expect(tasks, hasLength(501));
    });
  });

  group('fetchTaskHistory', () {
    test('新しい順に返り、limit を超える件数があると hasMore が true になる', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
      );
      for (var i = 1; i <= 12; i++) {
        await repository.recordExecution(id, executedAt: DateTime(2025, 1, i));
      }

      final page = await repository.fetchTaskHistory(id, limit: 10);

      expect(page.items, hasLength(10));
      expect(page.items.first.executedAt, DateTime(2025, 1, 12));
      expect(page.items.last.executedAt, DateTime(2025, 1, 3));
      expect(page.hasMore, isTrue);
    });
  });

  // fetchTaskHistory は cursor 継続時に FieldPath.documentId を使っており、
  // fake_cloud_firestore がこれを正しく解決できないため自動テストできない。
  // 境界の正しさ（取りこぼし・重複がないこと）は手動で確認すること。
}
