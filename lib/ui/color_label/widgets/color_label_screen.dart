import 'dart:async';

import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/ui/color_label/viewmodel/color_label_view_model.dart';
import 'package:dawnbreaker/ui/common/components/app_app_bar.dart';
import 'package:dawnbreaker/ui/common/components/app_icon_button.dart';
import 'package:dawnbreaker/ui/common/components/app_section_header.dart';
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

  void _initControllers(BuildContext context, List<ColorSetting> settings) {
    if (_controllersInitialized) return;
    _controllersInitialized = true;
    for (final setting in settings) {
      _controllers[setting.color]?.text = setting.alias.isNotEmpty
          ? setting.alias
          : setting.color.defaultLabel(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    _viewModel = ref.read(colorLabelViewModelProvider.notifier);
    final uiState = ref.watch(colorLabelViewModelProvider);

    if (!uiState.isLoading) {
      _initControllers(context, uiState.settings);
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
          : _ColorLabelBody(
              isSort: isSort,
              settings: uiState.settings,
              controllers: _controllers,
              onReorderItem: _viewModel.reorder,
              onChanged: _viewModel.updateAlias,
            ),
    );
  }
}

class _ColorLabelBody extends StatelessWidget {
  const _ColorLabelBody({
    required this.isSort,
    required this.settings,
    required this.controllers,
    required this.onReorderItem,
    required this.onChanged,
  });

  final bool isSort;
  final List<ColorSetting> settings;
  final Map<TaskColor, TextEditingController> controllers;
  final void Function(int, int) onReorderItem;
  final void Function(TaskColor, String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: isSort
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: AppSectionHeader(
            title: Text(context.l10n.colorLabelEditSectionTitle),
          ),
          secondChild: AppSectionHeader(
            title: Text(context.l10n.colorLabelSortSectionTitle),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: isSort
              ? _SortModeContent(
                  settings: settings,
                  onReorderItem: onReorderItem,
                )
              : _EditModeContent(
                  settings: settings,
                  controllers: controllers,
                  onChanged: onChanged,
                ),
        ),
      ],
    );
  }
}

class _EditModeContent extends StatelessWidget {
  const _EditModeContent({
    required this.settings,
    required this.controllers,
    required this.onChanged,
  });

  final List<ColorSetting> settings;
  final Map<TaskColor, TextEditingController> controllers;
  final void Function(TaskColor, String) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    final padding = MediaQuery.paddingOf(context);
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        DecoratedSliver(
          decoration: BoxDecoration(color: colors.surface),
          sliver: SliverList.separated(
            itemCount: settings.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final setting = settings[index];
              return ListTile(
                tileColor: colors.surface,
                leading: _ColorDot(color: setting.color),
                title: TextField(
                  controller: controllers[setting.color]!,
                  decoration: InputDecoration(
                    hintText: setting.color.defaultLabel(context),
                    hintStyle: TextStyle(color: colors.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (alias) => onChanged(setting.color, alias),
                ),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: Divider(height: 1)),
        SliverToBoxAdapter(
          child: ColoredBox(
            color: colors.bg,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, padding.bottom + 16),
              child: Text(
                context.l10n.colorLabelEditDescription,
                style: AppTextStyle.caption.copyWith(color: colors.textMuted),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SortModeContent extends StatefulWidget {
  const _SortModeContent({required this.settings, required this.onReorderItem});

  final List<ColorSetting> settings;
  final void Function(int, int) onReorderItem;

  @override
  State<_SortModeContent> createState() => _SortModeContentState();
}

class _SortModeContentState extends State<_SortModeContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<Offset> _handleSlide(int index) {
    final start = (index / widget.settings.length * 0.4).clamp(0.0, 1.0);
    final end = (start + 0.6).clamp(0.0, 1.0);
    return Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    final padding = MediaQuery.paddingOf(context);
    // CustomScrollView で単一スクロールコンテキストにまとめることで、
    // shrinkWrap + SingleChildScrollView の組み合わせによるジェスチャー競合を回避する
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        DecoratedSliver(
          decoration: BoxDecoration(color: colors.surface),
          sliver: SliverReorderableList(
            onReorderItem: widget.onReorderItem,
            proxyDecorator: (child, _, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (_, child) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withValues(
                            alpha: 0.2 * animation.value,
                          ),
                          blurRadius: 8 * animation.value,
                          offset: Offset(0, 3 * animation.value),
                        ),
                      ],
                    ),
                    child: Material(color: Colors.transparent, child: child!),
                  );
                },
                child: child,
              );
            },
            itemCount: widget.settings.length,
            itemBuilder: (context, index) {
              final setting = widget.settings[index];
              final label = setting.alias.isNotEmpty
                  ? setting.alias
                  : setting.color.defaultLabel(context);
              return Column(
                key: ValueKey(setting.color),
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: ListTile(
                      tileColor: colors.surface,
                      leading: _ColorDot(color: setting.color),
                      title: Text(label),
                      trailing: SlideTransition(
                        position: _handleSlide(index),
                        child: Icon(Icons.drag_handle, color: colors.textMuted),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                ],
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: ColoredBox(
            color: colors.bg,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, padding.bottom + 16),
              child: Text(
                context.l10n.colorLabelSortDescription,
                style: AppTextStyle.caption.copyWith(color: colors.textMuted),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final TaskColor color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
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
