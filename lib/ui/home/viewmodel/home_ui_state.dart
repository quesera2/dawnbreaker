import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_ui_state.freezed.dart';

@freezed
abstract class HomeUiState with _$HomeUiState {
  const HomeUiState._();

  const factory HomeUiState({
    @Default(false) bool isLoading,
    String? errorMessage,
    @Default([]) List<TaskItem> tasks,
    @Default('') String searchQuery,
  }) = _HomeUiState;

  bool get hasTasks => tasks.isNotEmpty;

  List<TaskItem> get filteredTasks {
    if (searchQuery.isEmpty) return tasks;
    final query = searchQuery.toLowerCase();
    return tasks.where((t) {
      if (t.name.toLowerCase().contains(query)) return true;
      final furigana = t.furigana;
      return furigana != null && furigana.contains(query);
    }).toList();
  }
}
