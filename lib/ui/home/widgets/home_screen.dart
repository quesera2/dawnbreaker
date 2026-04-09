import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/home/viewmodel/home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(homeViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dawnbreaker')),
      body: uiState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: uiState.tasks.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final task = uiState.tasks[index];
                return _TaskListItem(task: task);
              },
            ),
    );
  }
}

class _TaskListItem extends StatelessWidget {
  const _TaskListItem({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final scheduledAt = task.scheduledAt;
    final registered = _formatDate(task.registeredAt);
    final scheduled = scheduledAt != null ? _formatDate(scheduledAt) : null;

    return ListTile(
      title: Row(
        spacing: 4,
        children: [
          Text('●', style: TextStyle(color: task.color.color, fontSize: 16)),
          Text(task.name),
        ],
      ),
      subtitle: Row(
        spacing: 16,
        children: [
          Text('登録日：$registered'),
          if (scheduled != null) Text('予定日：$scheduled'),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
