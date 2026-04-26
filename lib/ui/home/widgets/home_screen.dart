import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/common/components/app_filter_chip.dart';
import 'package:dawnbreaker/ui/common/components/app_icon_button.dart';
import 'package:dawnbreaker/ui/common/components/app_input.dart';
import 'package:dawnbreaker/ui/common/components/app_section_header.dart';
import 'package:dawnbreaker/ui/common/default_sticky_header.dart';
import 'package:dawnbreaker/ui/common/messages_mixin.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_task_list.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_ui_state.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_view_model.dart';
import 'package:dawnbreaker/ui/home/widgets/task_complete_sheet.dart';
import 'package:dawnbreaker/ui/home/widgets/task_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with MessagesListenMixin<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    listenMessages(homeViewModelProvider);
    final uiState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    if (uiState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final colorScheme = context.appColorScheme;
    final taskList = uiState.taskList;

    return Scaffold(
      body: CustomScrollView(
        clipBehavior: Clip.none,
        slivers: [
          SliverAppBar(
            pinned: true,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 3.0,
            shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
            title: const _HomeAppBar(),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: AppSearchInput(
                      placeholder: context.l10n.homeSearchHint,
                      controller: _searchController,
                      showClear: uiState.searchQuery.isNotEmpty,
                      onChanged: viewModel.updateSearchQuery,
                      onClear: () {
                        _searchController.clear();
                        viewModel.updateSearchQuery('');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _FilterChipRow(
              uiState: uiState,
              onFilterChanged: viewModel.updateFilter,
            ),
          ),
          ..._buildContentSlivers(context, uiState.hasTasks, taskList),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: 8 + MediaQuery.paddingOf(context).bottom,
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteSheet(BuildContext context, TaskItem task) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => TaskCompleteSheet(
        task: task,
        onConfirm: (date, comment) => ref
            .read(homeViewModelProvider.notifier)
            .recordExecution(task, date, comment),
      ),
    );
  }

  List<Widget> _buildContentSlivers(
    BuildContext context,
    bool hasTasks,
    HomeTaskList taskList,
  ) {
    final overdue = taskList.overdueTasks;
    final upcoming = taskList.upcomingTasks;
    final colors = context.appColorScheme;

    if (overdue.isEmpty && upcoming.isEmpty) {
      final colors = context.appColorScheme;
      return [
        SliverFillRemaining(
          child: Center(
            child: Text(
              hasTasks
                  ? context.l10n.homeNoTasksFound
                  : context.l10n.homeNoTasksYet,
              style: TextStyle(color: colors.textMuted),
            ),
          ),
        ),
      ];
    }

    return [
      if (overdue.isNotEmpty)
        SliverMainAxisGroup(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: DefaultStickyHeaderDelegate(
                maxHeight: 30,
                minHeight: 30,
                child: AppSectionHeader(
                  title: Text(context.l10n.homeSectionOverdue),
                  subTitle: Text(overdue.length.toString()),
                  backgroundColor: colors.bg.withValues(alpha: 0.8),
                ),
              ),
            ),
            _TaskSliver(
              tasks: overdue,
              onTap: (task) => context.push('/app-detail', extra: task.id),
              onComplete: (task) => _showCompleteSheet(context, task),
            ),
          ],
        ),
      if (upcoming.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.only(top: 16),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: DefaultStickyHeaderDelegate(
                  maxHeight: 30,
                  minHeight: 30,
                  child: AppSectionHeader(
                    title: Text(context.l10n.homeSectionUpcoming),
                    subTitle: Text(upcoming.length.toString()),
                    backgroundColor: colors.bg.withValues(alpha: 0.8),
                  ),
                ),
              ),
              _TaskSliver(
                tasks: upcoming,
                onTap: (task) => context.push('/app-detail', extra: task.id),
                onComplete: (task) => _showCompleteSheet(context, task),
              ),
            ],
          ),
        ),
    ];
  }
}

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 48,
      actions: [
        AppIconButton(onTap: () => context.push('/editor'), icon: Icons.add),
        AppIconButton(onTap: () {}, icon: Icons.settings_outlined),
      ],
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({required this.uiState, required this.onFilterChanged});

  final HomeUiState uiState;
  final void Function(HomeFilter) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final taskCount = uiState.taskCount;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Row(
        children: [
          AppFilterChip(
            label: context.l10n.homeFilterAll,
            isSelected: uiState.selectedFilter == HomeFilter.all,
            onTap: () => onFilterChanged(HomeFilter.all),
            count: taskCount.all,
          ),
          const SizedBox(width: 6),
          AppFilterChip(
            label: context.l10n.homeFilterToday,
            isSelected: uiState.selectedFilter == HomeFilter.today,
            onTap: () => onFilterChanged(HomeFilter.today),
            count: taskCount.today,
          ),
          const SizedBox(width: 6),
          AppFilterChip(
            label: context.l10n.homeFilterWeek,
            isSelected: uiState.selectedFilter == HomeFilter.week,
            onTap: () => onFilterChanged(HomeFilter.week),
            count: taskCount.week,
          ),
          const SizedBox(width: 6),
          AppFilterChip(
            label: context.l10n.homeFilterIrregular,
            isSelected: uiState.selectedFilter == HomeFilter.irregular,
            onTap: () => onFilterChanged(HomeFilter.irregular),
            count: taskCount.irregular,
          ),
        ],
      ),
    );
  }
}

class _TaskSliver extends StatelessWidget {
  const _TaskSliver({
    required this.tasks,
    required this.onTap,
    required this.onComplete,
  });

  final List<TaskItem> tasks;
  final void Function(TaskItem) onTap;
  final void Function(TaskItem) onComplete;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => TaskListItem(
            task: tasks[index],
            onTap: () => onTap(tasks[index]),
            onComplete: () => onComplete(tasks[index]),
          ),
          childCount: tasks.length,
        ),
      ),
    );
  }
}
