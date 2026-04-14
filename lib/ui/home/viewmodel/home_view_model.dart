import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_view_model.g.dart';

@riverpod
class HomeViewModel extends _$HomeViewModel {
  late TaskRepository _repository;

  @override
  HomeUiState build() {
    _repository = ref.read(taskRepositoryProvider);
    _initialize();
    return const HomeUiState(isLoading: true);
  }

  Future<void> _initialize() async {
    try {
      await _seedIfNeeded();
    } on TaskRepositoryException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return;
    }
    if (!ref.mounted) return;

    final subscription = _repository.watchAllTasks().listen((tasks) {
      state = state.copyWith(isLoading: false, tasks: tasks);
    });
    ref.onDispose(subscription.cancel);
  }

  Future<void> _seedIfNeeded() async {
    final tasks = await _repository.watchAllTasks().first;
    if (tasks.isNotEmpty || !ref.mounted) return;

    final toothbrushId = await _repository.addPeriodTask(
      name: '歯ブラシ交換',
      color: TaskColor.blue,
    );
    await _repository.recordExecution(toothbrushId, executedAt: DateTime(2026, 1, 10));
    await _repository.recordExecution(toothbrushId, executedAt: DateTime(2026, 2, 13));
    await _repository.recordExecution(toothbrushId, executedAt: DateTime(2026, 3, 12));

    await _repository.addPeriodTask(name: '散髪', color: TaskColor.none);

    final washId = await _repository.addPeriodTask(
      name: '洗濯槽クリーニング',
      color: TaskColor.green,
    );
    await _repository.recordExecution(washId, executedAt: DateTime(2025, 10, 5));

    final futonId = await _repository.addPeriodTask(
      name: '布団干し',
      color: TaskColor.yellow,
    );
    await _repository.recordExecution(futonId, executedAt: DateTime(2025, 7, 10));
    await _repository.recordExecution(futonId, executedAt: DateTime(2025, 10, 16));
    await _repository.recordExecution(futonId, executedAt: DateTime(2026, 1, 9));

    await _repository.addScheduledTask(
      name: '虫避け交換',
      color: TaskColor.orange,
      scheduleValue: 2,
      scheduleUnit: ScheduleUnit.week,
    );

    final airconId = await _repository.addScheduledTask(
      name: 'エアコンフィルタ掃除',
      color: TaskColor.red,
      scheduleValue: 3,
      scheduleUnit: ScheduleUnit.month,
    );
    await _repository.recordExecution(airconId, executedAt: DateTime(2026, 1, 13));

    final waterId = await _repository.addScheduledTask(
      name: '給水フィルタ交換',
      color: TaskColor.blue,
      scheduleValue: 6,
      scheduleUnit: ScheduleUnit.month,
    );
    await _repository.recordExecution(waterId, executedAt: DateTime(2025, 4, 10));
    await _repository.recordExecution(waterId, executedAt: DateTime(2025, 10, 20));
  }

  void updateSearchQuery(String query) {
    if (query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
  }
}