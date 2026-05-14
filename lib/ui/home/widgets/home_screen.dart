import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/common/components/app_filter_chip.dart';
import 'package:dawnbreaker/ui/common/components/app_icon_button.dart';
import 'package:dawnbreaker/ui/common/components/app_input.dart';
import 'package:dawnbreaker/ui/common/components/app_section_header.dart';
import 'package:dawnbreaker/ui/common/components/app_task_list_item.dart';
import 'package:dawnbreaker/ui/common/default_sticky_header.dart';
import 'package:dawnbreaker/ui/common/messages_mixin.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_task_list.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_ui_state.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_view_model.dart';
import 'package:dawnbreaker/ui/home/widgets/task_complete_sheet.dart';
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
      return const Scaffold();
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
          ..._buildContentSlivers(
            context,
            uiState.hasTasks,
            taskList,
            viewModel,
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: 8 + MediaQuery.paddingOf(context).bottom,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContentSlivers(
    BuildContext context,
    bool hasTasks,
    HomeTaskList taskList,
    HomeViewModel viewModel,
  ) {
    if (taskList.isEmpty) {
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

    final entries = taskList.taskItemMap.entries.where(
      (e) => e.value.isNotEmpty,
    );

    return [
      for (final (index, entry) in entries.indexed)
        _buildSectionSliver(
          context,
          entry.key,
          entry.value,
          viewModel,
          addTopPadding: index > 0,
        ),
    ];
  }

  Widget _buildSectionSliver(
    BuildContext context,
    HomeTaskListType type,
    List<TaskItem> tasks,
    HomeViewModel viewModel, {
    required bool addTopPadding,
  }) {
    final colors = context.appColorScheme;
    final group = SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: DefaultStickyHeaderDelegate(
            maxHeight: 30,
            minHeight: 30,
            child: AppSectionHeader(
              title: Text(type.label(context)),
              subTitle: Text(tasks.length.toString()),
              backgroundColor: colors.bg.withValues(alpha: 0.8),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverImplicitlyAnimatedList<TaskItem>(
            items: tasks,
            areItemsTheSame: (a, b) => a.id == b.id,
            itemBuilder: (context, animation, item, index) =>
                SizeFadeTransition(
                  curve: Curves.easeInOut,
                  animation: animation,
                  child: AppTaskListItem(
                    task: item,
                    onTap: () => context.push('/app-detail/${item.id}'),
                    onComplete: () => TaskCompleteSheet.show(
                      context,
                      task: item,
                      onConfirm: (date, comment) =>
                          viewModel.recordExecution(item, date, comment),
                    ),
                  ),
                ),
          ),
        ),
      ],
    );

    if (addTopPadding) {
      return SliverPadding(
        padding: const EdgeInsets.only(top: 16),
        sliver: group,
      );
    }
    return group;
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
        AppIconButton(
          onTap: () => context.push('/home/new_task'),
          label: context.l10n.homeBarAdd,
          icon: Icons.add,
        ),
        AppIconButton(
          onTap: () => context.push('/settings'),
          label: context.l10n.homeBarSettings,
          icon: Icons.settings_outlined,
        ),
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

extension _HomeTaskListTypeLabel on HomeTaskListType {
  String label(BuildContext context) => switch (this) {
    HomeTaskListType.overdueTasks => context.l10n.homeSectionOverdue,
    HomeTaskListType.upcomingTasks => context.l10n.homeSectionUpcoming,
  };
}
