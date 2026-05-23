import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/ui/color_label/viewmodel/color_label_view_model.dart';
import 'package:dawnbreaker/ui/common/components/app_app_bar.dart';
import 'package:dawnbreaker/ui/common/components/app_icon_button.dart';
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
              onReorderItem: _viewModel.reorder,
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
      padding: EdgeInsets.only(bottom: padding.bottom),
      itemCount: settings.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final setting = settings[index];
        return ListTile(
          leading: _ColorDot(color: setting.color),
          title: TextField(
            controller: controllers[setting.color]!,
            decoration: InputDecoration(
              hintText: setting.color.defaultLabel(context),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (alias) => onChanged(setting.color, alias),
          ),
        );
      },
    );
  }
}

class _SortModeList extends StatelessWidget {
  const _SortModeList({required this.settings, required this.onReorderItem});

  final List<ColorSetting> settings;
  final void Function(int, int) onReorderItem;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final colors = context.appColorScheme;
    return ReorderableListView.builder(
      padding: EdgeInsets.only(bottom: padding.bottom),
      buildDefaultDragHandles: false,
      itemCount: settings.length,
      onReorderItem: onReorderItem,
      proxyDecorator: (child, _, _) =>
          Material(color: Colors.transparent, child: child),
      itemBuilder: (context, index) {
        final setting = settings[index];
        final label = setting.alias.isNotEmpty
            ? setting.alias
            : setting.color.defaultLabel(context);
        return Column(
          key: ValueKey(setting.color),
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: _ColorDot(color: setting.color),
              title: Text(label),
              trailing: ReorderableDragStartListener(
                index: index,
                child: Icon(Icons.drag_handle, color: colors.textMuted),
              ),
            ),
            const Divider(height: 1),
          ],
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
