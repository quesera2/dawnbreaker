import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_type.dart';
import 'package:dawnbreaker/ui/common/components/app_app_bar.dart';
import 'package:dawnbreaker/ui/common/components/app_button.dart';
import 'package:dawnbreaker/ui/common/components/app_input.dart';
import 'package:dawnbreaker/ui/common/components/app_task_icon_tile.dart';
import 'package:dawnbreaker/ui/common/messages_mixin.dart';
import 'package:dawnbreaker/ui/editor/viewmodel/editor_ui_state.dart';
import 'package:dawnbreaker/ui/editor/viewmodel/editor_view_model.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

extension _ScheduleUnitLabel on ScheduleUnit {
  String label(BuildContext context) => switch (this) {
    ScheduleUnit.day => context.l10n.editorSpanDay,
    ScheduleUnit.week => context.l10n.editorSpanWeek,
    ScheduleUnit.month => context.l10n.editorSpanMonth,
  };
}

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, this.taskId});

  final int? taskId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen>
    with MessagesListenMixin<EditorScreen> {
  late final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(editorViewModelProvider(taskId: widget.taskId));
      _nameController.text = state.name;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = editorViewModelProvider(taskId: widget.taskId);
    listenMessages(provider);

    ref.listen(provider.select((s) => s.isSaved), (_, isSaved) {
      if (isSaved == true) context.pop();
    });

    final uiState = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);
    final isNew = widget.taskId == null;

    return Stack(
      children: [
        Scaffold(
          appBar: AppAppBar(
            title: isNew
                ? context.l10n.editorTitleNew
                : context.l10n.editorTitleEdit,
          ),
          body: uiState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _EditorBody(
                  uiState: uiState,
                  viewModel: viewModel,
                  nameController: _nameController,
                ),
          bottomNavigationBar: _SaveBar(
            enabled: uiState.canSave && !uiState.isLoading && !uiState.isSaving,
            isNew: isNew,
            onSave: viewModel.save,
          ),
        ),
        IgnorePointer(
          ignoring: !uiState.isSaving,
          child: AnimatedOpacity(
            opacity: uiState.isSaving ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: ColoredBox(
              color: context.appColorScheme.overlay,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorBody extends StatelessWidget {
  const _EditorBody({
    required this.uiState,
    required this.viewModel,
    required this.nameController,
  });

  final EditorUiState uiState;
  final EditorViewModel viewModel;
  final TextEditingController nameController;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, padding.bottom + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._basicInfoSection(context),
          const SizedBox(height: 24),
          ..._taskTypeSection(context),
        ],
      ),
    );
  }

  List<Widget> _basicInfoSection(BuildContext context) {
    var appColorScheme = context.appColorScheme;
    return [
      _SectionHeader(context.l10n.editorSectionBasic),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: appColorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: appColorScheme.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconArea(
              icon: uiState.icon,
              color: uiState.color,
              onChanged: viewModel.updateIcon,
            ),
            const SizedBox(height: 16),
            AppTextInput(
              hintText: context.l10n.editorNameHint,
              controller: nameController,
              onChanged: viewModel.updateName,
            ),
            const SizedBox(height: 16),
            // 色選択
            Text(
              context.l10n.editorLabelColor,
              style: AppTextStyle.caption.copyWith(
                color: appColorScheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _ColorPicker(
              selected: uiState.color,
              onChanged: viewModel.updateColor,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.editorColorNote,
              style: AppTextStyle.caption.copyWith(
                color: appColorScheme.textSubtle,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _taskTypeSection(BuildContext context) {
    return [
      _SectionHeader(context.l10n.editorLabelType),
      const SizedBox(height: 8),
      _TypeSelector(
        selected: uiState.type,
        onChanged: viewModel.updateType,
        scheduleValue: uiState.scheduleValue,
        scheduleUnit: uiState.scheduleUnit,
        onScheduleValueChanged: viewModel.updateScheduleValue,
        onScheduleUnitChanged: viewModel.updateScheduleUnit,
      ),
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: AppTextStyle.caption.copyWith(
          color: c.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IconArea extends StatelessWidget {
  const _IconArea({
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  final String icon;
  final TaskColor color;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppTaskIconTile(emoji: icon, color: color, size: 64),
        const SizedBox(width: 16),
        AppButton(
          label: context.l10n.editorChangeIcon,
          variant: AppButtonVariant.secondary,
          onPressed: () => _showEmojiPicker(context),
        ),
      ],
    );
  }

  Future<void> _showEmojiPicker(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => EmojiPicker(
        onEmojiSelected: (_, emoji) {
          onChanged(emoji.emoji);
          Navigator.of(ctx).pop();
        },
        config: Config(
          height: 256,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            backgroundColor: colorScheme.surfaceContainerLow,
            columns: 8,
            emojiSizeMax: 40,
            gridPadding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          ),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: colorScheme.surfaceContainerLow,
            iconColor: colorScheme.onSurfaceVariant,
            iconColorSelected: colorScheme.primary,
            indicatorColor: colorScheme.primary,
            backspaceColor: colorScheme.onSurfaceVariant,
            dividerColor: colorScheme.outlineVariant,
          ),
          bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.selected,
    required this.onChanged,
    required this.scheduleValue,
    required this.scheduleUnit,
    required this.onScheduleValueChanged,
    required this.onScheduleUnitChanged,
  });

  final TaskType selected;
  final ValueChanged<TaskType> onChanged;
  final int scheduleValue;
  final ScheduleUnit scheduleUnit;
  final ValueChanged<int> onScheduleValueChanged;
  final ValueChanged<ScheduleUnit> onScheduleUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TypeCard(
          title: context.l10n.editorTypeIrregular,
          description: context.l10n.editorTypeIrregularDesc,
          icon: Icons.event_busy_outlined,
          isSelected: selected == TaskType.irregular,
          onTap: () => onChanged(TaskType.irregular),
        ),
        const SizedBox(height: 8),
        _TypeCard(
          title: context.l10n.editorTypePeriod,
          description: context.l10n.editorTypePeriodDesc,
          icon: Icons.auto_graph_outlined,
          isSelected: selected == TaskType.period,
          onTap: () => onChanged(TaskType.period),
        ),
        const SizedBox(height: 8),
        _TypeCard(
          title: context.l10n.editorTypeScheduled,
          description: context.l10n.editorTypeScheduledDesc,
          icon: Icons.repeat_outlined,
          isSelected: selected == TaskType.scheduled,
          onTap: () => onChanged(TaskType.scheduled),
          expandedChild: _SpanPickerButton(
            value: scheduleValue,
            unit: scheduleUnit,
            onValueChanged: onScheduleValueChanged,
            onUnitChanged: onScheduleUnitChanged,
          ),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.expandedChild,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? expandedChild;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    final bgColor = isSelected ? c.primarySoft : c.surface;
    final borderColor = isSelected ? c.primary : c.border;
    final titleColor = isSelected ? c.primary : c.text;
    final descColor = isSelected ? c.primary.withAlpha(180) : c.textMuted;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      label: title,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: InkWell(
          onTap: isSelected ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TypeIconContainer(icon: icon, isSelected: isSelected),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyle.headline.copyWith(
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: AppTextStyle.caption.copyWith(
                              color: descColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RadioIndicator(isSelected: isSelected),
                  ],
                ),
                if (expandedChild != null)
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOut,
                          child: isSelected
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: expandedChild!,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeIconContainer extends StatelessWidget {
  const _TypeIconContainer({required this.icon, required this.isSelected});

  final IconData icon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isSelected ? c.primary : c.bgSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(
        icon,
        size: 22,
        color: isSelected ? c.primaryOn : c.textMuted,
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? c.primary : Colors.transparent,
        border: isSelected ? null : Border.all(color: c.borderStrong, width: 2),
      ),
      child: isSelected
          ? Icon(Icons.check, size: 14, color: c.primaryOn)
          : null,
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onChanged});

  final TaskColor selected;
  final ValueChanged<TaskColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: TaskColor.values.map((c) {
        return _ColorChip(
          taskColor: c,
          isSelected: c == selected,
          onTap: () => onChanged(c),
        );
      }).toList(),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.taskColor,
    required this.isSelected,
    required this.onTap,
  });

  final TaskColor taskColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayColor = taskColor.baseColor(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: displayColor,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: taskColor.onColor(context).withAlpha(80), width: 3)
              : Border.all(color: taskColor.softColor(context).withAlpha(80), width: 1),
          boxShadow: isSelected
              ? [BoxShadow(color: taskColor.onColor(context).withAlpha(80), blurRadius: 6)]
              : null,
        ),
        child: isSelected
            ? Icon(Icons.check_rounded, size: 24, color: taskColor.softColor(context))
            : null,
      ),
    );
  }
}

class _SpanPickerButton extends StatelessWidget {
  const _SpanPickerButton({
    required this.value,
    required this.unit,
    required this.onValueChanged,
    required this.onUnitChanged,
  });

  final int value;
  final ScheduleUnit unit;
  final ValueChanged<int> onValueChanged;
  final ValueChanged<ScheduleUnit> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    final label = context.l10n.editorSpanLabel('$value', unit.label(context));
    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: c.borderStrong),
        ),
        child: Row(
          children: [
            Text(label, style: AppTextStyle.headline.copyWith(color: c.text)),
            const Spacer(),
            Icon(Icons.arrow_drop_down, color: c.textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final result = await showModalBottomSheet<({int value, ScheduleUnit unit})>(
      context: context,
      builder: (_) => _SpanPickerSheet(initialValue: value, initialUnit: unit),
    );
    if (result != null) {
      onValueChanged(result.value);
      onUnitChanged(result.unit);
    }
  }
}

class _SpanPickerSheet extends StatefulWidget {
  const _SpanPickerSheet({
    required this.initialValue,
    required this.initialUnit,
  });

  final int initialValue;
  final ScheduleUnit initialUnit;

  @override
  State<_SpanPickerSheet> createState() => _SpanPickerSheetState();
}

class _SpanPickerSheetState extends State<_SpanPickerSheet> {
  static const _maxValue = 99;
  static const _itemExtent = 52.0;
  static const _wheelHeight = 200.0;

  late int _value;
  late ScheduleUnit _unit;
  late final FixedExtentScrollController _valueController;
  late final FixedExtentScrollController _unitController;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _unit = widget.initialUnit;
    _valueController = FixedExtentScrollController(
      initialItem: widget.initialValue - 1,
    );
    _unitController = FixedExtentScrollController(
      initialItem: ScheduleUnit.values.indexOf(widget.initialUnit),
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  TextStyle? _wheelTextStyle(ColorScheme colorScheme, bool isSelected) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(
      color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
    );
  }

  Positioned _fadeEdge({required Color color, required bool top}) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: top ? Alignment.topCenter : Alignment.bottomCenter,
              end: top ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [color, color.withAlpha(0)],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final surfaceColor = colorScheme.surfaceContainerLow;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: _wheelHeight,
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ListWheelScrollView.useDelegate(
                        controller: _valueController,
                        itemExtent: _itemExtent,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (i) =>
                            setState(() => _value = i + 1),
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: _maxValue,
                          builder: (context, i) {
                            final v = i + 1;
                            return Center(
                              child: Text(
                                '$v',
                                style: _wheelTextStyle(
                                  colorScheme,
                                  v == _value,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: ListWheelScrollView(
                        controller: _unitController,
                        itemExtent: _itemExtent,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (i) =>
                            setState(() => _unit = ScheduleUnit.values[i]),
                        children: ScheduleUnit.values.map((u) {
                          return Center(
                            child: Text(
                              u.label(context),
                              style: _wheelTextStyle(colorScheme, u == _unit),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: (_wheelHeight - _itemExtent) / 2,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: _itemExtent,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withAlpha(80),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                _fadeEdge(color: surfaceColor, top: true),
                _fadeEdge(color: surfaceColor, top: false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: context.l10n.ok,
            onPressed: () =>
                Navigator.of(context).pop((value: _value, unit: _unit)),
            fullWidth: true,
            size: AppButtonSize.large,
          ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.enabled,
    required this.isNew,
    required this.onSave,
  });

  final bool enabled;
  final bool isNew;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final c = context.appColorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: AppButton(
        label: isNew ? context.l10n.editorSaveNew : context.l10n.editorSaveEdit,
        onPressed: enabled ? onSave : null,
        fullWidth: true,
        size: AppButtonSize.large,
      ),
    );
  }
}
