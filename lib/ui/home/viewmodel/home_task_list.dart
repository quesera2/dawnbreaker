import 'package:collection/collection.dart';
import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_progress.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_ui_state.dart';

enum HomeTaskListType {
  overdueTasks,
  upcomingTasks,
  none,
  red,
  blue,
  yellow,
  green,
  orange,
}

extension on TaskColor {
  HomeTaskListType get asListType => switch (this) {
    .none => .none,
    .red => .red,
    .blue => .blue,
    .yellow => .yellow,
    .green => .green,
    .orange => .orange,
  };
}

class HomeTaskList {
  HomeTaskList._({required this.taskItemMap, this.colorAliases = const {}});

  final Map<HomeTaskListType, List<TaskItem>> taskItemMap;

  // null = デフォルト名を使う, non-null = カスタムエイリアス
  final Map<HomeTaskListType, String?> colorAliases;

  bool get isEmpty => taskItemMap.values.every((list) => list.isEmpty);

  String? aliasFor(HomeTaskListType type) => colorAliases[type];

  factory HomeTaskList.from({
    required HomeDisplayMode displayMode,
    required List<TaskItem> tasks,
    required String searchQuery,
    required HomeFilter filter,
    required List<ColorSetting> colorSettings,
    DateTime? now,
  }) {
    final filtered = _applySearchAndFilter(tasks, searchQuery, filter, now);
    return switch (displayMode) {
      .timeline => _buildTimeline(filtered, now),
      .byColor => _buildByColor(filtered, colorSettings),
    };
  }

  static HomeTaskList _buildTimeline(Iterable<TaskItem> tasks, DateTime? now) {
    final taskItemMap = tasks
        .groupListsBy((t) {
          final p = t.computeProgress(now);
          return p is DueDate && p.isOverdue;
        })
        .map((key, value) {
          final newKey = key
              ? HomeTaskListType.overdueTasks
              : HomeTaskListType.upcomingTasks;
          return MapEntry(newKey, value);
        });
    return HomeTaskList._(taskItemMap: taskItemMap);
  }

  static HomeTaskList _buildByColor(
    Iterable<TaskItem> tasks,
    List<ColorSetting> colorSettings,
  ) {
    final grouped = tasks.groupListsBy((t) => t.color.asListType);
    final ordered = colorSettings.isEmpty
        ? HomeTaskListType.values
        : colorSettings.map((s) => s.color.asListType);

    final taskItemMap = Map.fromEntries(
      ordered
          .where((t) => grouped.containsKey(t))
          .map((t) => MapEntry(t, grouped[t] ?? [])),
    );

    final colorAliases = Map.fromEntries(
      colorSettings.map(
        (s) =>
            MapEntry(s.color.asListType, s.alias.isNotEmpty ? s.alias : null),
      ),
    );

    return HomeTaskList._(taskItemMap: taskItemMap, colorAliases: colorAliases);
  }
}

Iterable<TaskItem> _applySearchAndFilter(
  List<TaskItem> tasks,
  String searchQuery,
  HomeFilter filter,
  DateTime? now,
) {
  final searched = searchQuery.isEmpty
      ? tasks
      : tasks.where((t) {
          final q = searchQuery.toLowerCase();
          return t.name.toLowerCase().contains(q) || t.furigana.contains(q);
        });

  return switch (filter) {
    HomeFilter.all => searched,
    HomeFilter.overdue => searched.where((t) {
      final p = t.computeProgress(now);
      return p is DueDate && p.isOverdue;
    }),
    HomeFilter.today => searched.where((t) {
      final p = t.computeProgress(now);
      return p is DueDate && !p.isOverdue && p.isToday;
    }),
    HomeFilter.week => searched.where((t) {
      final p = t.computeProgress(now);
      return p is DueDate && !p.isOverdue && p.isCurrentWeek;
    }),
    HomeFilter.irregular => searched.where((t) {
      final p = t.computeProgress(now);
      return p is NoDueDate;
    }),
  };
}
