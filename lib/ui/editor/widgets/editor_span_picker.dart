import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/data/model/schedule_unit.dart';
import 'package:dawnbreaker/ui/common/components/app_button.dart';
import 'package:dawnbreaker/ui/common/components/app_wheel_picker.dart';
import 'package:flutter/material.dart';

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
    final result = await showModalBottomSheet<SpanValue>(
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

  @override
  Widget build(BuildContext context) {
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
          AppWheelPicker(
            children: [
              WheelIntColumn(
                count: _maxValue,
                selected: _value - 1,
                controller: _valueController,
                flex: 2,
                labelOf: (i) => '${i + 1}',
                onChanged: (i) => setState(() => _value = i + 1),
              ),
              WheelColumn<ScheduleUnit>(
                items: ScheduleUnit.values,
                selected: _unit,
                controller: _unitController,
                flex: 3,
                labelOf: (u) => u.label(context),
                onChanged: (u) => setState(() => _unit = u),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppButton(
                  label: context.l10n.commonCancel,
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
                  label: context.l10n.commonOk,
                  size: AppButtonSize.large,
                  fullWidth: true,
                  onPressed: () =>
                      Navigator.of(context).pop((value: _value, unit: _unit)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
