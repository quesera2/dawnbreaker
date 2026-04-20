import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/data/model/task_progress.dart';
import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/error_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_ui_state.freezed.dart';

enum HomeFilter { all, overdue, today, week }

@freezed
abstract class HomeUiState with _$HomeUiState implements BaseUiState {
  const HomeUiState._();

  const factory HomeUiState({
    @Default(false) bool isLoading,
    ErrorMessage? errorMessage,
    @Default([]) List<TaskItem> tasks,
    @Default('') String searchQuery,
    @Default(HomeFilter.all) HomeFilter selectedFilter,
  }) = _HomeUiState;

  bool get hasTasks => tasks.isNotEmpty;

  int get overdueCount => tasks.where((t) {
    final p = t.computeProgress();
    return p is DueDate && p.isOverdue;
  }).length;

  int get todayCount => tasks.where((t) {
    final p = t.computeProgress();
    return p is DueDate && !p.isOverdue && p.daysRemaining == 0;
  }).length;

  int get weekCount => tasks.where((t) {
    final p = t.computeProgress();
    return p is DueDate && !p.isOverdue && p.daysRemaining <= 7;
  }).length;

  List<TaskItem> get _searchFiltered {
    if (searchQuery.isEmpty) return tasks;
    final query = searchQuery.toLowerCase();
    return tasks.where((t) {
      if (t.name.toLowerCase().contains(query)) return true;
      return t.furigana.contains(query);
    }).toList();
  }

  List<TaskItem> get filteredTasks => switch (selectedFilter) {
    HomeFilter.all => _searchFiltered,
    HomeFilter.overdue => _searchFiltered.where((t) {
      final p = t.computeProgress();
      return p is DueDate && p.isOverdue;
    }).toList(),
    HomeFilter.today => _searchFiltered.where((t) {
      final p = t.computeProgress();
      return p is DueDate && !p.isOverdue && p.daysRemaining == 0;
    }).toList(),
    HomeFilter.week => _searchFiltered.where((t) {
      final p = t.computeProgress();
      return p is DueDate && !p.isOverdue && p.daysRemaining <= 7;
    }).toList(),
  };

  List<TaskItem> get overdueTasks => filteredTasks.where((t) {
    final p = t.computeProgress();
    return p is DueDate && p.isOverdue;
  }).toList();

  List<TaskItem> get upcomingTasks => filteredTasks.where((t) {
    final p = t.computeProgress();
    return !(p is DueDate && p.isOverdue);
  }).toList();
}