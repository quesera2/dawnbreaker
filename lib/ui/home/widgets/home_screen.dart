import 'package:dawnbreaker/ui/home/viewmodel/home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(homeViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dawnbreaker'),
      ),
      body: uiState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : const Center(
              child: Text('Home'),
            ),
    );
  }
}
