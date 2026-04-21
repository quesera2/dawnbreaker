import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/common/components/app_filter_chip.dart';
import 'package:dawnbreaker/ui/common/components/app_icon_button.dart';
import 'package:dawnbreaker/ui/common/components/app_search_input.dart';
import 'package:dawnbreaker/ui/common/error_dialog_mixin.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_ui_state.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_view_model.dart';
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
    with ErrorDialogMixin<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    listenError(homeViewModelProvider);
    final uiState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    if (uiState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final colorScheme = context.appColorScheme;

    return Scaffold(
      body: CustomScrollView(
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
          ..._buildContentSlivers(context, uiState),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: 8 + MediaQuery.paddingOf(context).bottom,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContentSlivers(BuildContext context, HomeUiState uiState) {
    final overdue = uiState.overdueTasks;
    final upcoming = uiState.upcomingTasks;

    if (overdue.isEmpty && upcoming.isEmpty) {
      final colors = context.appColorScheme;
      return [
        SliverFillRemaining(
          child: Center(
            child: Text(
              uiState.hasTasks
                  ? context.l10n.homeNoTasksFound
                  : context.l10n.homeNoTasksYet,
              style: TextStyle(color: colors.textMuted),
            ),
          ),
        ),
      ];
    }

    return [
      if (overdue.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: context.l10n.homeSectionOverdue,
            count: overdue.length,
          ),
        ),
        _TaskSliver(
          tasks: overdue,
          onTap: (task) => context.push('/editor', extra: task.id),
        ),
      ],
      if (upcoming.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: context.l10n.homeSectionUpcoming,
            count: upcoming.length,
          ),
        ),
        _TaskSliver(
          tasks: upcoming,
          onTap: (task) => context.push('/editor', extra: task.id),
        ),
      ],
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
      toolbarHeight: 44,
      actions: [
        AppIconButton(onTap: () => context.push('/editor'), icon: Icons.add),
        const SizedBox(width: 4),
        AppIconButton(onTap: (){}, icon: Icons.settings_outlined),
        const SizedBox(width: 4),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Row(
        children: [
          AppFilterChip(
            label: context.l10n.homeFilterAll,
            isSelected: uiState.selectedFilter == HomeFilter.all,
            onTap: () => onFilterChanged(HomeFilter.all),
            count: uiState.tasks.length,
          ),
          const SizedBox(width: 6),
          AppFilterChip(
            label: context.l10n.homeFilterOverdue,
            isSelected: uiState.selectedFilter == HomeFilter.overdue,
            onTap: () => onFilterChanged(HomeFilter.overdue),
            count: uiState.overdueCount,
          ),
          const SizedBox(width: 6),
          AppFilterChip(
            label: context.l10n.homeFilterToday,
            isSelected: uiState.selectedFilter == HomeFilter.today,
            onTap: () => onFilterChanged(HomeFilter.today),
            count: uiState.todayCount,
          ),
          const SizedBox(width: 6),
          AppFilterChip(
            label: context.l10n.homeFilterWeek,
            isSelected: uiState.selectedFilter == HomeFilter.week,
            onTap: () => onFilterChanged(HomeFilter.week),
            count: uiState.weekCount,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(fontSize: 11, color: colors.textSubtle),
          ),
        ],
      ),
    );
  }
}

class _TaskSliver extends StatelessWidget {
  const _TaskSliver({required this.tasks, required this.onTap});

  final List<TaskItem> tasks;
  final void Function(TaskItem) onTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => TaskListItem(
            task: tasks[index],
            onTap: () => onTap(tasks[index]),
            onComplete: () {},
          ),
          childCount: tasks.length,
        ),
      ),
    );
  }
}
