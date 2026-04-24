import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/core/date_util.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/common/components/app_button.dart';
import 'package:dawnbreaker/ui/common/components/app_task_icon_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class TaskCompleteSheet extends StatefulWidget {
  const TaskCompleteSheet({
    super.key,
    required this.task,
    required this.onConfirm,
  });

  final TaskItem task;
  final void Function(DateTime date) onConfirm;

  @override
  State<TaskCompleteSheet> createState() => _TaskCompleteSheetState();
}

class _TaskCompleteSheetState extends State<TaskCompleteSheet> {
  DateTime _selectedDate = DateTime.now().truncateTime;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _titleArea,
          const SizedBox(height: 20),
          _calendar,
          const SizedBox(height: 16),
          _buttonArea,
        ],
      ),
    );
  }

  Widget get _titleArea {
    final c = context.appColorScheme;
    return Row(
      children: [
        AppTaskIconTile(
          emoji: widget.task.icon,
          color: widget.task.color,
          size: 40,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.homeCompleteSheetTitle,
              style: AppTextStyle.caption.copyWith(color: c.textMuted),
            ),
            Text(
              widget.task.name,
              style: AppTextStyle.title2.copyWith(color: c.text),
            ),
          ],
        ),
      ],
    );
  }

  Widget get _calendar {
    final c = context.appColorScheme;
    return Container(
      height: 240,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.border),
      ),
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: _selectedDate,
        minimumDate: DateTime(2000),
        maximumDate: DateTime.now(),
        onDateTimeChanged: (date) {
          HapticFeedback.selectionClick();
          setState(() => _selectedDate = date);
        },
      ),
    );
  }

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
            label: context.l10n.homeCompleteRecord,
            size: AppButtonSize.large,
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              widget.onConfirm(_selectedDate);
            },
          ),
        ),
      ],
    );
  }
}
