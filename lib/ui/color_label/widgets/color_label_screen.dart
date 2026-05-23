import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/ui/color_label/viewmodel/color_label_view_model.dart';
import 'package:dawnbreaker/ui/common/components/app_app_bar.dart';
import 'package:dawnbreaker/ui/common/components/app_icon_button.dart';
import 'package:dawnbreaker/ui/common/components/app_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ColorLabelScreen extends ConsumerStatefulWidget {
  const ColorLabelScreen({super.key});

  @override
  ConsumerState<ColorLabelScreen> createState() => _ColorLabelScreenState();
}

class _ColorLabelScreenState extends ConsumerState<ColorLabelScreen> {
  late ColorLabelViewModel _viewModel;
  final _controllers = <TaskColor, TextEditingController>{};
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    for (final color in TaskColor.values) {
      _controllers[color] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initControllers(List<ColorSetting> settings) {
    if (_controllersInitialized) return;
    _controllersInitialized = true;
    for (final setting in settings) {
      _controllers[setting.color]?.text = setting.alias;
    }
  }

  @override
  Widget build(BuildContext context) {
    _viewModel = ref.read(colorLabelViewModelProvider.notifier);
    final uiState = ref.watch(colorLabelViewModelProvider);

    if (!uiState.isLoading) {
      _initControllers(uiState.settings);
    }

    final isSort = uiState.mode == .sort;

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.colorLabelScreenTitle,
        onBack: () => context.pop(),
        actions: [
          if (!uiState.isLoading)
            AppIconButton(
              icon: isSort ? Icons.edit_outlined : Icons.swap_vert,
              label: isSort
                  ? context.l10n.colorLabelEditButton
                  : context.l10n.colorLabelSortButton,
              onTap: _viewModel.toggleMode,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: uiState.isLoading
          ? const SizedBox.shrink()
          : isSort
          ? _SortModeList(
              settings: uiState.settings,
              onReorder: _viewModel.reorder,
            )
          : _EditModeList(
              settings: uiState.settings,
              controllers: _controllers,
              onChanged: _viewModel.updateAlias,
            ),
    );
  }
}

class _EditModeList extends StatelessWidget {
  const _EditModeList({
    required this.settings,
    required this.controllers,
    required this.onChanged,
  });

  final List<ColorSetting> settings;
  final Map<TaskColor, TextEditingController> controllers;
  final void Function(TaskColor, String) onChanged;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 16, 20, padding.bottom + 16),
      itemCount: settings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final setting = settings[index];
        return _EditModeRow(
          setting: setting,
          controller: controllers[setting.color]!,
          onChanged: (alias) => onChanged(setting.color, alias),
        );
      },
    );
  }
}

class _EditModeRow extends StatelessWidget {
  const _EditModeRow({
    required this.setting,
    required this.controller,
    required this.onChanged,
  });

  final ColorSetting setting;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        _ColorDot(color: setting.color),
        Expanded(
          child: AppTextInput(
            controller: controller,
            hintText: setting.color.defaultLabel(context),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SortModeList extends StatelessWidget {
  const _SortModeList({required this.settings, required this.onReorder});

  final List<ColorSetting> settings;
  final void Function(int, int) onReorder;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final colors = context.appColorScheme;
    return ReorderableListView.builder(
      padding: EdgeInsets.fromLTRB(20, 16, 20, padding.bottom + 16),
      itemCount: settings.length,
      onReorder: onReorder,
      proxyDecorator: (child, _, __) =>
          Material(color: Colors.transparent, child: child),
      itemBuilder: (context, index) {
        final setting = settings[index];
        final label = setting.alias.isNotEmpty
            ? setting.alias
            : setting.color.defaultLabel(context);
        return Padding(
          key: ValueKey(setting.color),
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            spacing: 12,
            children: [
              _ColorDot(color: setting.color),
              Expanded(child: Text(label, style: AppTextStyle.body)),
              Icon(Icons.drag_handle, color: colors.textMuted),
            ],
          ),
        );
      },
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final TaskColor color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.baseColor(context),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}

extension _TaskColorDefaultLabel on TaskColor {
  String defaultLabel(BuildContext context) => switch (this) {
    .none => context.l10n.homeSectionColorNone,
    .red => context.l10n.homeSectionColorRed,
    .blue => context.l10n.homeSectionColorBlue,
    .yellow => context.l10n.homeSectionColorYellow,
    .green => context.l10n.homeSectionColorGreen,
    .orange => context.l10n.homeSectionColorOrange,
  };
}
