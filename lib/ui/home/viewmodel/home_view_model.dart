import 'package:dawnbreaker/data/dummy/dummy_tasks.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_view_model.g.dart';

@riverpod
class HomeViewModel extends _$HomeViewModel {
  @override
  HomeUiState build() {
    _loadItem();
    return const HomeUiState(isLoading: true);
  }

  void updateSearchQuery(String query) {
    if (query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
  }

  Future<void> _loadItem() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!ref.mounted) return;
    state = state.copyWith(isLoading: false, tasks: dummyTasks);
  }
}
