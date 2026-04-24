import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/ui/common/components/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef SpanValue = ({int value, ScheduleUnit unit});

class SpanPickerButton extends StatelessWidget {
  const SpanPickerButton({
    super.key,
    required this.value,
    required this.unit,
    required this.onChanged,
  });

  final int value;
  final ScheduleUnit unit;
  final ValueChanged<SpanValue> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    final label = context.l10n.editorSpanLabel('$value', unit.label(context));
    return OutlinedButton(
      onPressed: () => _showPicker(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        backgroundColor: c.surface,
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        side: BorderSide(color: c.borderStrong),
        textStyle: AppTextStyle.headline.copyWith(fontWeight: FontWeight.w600),
      ),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Icon(Icons.arrow_drop_down, color: c.textMuted),
        ],
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final result = await showModalBottomSheet<({int value, ScheduleUnit unit})>(
      context: context,
      showDragHandle: true,
      builder: (_) => _SpanPickerSheet(initialValue: value, initialUnit: unit),
    );
    if (result != null) {
      onChanged(result);
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

  TextStyle _wheelTextStyle(AppColorScheme c, bool isSelected) {
    return AppTextStyle.headline.copyWith(
      color: isSelected ? c.text : c.textMuted,
    );
  }

  Positioned _topFadeEdge(Color color) => Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: IgnorePointer(
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, color.withAlpha(0)],
          ),
        ),
      ),
    ),
  );

  Positioned _bottomFadeEdge(Color color) => Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: IgnorePointer(
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [color, color.withAlpha(0)],
          ),
        ),
      ),
    ),
  );

  Widget get _buttonArea {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AppButton(
            label: context.l10n.cancel,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.large,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: AppButton(
            label: context.l10n.ok,
            size: AppButtonSize.large,
            fullWidth: true,
            onPressed: () =>
                Navigator.of(context).pop((value: _value, unit: _unit)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.editorSpanPickerTitle,
            style: AppTextStyle.headline,
          ),
          const SizedBox(height: 16),
          Container(
            height: _wheelHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.bgSubtle,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: c.border),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: (_wheelHeight - _itemExtent) / 2,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: _itemExtent,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: c.trackBg,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ListWheelScrollView.useDelegate(
                          controller: _valueController,
                          itemExtent: _itemExtent,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (i) {
                            HapticFeedback.selectionClick();
                            setState(() => _value = i + 1);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: _maxValue,
                            builder: (context, i) {
                              final v = i + 1;
                              return Center(
                                child: Text(
                                  '$v',
                                  style: _wheelTextStyle(c, v == _value),
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
                          onSelectedItemChanged: (i) {
                            HapticFeedback.selectionClick();
                            setState(() => _unit = ScheduleUnit.values[i]);
                          },
                          children: ScheduleUnit.values.map((u) {
                            return Center(
                              child: Text(
                                u.label(context),
                                style: _wheelTextStyle(c, u == _unit),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                _topFadeEdge(c.bgSubtle),
                _bottomFadeEdge(c.bgSubtle),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buttonArea,
        ],
      ),
    );
  }
}
