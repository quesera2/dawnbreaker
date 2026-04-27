import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/core/date_util.dart';
import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/common/components/app_button.dart';
import 'package:dawnbreaker/ui/common/components/app_input.dart';
import 'package:dawnbreaker/ui/common/components/app_task_icon_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class TaskCompleteSheet extends StatefulWidget {
  const TaskCompleteSheet({
    super.key,
    required this.task,
    required this.onConfirm,
    this.initialDate,
    this.initialComment,
  });

  final TaskItem task;
  final void Function(DateTime date, String? comment) onConfirm;
  final DateTime? initialDate;
  final String? initialComment;

  @override
  State<TaskCompleteSheet> createState() => _TaskCompleteSheetState();
}

class _TaskCompleteSheetState extends State<TaskCompleteSheet> {
  late DateTime _selectedDate;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate =
        (widget.initialDate ?? DateTime.now()).truncateTime;
    if (widget.initialComment case final comment?) {
      _commentController.text = comment;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery
        .paddingOf(context)
        .bottom;
    final keyboardBottom = MediaQuery
        .viewInsetsOf(context)
        .bottom;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, 16 + safeBottom + keyboardBottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _titleArea,
            const SizedBox(height: 20),
            _calendar,
            const SizedBox(height: 16),
            _commentArea,
            const SizedBox(height: 16),
            _buttonArea,
          ],
        ),
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

  Widget get _commentArea =>
      AppTextInput(
        controller: _commentController,
        hintText: context.l10n.homeCompleteCommentPlaceholder,
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
            label: widget.initialDate != null
                ? context.l10n.editorSaveEdit
                : context.l10n.homeCompleteRecord,
            size: AppButtonSize.large,
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              final comment = _commentController.text.trim();
              widget.onConfirm(
                _selectedDate,
                comment.isEmpty ? null : comment,
              );
            },
          ),
        ),
      ],
    );
  }
}
