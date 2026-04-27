import 'package:dawnbreaker/data/database/app_database.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_furigana_translate.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = TaskRepositoryImpl(
      db: db,
      furiganaTranslate: const FakeFuriganaTranslate({
        '散髪': 'さんぱつ',
        '歯ブラシ交換': 'はぶらしこうかん',
        '虫避け交換': 'むしよけこうかん',
        '散髪(更新)': 'さんぱつこうしん',
      }),
    );
  });

  tearDown(() => db.close());

  group('scheduled タスクで config がないとき', () {
    test('タスク一覧の取得がエラーになる', () async {
      // DB に直接 scheduled タスクを挿入（taskScheduledConfigs なし）
      await db.into(db.taskDefinitions).insert(
        TaskDefinitionsCompanion.insert(
          taskType: TaskType.scheduled,
          name: 'config なしタスク',
          furigana: '',
          icon: '📝',
          color: TaskColor.none,
        ),
      );

      await expectLater(
        repository.allTaskItems(),
        emitsError(isA<TaskNotFoundException>()),
      );
    });
  });

  group('データベースエラー時の異常系', () {
    setUp(() async {
      await db.select(db.taskDefinitions).get();
      await db.close();
    });

    test('addTask: タスクの追加が失敗する', () async {
      await expectLater(
            () =>
            repository.addTask(
              taskType: TaskType.period,
              name: 'x',
              icon: '📝',
              color: TaskColor.none,
              executedAt: DateTime.now(),
            ),
        throwsA(isA<TaskSaveException>()),
      );
    });

    test('findTaskById: タスクの取得が失敗する', () async {
      await expectLater(
            () => repository.findTaskById(1),
        throwsA(isA<TaskLoadException>()),
      );
    });

    test('recordExecution: 実行の記録が失敗する', () async {
      await expectLater(
            () => repository.recordExecution(1, executedAt: DateTime.now()),
        throwsA(isA<TaskSaveException>()),
      );
    });

    test('updateExecution: 実行の更新が失敗する', () async {
      await expectLater(
            () => repository.updateExecution(1, executedAt: DateTime.now()),
        throwsA(isA<TaskUpdateException>()),
      );
    });

    test('deleteExecution: 実行の削除が失敗する', () async {
      await expectLater(
            () => repository.deleteExecution(1),
        throwsA(isA<TaskDeleteException>()),
      );
    });

    test('updateTask: タスクの更新が失敗する', () async {
      await expectLater(
            () =>
            repository.updateTask(
              taskId: 1,
              taskType: TaskType.period,
              name: 'x',
              icon: '📝',
              color: TaskColor.none,
            ),
        throwsA(isA<TaskUpdateException>()),
      );
    });

    test('deleteTask: タスクの削除が失敗する', () async {
      await expectLater(
            () => repository.deleteTask(1),
        throwsA(isA<TaskDeleteException>()),
      );
    });

    test('restoreTask: タスクの復元が失敗する', () async {
      const task = TaskItem.period(
        id: 1,
        name: 'x',
        furigana: '',
        icon: '📝',
        color: TaskColor.none,
        taskHistory: [],
      );
      await expectLater(
            () => repository.restoreTask(task),
        throwsA(isA<TaskSaveException>()),
      );
    });
  });

  group('allTaskItems ソート順', () {
    test('次回予定日が早いタスクが先に来る', () async {
      // 後の scheduledAt を先に追加して、ソートで前に来ることを確認
      await repository.addTask(
        taskType: TaskType.scheduled,
        name: 'タスクB',
        icon: '📝',
        color: TaskColor.none,
        scheduleValue: 7,
        scheduleUnit: ScheduleUnit.day,
        executedAt: DateTime(2025, 1, 15), // scheduledAt = 1/22
      );
      await repository.addTask(
        taskType: TaskType.scheduled,
        name: 'タスクA',
        icon: '📝',
        color: TaskColor.none,
        scheduleValue: 7,
        scheduleUnit: ScheduleUnit.day,
        executedAt: DateTime(2025, 1, 1), // scheduledAt = 1/8
      );

      final tasks = await repository
          .allTaskItems()
          .first;
      expect(tasks[0].name, 'タスクA'); // scheduledAt=1/8 が先
      expect(tasks[1].name, 'タスクB'); // scheduledAt=1/22 が後
    });

    test('次回予定日がないタスクは末尾に来る', () async {
      // PeriodTask 履歴1件 → scheduledAt=null
      await repository.addTask(
        taskType: TaskType.period,
        name: '不定期タスク',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime(2025, 1, 1),
      );
      await repository.addTask(
        taskType: TaskType.scheduled,
        name: '定期タスク',
        icon: '📝',
        color: TaskColor.none,
        scheduleValue: 7,
        scheduleUnit: ScheduleUnit.day,
        executedAt: DateTime(2025, 1, 1),
      );

      final tasks = await repository
          .allTaskItems()
          .first;
      expect(tasks[0].name, '定期タスク'); // scheduledAt あり
      expect(tasks[1].name, '不定期タスク'); // scheduledAt=null → 末尾
    });

    test('次回予定日がないタスクが複数あるとき全て末尾に集まる', () async {
      await repository.addTask(
        taskType: TaskType.scheduled,
        name: '定期タスク',
        icon: '📝',
        color: TaskColor.none,
        scheduleValue: 7,
        scheduleUnit: ScheduleUnit.day,
        executedAt: DateTime(2025, 1, 1),
      );
      await repository.addTask(
        taskType: TaskType.period,
        name: '不定期A',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime(2025, 1, 1),
      );
      await repository.addTask(
        taskType: TaskType.period,
        name: '不定期B',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime(2025, 1, 1),
      );

      final tasks = await repository
          .allTaskItems()
          .first;
      expect(tasks[0].name, '定期タスク');
      expect(
        tasks.skip(1).map((t) => t.name).toSet(),
        {'不定期A', '不定期B'},
      );
    });
  });

  group('addTask', () {
    test('period タスクを追加できる', () async {
      await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime.now(),
      );
      final tasks = await repository
          .allTaskItems()
          .first;

      expect(tasks, hasLength(1));
      final task = tasks.first;
      expect(task, isA<PeriodTaskItem>());
      expect(task.name, '散髪');
      expect(task.furigana, 'さんぱつ');
      expect(task.color, TaskColor.none);
      expect(task.taskHistory, hasLength(1));
    });

    test('scheduled タスクを追加できる', () async {
      await repository.addTask(
        taskType: TaskType.scheduled,
        name: '虫避け交換',
        icon: '📝',
        color: TaskColor.orange,
        scheduleValue: 2,
        scheduleUnit: ScheduleUnit.week,
        executedAt: DateTime.now(),
      );
      final tasks = await repository
          .allTaskItems()
          .first;

      expect(tasks, hasLength(1));
      final task = tasks.first as ScheduledTaskItem;
      expect(task.name, '虫避け交換');
      expect(task.furigana, 'むしよけこうかん');
      expect(task.scheduleValue, 2);
      expect(task.scheduleUnit, ScheduleUnit.week);
      expect(task.taskHistory, hasLength(1));
    });

    test('irregular タスクを追加できる', () async {
      await repository.addTask(
        taskType: TaskType.irregular,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime.now(),
      );
      final tasks = await repository
          .allTaskItems()
          .first;

      expect(tasks, hasLength(1));
      final task = tasks.first;
      expect(task, isA<IrregularTaskItem>());
      expect(task.name, '散髪');
      expect(task.scheduledAt, isNull);
    });

    test(
      'scheduled タイプでスケジュール設定がないとき例外を投げる',
          () async {
        expect(
              () =>
              repository.addTask(
                taskType: TaskType.scheduled,
                name: '虫避け交換',
                icon: '📝',
                color: TaskColor.orange,
                executedAt: DateTime.now(),
              ),
          throwsA(isA<TaskRepositoryException>()),
        );
      },
    );
  });

  group('findTaskById', () {
    test('指定した ID の PeriodTaskItem を取得できる', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '✂️',
        color: TaskColor.none,
        executedAt: DateTime.now(),
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
        executedAt: DateTime.now(),
      );

      final task = await repository.findTaskById(id) as ScheduledTaskItem;
      expect(task.id, id);
      expect(task.scheduleValue, 2);
      expect(task.scheduleUnit, ScheduleUnit.week);
    });

    test(
        '存在しない ID を指定すると TaskRepositoryException を投げる', () async {
      expect(
            () => repository.findTaskById(999),
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
        executedAt: DateTime(2025, 1, 1),
      );
      await repository.recordExecution(id, executedAt: DateTime(2025, 6, 1));

      final tasks = await repository
          .allTaskItems()
          .first;
      expect(tasks.first.taskHistory, hasLength(2));
    });

    test('履歴が2件以上になると scheduledAt が算出される', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime(2025, 1, 1),
      );
      await repository.recordExecution(id, executedAt: DateTime(2025, 2, 1));

      final tasks = await repository
          .allTaskItems()
          .first;
      expect(tasks.first.scheduledAt, isNotNull);
    });

    test('コメントなしで記録すると戻り値にコメントは含まれない', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime(2025, 1, 1),
      );
      final history = await repository.recordExecution(
        id,
        executedAt: DateTime(2025, 6, 1),
      );

      expect(history.comment, isNull);
    });

    test(
        'コメントなしで記録した履歴を取得するとコメントは保存されない', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime(2025, 1, 1),
      );
      final history = await repository.recordExecution(
        id,
        executedAt: DateTime(2025, 6, 1),
      );

      final task = await repository.findTaskById(id);
      final recorded = task.taskHistory.firstWhere((h) => h.id == history.id);
      expect(recorded.comment, isNull);
    });

    test('コメントありで記録すると戻り値にコメントが含まれる', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime(2025, 1, 1),
      );
      final history = await repository.recordExecution(
        id,
        executedAt: DateTime(2025, 6, 1),
        comment: '良い感じ',
      );

      expect(history.comment, '良い感じ');
    });

    test(
        'コメントありで記録した履歴を取得するとコメントが保持されている', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime(2025, 1, 1),
      );
      final history = await repository.recordExecution(
        id,
        executedAt: DateTime(2025, 6, 1),
        comment: '良い感じ',
      );

      final task = await repository.findTaskById(id);
      final recorded = task.taskHistory.firstWhere((h) => h.id == history.id);
      expect(recorded.comment, '良い感じ');
    });
  });

  group('updateExecution', () {
    late int taskId;

    setUp(() async {
      taskId = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime(2025, 1, 1),
      );
    });

    group('コメントなしの場合', () {
      late TaskHistory history;

      setUp(() async {
        history = await repository.recordExecution(
          taskId,
          executedAt: DateTime(2025, 6, 1),
          comment: null,
        );
      });

      test('日付を更新できる', () async {
        await repository.updateExecution(
          history.id,
          executedAt: DateTime(2025, 7, 1),
        );

        final task = await repository.findTaskById(taskId);
        final updated = task.taskHistory.firstWhere((h) => h.id == history.id);
        expect(updated.executedAt, DateTime(2025, 7, 1));
      });

      test('コメントを追加できる', () async {
        expect(history.comment, isNull);

        await repository.updateExecution(
          history.id,
          executedAt: history.executedAt,
          comment: '更新コメント',
        );

        final task = await repository.findTaskById(taskId);
        final updated = task.taskHistory.firstWhere((h) => h.id == history.id);
        expect(updated.comment, '更新コメント');
      });

      test('他の履歴には影響しない', () async {
        final other = await repository.recordExecution(
          taskId,
          executedAt: DateTime(2025, 9, 1),
        );
        await repository.updateExecution(
          history.id,
          executedAt: DateTime(2025, 7, 1),
        );

        final task = await repository.findTaskById(taskId);
        final otherUpdated =
        task.taskHistory.firstWhere((h) => h.id == other.id);
        expect(otherUpdated.executedAt, DateTime(2025, 9, 1));
      });
    });

    group('コメントありの場合', () {
      late TaskHistory history;

      setUp(() async {
        history = await repository.recordExecution(
          taskId,
          executedAt: DateTime(2025, 6, 1),
          comment: '元のコメント',
        );
      });

      test('コメントを削除できる', () async {
        expect(history.comment, '元のコメント');

        await repository.updateExecution(
          history.id,
          executedAt: history.executedAt,
        );

        final task = await repository.findTaskById(taskId);
        final updated = task.taskHistory.firstWhere((h) => h.id == history.id);
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
        executedAt: DateTime.now(),
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
        executedAt: DateTime.now(),
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

    test('period タイプに変更するとスケジュール設定が削除される', () async {
      final id = await repository.addTask(
        taskType: TaskType.scheduled,
        name: '虫避け交換',
        icon: '📝',
        color: TaskColor.orange,
        scheduleValue: 2,
        scheduleUnit: ScheduleUnit.week,
        executedAt: DateTime.now(),
      );
      await repository.updateTask(
        taskId: id,
        taskType: TaskType.period,
        name: '虫避け交換',
        icon: '📝',
        color: TaskColor.orange,
      );

      final configs = await db.select(db.taskScheduledConfigs).get();
      expect(configs, isEmpty);
    });

    test('scheduled タイプに変更するとスケジュール設定が追加される', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime.now(),
      );
      await repository.updateTask(
        taskId: id,
        taskType: TaskType.scheduled,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        scheduleValue: 3,
        scheduleUnit: ScheduleUnit.month,
      );

      final configs = await db.select(db.taskScheduledConfigs).get();
      expect(configs, hasLength(1));
      expect(configs.first.scheduleValue, 3);
      expect(configs.first.scheduleUnit, ScheduleUnit.month);
    });

    test(
      'scheduled タイプでスケジュール設定がないとき例外を投げる',
          () async {
        final id = await repository.addTask(
          taskType: TaskType.scheduled,
          name: '虫避け交換',
          icon: '📝',
          color: TaskColor.orange,
          scheduleValue: 2,
          scheduleUnit: ScheduleUnit.week,
          executedAt: DateTime.now(),
        );

        expect(
              () =>
              repository.updateTask(
                taskId: id,
                taskType: TaskType.scheduled,
                name: '虫避け交換',
                icon: '📝',
                color: TaskColor.orange,
              ),
          throwsA(isA<TaskRepositoryException>()),
        );
      },
    );
  });

  group('watchTaskById', () {
    test('存在するタスクを emit する', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '✂️',
        color: TaskColor.none,
        executedAt: DateTime.now(),
      );

      final task = await repository
          .watchTaskById(id)
          .first;
      expect(task, isNotNull);
      expect(task!.id, id);
      expect(task.name, '散髪');
    });

    test('存在しない ID のとき null を emit する', () async {
      final result = await repository
          .watchTaskById(999)
          .first;
      expect(result, isNull);
    });

    test('タスクが更新されたとき新しい値を emit する', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime.now(),
      );

      final future = expectLater(
        repository.watchTaskById(id),
        emitsInOrder([
          isA<TaskItem>().having((t) => t.name, 'name', '散髪'),
          isA<TaskItem>().having((t) => t.name, 'name', '散髪(更新)'),
        ]),
      );

      await repository.updateTask(
        taskId: id,
        taskType: TaskType.period,
        name: '散髪(更新)',
        icon: '📝',
        color: TaskColor.none,
      );

      await future;
    });

    test('タスクが削除されたとき null を emit する', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime.now(),
      );

      final future = expectLater(
        repository.watchTaskById(id),
        emitsInOrder([isA<TaskItem>(), isNull]),
      );

      await repository.deleteTask(id);

      await future;
    });
  });

  group('deleteExecution', () {
    test('指定した実行履歴が削除される', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime(2025, 1, 1),
      );
      final history = await repository.recordExecution(
        id,
        executedAt: DateTime(2025, 6, 1),
      );

      await repository.deleteExecution(history.id);

      final task = await repository.findTaskById(id);
      expect(task.taskHistory, hasLength(1));
      expect(task.taskHistory.first.executedAt, DateTime(2025, 1, 1));
    });

    test('他の履歴には影響しない', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime(2025, 1, 1),
      );
      await repository.recordExecution(id, executedAt: DateTime(2025, 3, 1));
      final target = await repository.recordExecution(
        id,
        executedAt: DateTime(2025, 6, 1),
      );
      await repository.recordExecution(id, executedAt: DateTime(2025, 9, 1));

      await repository.deleteExecution(target.id);

      final task = await repository.findTaskById(id);
      expect(task.taskHistory, hasLength(3));
      expect(
        task.taskHistory.map((h) => h.executedAt),
        isNot(contains(DateTime(2025, 6, 1))),
      );
    });
  });

  group('restoreTask', () {
    test('削除した period タスクを履歴ごと復元できる', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '✂️',
        color: TaskColor.none,
        executedAt: DateTime(2025, 1, 1),
      );
      await repository.recordExecution(id, executedAt: DateTime(2025, 6, 1));
      final deleted = await repository.findTaskById(id);
      await repository.deleteTask(id);

      await repository.restoreTask(deleted);

      final tasks = await repository
          .allTaskItems()
          .first;
      expect(tasks, hasLength(1));
      final restored = tasks.first;
      expect(restored, isA<PeriodTaskItem>());
      expect(restored.name, '散髪');
      expect(restored.icon, '✂️');
      expect(restored.taskHistory, hasLength(2));
    });

    test('削除した scheduled タスクを scheduleConfig ごと復元できる', () async {
      final id = await repository.addTask(
        taskType: TaskType.scheduled,
        name: '虫避け交換',
        icon: '📝',
        color: TaskColor.orange,
        scheduleValue: 2,
        scheduleUnit: ScheduleUnit.week,
        executedAt: DateTime.now(),
      );
      final deleted = await repository.findTaskById(id) as ScheduledTaskItem;
      await repository.deleteTask(id);

      await repository.restoreTask(deleted);

      final tasks = await repository
          .allTaskItems()
          .first;
      expect(tasks, hasLength(1));
      final restored = tasks.first as ScheduledTaskItem;
      expect(restored.scheduleValue, 2);
      expect(restored.scheduleUnit, ScheduleUnit.week);
    });

    test('復元後に watchTaskById で取得できる', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime.now(),
      );
      final deleted = await repository.findTaskById(id);
      await repository.deleteTask(id);

      await repository.restoreTask(deleted);

      final tasks = await repository
          .allTaskItems()
          .first;
      final restoredId = tasks.first.id;
      final watched = await repository
          .watchTaskById(restoredId)
          .first;
      expect(watched, isNotNull);
      expect(watched!.name, '散髪');
    });
  });

  group('deleteTask', () {
    test('指定したタスクが削除される', () async {
      final id = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime.now(),
      );
      await repository.deleteTask(id);

      final tasks = await repository
          .allTaskItems()
          .first;
      expect(tasks, isEmpty);
    });

    test('複数タスクのうち指定したものだけ削除される', () async {
      final id1 = await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime.now(),
      );
      await repository.addTask(
        taskType: TaskType.period,
        name: '歯ブラシ交換',
        icon: '📝',
        color: TaskColor.blue,
        executedAt: DateTime.now(),
      );
      await repository.deleteTask(id1);

      final tasks = await repository
          .allTaskItems()
          .first;
      expect(tasks, hasLength(1));
      expect(tasks.first.name, '歯ブラシ交換');
    });
  });
}
