import 'package:dawnbreaker/data/database/app_database.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
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

  group('addTask', () {
    test('period タスクが追加され PeriodTaskItem として取得できる', () async {
      await repository.addTask(
        taskType: TaskType.period,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime.now(),
      );
      final tasks = await repository.allTaskItems().first;

      expect(tasks, hasLength(1));
      final task = tasks.first;
      expect(task, isA<PeriodTaskItem>());
      expect(task.name, '散髪');
      expect(task.furigana, 'さんぱつ');
      expect(task.color, TaskColor.none);
      expect(task.taskHistory, hasLength(1));
    });

    test('scheduled タスクが追加され ScheduledTaskItem として取得できる', () async {
      await repository.addTask(
        taskType: TaskType.scheduled,
        name: '虫避け交換',
        icon: '📝',
        color: TaskColor.orange,
        scheduleValue: 2,
        scheduleUnit: ScheduleUnit.week,
        executedAt: DateTime.now(),
      );
      final tasks = await repository.allTaskItems().first;

      expect(tasks, hasLength(1));
      final task = tasks.first as ScheduledTaskItem;
      expect(task.name, '虫避け交換');
      expect(task.furigana, 'むしよけこうかん');
      expect(task.scheduleValue, 2);
      expect(task.scheduleUnit, ScheduleUnit.week);
      expect(task.taskHistory, hasLength(1));
    });

    test('irregular タスクが追加され IrregularTaskItem として取得できる', () async {
      await repository.addTask(
        taskType: TaskType.irregular,
        name: '散髪',
        icon: '📝',
        color: TaskColor.none,
        executedAt: DateTime.now(),
      );
      final tasks = await repository.allTaskItems().first;

      expect(tasks, hasLength(1));
      final task = tasks.first;
      expect(task, isA<IrregularTaskItem>());
      expect(task.name, '散髪');
      expect(task.scheduledAt, isNull);
    });

    test(
      'scheduled タイプで scheduleValue/scheduleUnit が null のとき例外を投げる',
      () async {
        expect(
          () => repository.addTask(
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

    test('存在しない ID を指定すると TaskRepositoryException を投げる', () async {
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

      final tasks = await repository.allTaskItems().first;
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

      final tasks = await repository.allTaskItems().first;
      expect(tasks.first.scheduledAt, isNotNull);
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

    test('scheduled タスクの scheduleValue/scheduleUnit を更新できる', () async {
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

    test('scheduled から period に変更すると taskScheduledConfigs が削除される', () async {
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

    test('period から scheduled に変更すると taskScheduledConfigs が追加される', () async {
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
      'scheduled タイプで scheduleValue/scheduleUnit が null のとき例外を投げる',
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
          () => repository.updateTask(
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

      final tasks = await repository.allTaskItems().first;
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

      final tasks = await repository.allTaskItems().first;
      expect(tasks, hasLength(1));
      expect(tasks.first.name, '歯ブラシ交換');
    });
  });
}
