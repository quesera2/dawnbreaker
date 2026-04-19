import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/common/GlassAppBar.dart';
import 'package:dawnbreaker/ui/common/error_dialog_mixin.dart';
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
      return const Scaffold(body: _LoadingView());
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/editor'),
        child: const Icon(Icons.add),
      ),
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: _SearchBarField(
          controller: _searchController,
          showClear: uiState.searchQuery.isNotEmpty,
          onChanged: viewModel.updateSearchQuery,
          onClear: () {
            _searchController.clear();
            viewModel.updateSearchQuery('');
          },
        ),
        opacity: 0.20,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: _bodyWidget(context, uiState),
      ),
    );
  }

  Widget _bodyWidget(BuildContext context, dynamic uiState) {
    if (!uiState.hasTasks) {
      return _EmptyView(message: context.l10n.homeNoTasksYet);
    }
    final filtered = uiState.filteredTasks;
    if (filtered.isEmpty) {
      return _EmptyView(message: context.l10n.homeNoTasksFound);
    }
    return _TaskListView(tasks: filtered);
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _SearchBarField extends StatelessWidget {
  const _SearchBarField({
    required this.controller,
    required this.showClear,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool showClear;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(28);
    final baseBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide.none,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: context.l10n.homeSearchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: showClear
              ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
              : null,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: baseBorder,
          enabledBorder: baseBorder,
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _TaskListView extends StatelessWidget {
  const _TaskListView({required this.tasks});

  final List<TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return ListView.builder(
      padding: EdgeInsets.only(
        top: 8 + topPadding,
        bottom: 80 + 8 + bottomPadding,
      ),
      itemCount: tasks.length,
      itemBuilder: (context, index) => TaskListItem(task: tasks[index]),
    );
  }
}
