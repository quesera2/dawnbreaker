import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_impl.dart';
import 'package:dawnbreaker/ui/common/error_message.dart';
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
    } on TaskRepositoryException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: TaskLoadErrorMessage(handler: _initialize),
      );
      return;
    }
    if (!ref.mounted) return;

    final subscription = _repository.allTaskItems().listen((tasks) {
      state = state.copyWith(isLoading: false, tasks: tasks);
    });
    ref.onDispose(subscription.cancel);
  }

  Future<void> _seedIfNeeded() async {
    final tasks = await _repository.allTaskItems().first;
    if (tasks.isNotEmpty || !ref.mounted) return;

    final now = DateTime.now();

    // 超過: avg 30日サイクル, 3日超過
    final toothbrushId = await _repository.addPeriodTask(
      icon: '🪥',
      name: '歯ブラシ交換',
      color: TaskColor.blue,
      executedAt: now.subtract(const Duration(days: 33)),
    );
    await _repository.recordExecution(
      toothbrushId,
      executedAt: now.subtract(const Duration(days: 93)),
    );
    await _repository.recordExecution(
      toothbrushId,
      executedAt: now.subtract(const Duration(days: 63)),
    );

    // 超過: 3ヶ月スケジュール, 約5日超過
    await _repository.addScheduledTask(
      icon: '🧊',
      name: 'エアコンフィルタ掃除',
      color: TaskColor.red,
      scheduleValue: 3,
      scheduleUnit: ScheduleUnit.month,
      executedAt: now.subtract(const Duration(days: 95)),
    );

    // ~85%: 6ヶ月スケジュール, 153/180日
    await _repository.addScheduledTask(
      icon: '💧',
      name: '給水フィルタ交換',
      color: TaskColor.blue,
      scheduleValue: 6,
      scheduleUnit: ScheduleUnit.month,
      executedAt: now.subtract(const Duration(days: 153)),
    );

    // ~80%: avg 90日サイクル, 72/90日
    final futonId = await _repository.addPeriodTask(
      icon: '🛏️',
      name: '布団干し',
      color: TaskColor.yellow,
      executedAt: now.subtract(const Duration(days: 72)),
    );
    await _repository.recordExecution(
      futonId,
      executedAt: now.subtract(const Duration(days: 252)),
    );
    await _repository.recordExecution(
      futonId,
      executedAt: now.subtract(const Duration(days: 162)),
    );

    // ~55%: avg 150日サイクル, 82/150日
    final washId = await _repository.addPeriodTask(
      icon: '🧺',
      name: '洗濯槽クリーニング',
      color: TaskColor.green,
      executedAt: now.subtract(const Duration(days: 82)),
    );
    await _repository.recordExecution(
      washId,
      executedAt: now.subtract(const Duration(days: 232)),
    );

    // ~40%: avg 80日サイクル, 32/80日
    final hairId = await _repository.addPeriodTask(
      icon: '✂️',
      name: '散髪',
      color: TaskColor.none,
      executedAt: now.subtract(const Duration(days: 32)),
    );
    await _repository.recordExecution(
      hairId,
      executedAt: now.subtract(const Duration(days: 192)),
    );
    await _repository.recordExecution(
      hairId,
      executedAt: now.subtract(const Duration(days: 112)),
    );

    // ~29%: 2週間スケジュール, 4/14日
    await _repository.addScheduledTask(
      icon: '🐝',
      name: '虫避け交換',
      color: TaskColor.orange,
      scheduleValue: 2,
      scheduleUnit: ScheduleUnit.week,
      executedAt: now.subtract(const Duration(days: 4)),
    );

    // 超過: 1ヶ月スケジュール, 10日超過
    await _repository.addScheduledTask(
      icon: '🚗',
      name: '洗車',
      color: TaskColor.blue,
      scheduleValue: 1,
      scheduleUnit: ScheduleUnit.month,
      executedAt: now.subtract(const Duration(days: 40)),
    );

    // ~90%: 1週間スケジュール, 6/7日
    await _repository.addScheduledTask(
      icon: '🪴',
      name: '観葉植物の水やり',
      color: TaskColor.green,
      scheduleValue: 1,
      scheduleUnit: ScheduleUnit.week,
      executedAt: now.subtract(const Duration(days: 6)),
    );

    // ~70%: 12ヶ月スケジュール, 255/365日
    await _repository.addScheduledTask(
      icon: '🔥',
      name: '火災報知器の電池交換',
      color: TaskColor.red,
      scheduleValue: 12,
      scheduleUnit: ScheduleUnit.month,
      executedAt: now.subtract(const Duration(days: 255)),
    );

    // ~60%: avg 60日サイクル, 36/60日
    final bathId = await _repository.addPeriodTask(
      icon: '🛁',
      name: 'バスルーム大掃除',
      color: TaskColor.orange,
      executedAt: now.subtract(const Duration(days: 36)),
    );
    await _repository.recordExecution(
      bathId,
      executedAt: now.subtract(const Duration(days: 96)),
    );

    // ~50%: 2ヶ月スケジュール, 30/60日
    await _repository.addScheduledTask(
      icon: '💊',
      name: 'サプリ補充',
      color: TaskColor.yellow,
      scheduleValue: 2,
      scheduleUnit: ScheduleUnit.month,
      executedAt: now.subtract(const Duration(days: 30)),
    );

    // ~20%: 12ヶ月スケジュール, 73/365日
    await _repository.addScheduledTask(
      icon: '🧯',
      name: '消火器の点検',
      color: TaskColor.red,
      scheduleValue: 12,
      scheduleUnit: ScheduleUnit.month,
      executedAt: now.subtract(const Duration(days: 73)),
    );

    // ~10%: avg 200日サイクル, 20/200日
    final pcId = await _repository.addPeriodTask(
      icon: '🖥️',
      name: 'PCのホコリ掃除',
      color: TaskColor.none,
      executedAt: now.subtract(const Duration(days: 20)),
    );
    await _repository.recordExecution(
      pcId,
      executedAt: now.subtract(const Duration(days: 220)),
    );

    // 超過: avg 14日サイクル, 2日超過
    final plantId = await _repository.addPeriodTask(
      icon: '🌿',
      name: 'ベランダの草むしり',
      color: TaskColor.green,
      executedAt: now.subtract(const Duration(days: 16)),
    );
    await _repository.recordExecution(
      plantId,
      executedAt: now.subtract(const Duration(days: 30)),
    );

    // ~35%: 3ヶ月スケジュール, 32/90日
    await _repository.addScheduledTask(
      icon: '👟',
      name: 'スニーカーの洗濯',
      color: TaskColor.blue,
      scheduleValue: 3,
      scheduleUnit: ScheduleUnit.month,
      executedAt: now.subtract(const Duration(days: 32)),
    );

    // ~75%: 1ヶ月スケジュール, 22/30日
    await _repository.addScheduledTask(
      icon: '🧹',
      name: '排水口の掃除',
      color: TaskColor.orange,
      scheduleValue: 1,
      scheduleUnit: ScheduleUnit.month,
      executedAt: now.subtract(const Duration(days: 22)),
    );
  }

  void updateSearchQuery(String query) {
    if (query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
  }
}
