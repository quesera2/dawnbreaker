import 'package:dawnbreaker/data/dummy/dummy_tasks.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_view_model.g.dart';

@riverpod
class HomeViewModel extends _$HomeViewModel {
  @override
  HomeUiState build() {
    _init();
    return const HomeUiState(isLoading: true);
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(isLoading: false, tasks: dummyTasks);
  }

  void updateSearchQuery(String query) {
    if (query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
  }
}
