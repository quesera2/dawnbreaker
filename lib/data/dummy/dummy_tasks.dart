import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_type.dart';

final dummyTasks = [
  TaskItem(
    id: 1,
    taskType: TaskType.period,
    name: '歯ブラシ交換',
    furigana: 'はぶらしこうかん',
    color: TaskColor.blue,
    registeredAt: DateTime(2026, 3, 10),
  ),
  TaskItem(
    id: 2,
    taskType: TaskType.period,
    name: '散髪',
    furigana: 'さんぱつ',
    color: TaskColor.none,
    registeredAt: DateTime(2026, 2, 20),
  ),
  TaskItem(
    id: 3,
    taskType: TaskType.period,
    name: '洗濯槽クリーニング',
    furigana: 'せんたくそうくりーにんぐ',
    color: TaskColor.green,
    registeredAt: DateTime(2025, 11, 5),
  ),
  TaskItem(
    id: 4,
    taskType: TaskType.period,
    name: '布団干し',
    furigana: 'ふとんほし',
    color: TaskColor.yellow,
    registeredAt: DateTime(2026, 3, 28),
  ),
  TaskItem(
    id: 5,
    taskType: TaskType.scheduled,
    name: '虫避け交換',
    furigana: 'むしよけこうかん',
    color: TaskColor.orange,
    registeredAt: DateTime(2026, 3, 26),
    scheduledAt: DateTime(2026, 4, 9),
  ),
  TaskItem(
    id: 6,
    taskType: TaskType.scheduled,
    name: 'エアコンフィルタ掃除',
    furigana: 'えあこんふぃるたそうじ',
    color: TaskColor.red,
    registeredAt: DateTime(2026, 2, 1),
    scheduledAt: DateTime(2026, 5, 1),
  ),
  TaskItem(
    id: 7,
    taskType: TaskType.scheduled,
    name: '給水フィルタ交換',
    furigana: 'きゅうすいふぃるたこうかん',
    color: TaskColor.blue,
    registeredAt: DateTime(2026, 1, 15),
    scheduledAt: DateTime(2026, 7, 15),
  ),
];
