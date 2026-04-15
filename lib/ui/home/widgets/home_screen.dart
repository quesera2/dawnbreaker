import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_ui_state.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_view_model.dart';
import 'package:dawnbreaker/ui/home/widgets/task_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('タスク')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            if (uiState.hasTasks)
              _SearchBar(
                controller: _searchController,
                showClear: uiState.searchQuery.isNotEmpty,
                onChanged: viewModel.updateSearchQuery,
                onClear: () {
                  _searchController.clear();
                  viewModel.updateSearchQuery('');
                },
              ),
            Expanded(child: _bodyWidget(uiState)),
          ],
        ),
      ),
    );
  }

  Widget _bodyWidget(HomeUiState uiState) {
    if (uiState.isLoading) {
      return const _LoadingView();
    }
    if (!uiState.hasTasks) {
      return const _EmptyView(message: 'タスクがまだありません');
    }
    final filtered = uiState.filteredTasks;
    if (filtered.isEmpty) {
      return const _EmptyView(message: '一致するタスクが見つかりません');
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'タスクを検索',
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
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 8 + bottomPadding),
      itemCount: tasks.length,
      itemBuilder: (context, index) => TaskListItem(task: tasks[index]),
    );
  }
}
