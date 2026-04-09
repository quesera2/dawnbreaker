import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';

final dummyTasks = [
  TaskItem(
    taskType: TaskType.period,
    name: '歯ブラシ交換',
    color: TaskColor.blue,
    registeredAt: DateTime(2026, 3, 10),
  ),
  TaskItem(
    taskType: TaskType.period,
    name: '散髪',
    color: TaskColor.none,
    registeredAt: DateTime(2026, 2, 20),
  ),
  TaskItem(
    taskType: TaskType.period,
    name: '洗濯槽クリーニング',
    color: TaskColor.green,
    registeredAt: DateTime(2025, 11, 5),
  ),
  TaskItem(
    taskType: TaskType.period,
    name: '布団干し',
    color: TaskColor.yellow,
    registeredAt: DateTime(2026, 3, 28),
  ),
  TaskItem(
    taskType: TaskType.scheduled,
    name: '虫避け交換',
    color: TaskColor.orange,
    registeredAt: DateTime(2026, 3, 26),
    scheduledAt: DateTime(2026, 4, 9),
  ),
  TaskItem(
    taskType: TaskType.scheduled,
    name: 'エアコンフィルタ掃除',
    color: TaskColor.red,
    registeredAt: DateTime(2026, 2, 1),
    scheduledAt: DateTime(2026, 4, 1),
  ),
  TaskItem(
    taskType: TaskType.scheduled,
    name: '給水フィルタ交換',
    color: TaskColor.blue,
    registeredAt: DateTime(2026, 1, 15),
    scheduledAt: DateTime(2026, 4, 15),
  ),
];
