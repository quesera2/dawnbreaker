import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/core/util/date_util.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/model/task_history.dart';
import 'package:dawnbreaker/ui/common/components/app_list_cell.dart';
import 'package:flutter/material.dart';

class AppDetailHistoryItem extends StatelessWidget {
  const AppDetailHistoryItem({
    super.key,
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.taskColor,
    required this.intervalDays,
    this.onTap,
  });

  final TaskHistory entry;
  final bool isFirst;
  final bool isLast;
  final TaskColor taskColor;
  final int? intervalDays;
  final VoidCallback? onTap;

  static const _dotSize = 10.0;
  static const _lineWidth = 1.5;
  static const _paddingH = 20.0;
  static const _paddingV = 14.0;
  static const _dotTopY = _paddingV + 4.0;
  static const _dotBottomY = _dotTopY + _dotSize;
  static const _lineLeft = _paddingH + _dotSize / 2 - _lineWidth / 2;

  AppListCellType get _type => switch ((isFirst, isLast)) {
    (true, true) => .single,
    (true, false) => .top,
    (false, true) => .bottom,
    _ => .middle,
  };

  BoxDecoration _dotDecoration(Color dotColor, Color surface) => isFirst
      ? BoxDecoration(color: dotColor, shape: BoxShape.circle)
      : BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: dotColor, width: _lineWidth),
          color: surface,
        );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    final dotColor = taskColor.baseColor(context);

    return AppListCell(
      type: _type,
      onTap: onTap,
      child: Stack(
        children: [
          if (!isFirst || !isLast)
            Positioned(
              left: _lineLeft,
              width: _lineWidth,
              top: isFirst ? _dotBottomY : 0,
              bottom: isLast ? null : 0,
              height: isLast ? _dotTopY : null,
              child: ColoredBox(color: colors.divider),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              _paddingH,
              _paddingV,
              _paddingH,
              entry.comment == null ? _paddingV : 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: _dotSize,
                      height: _dotSize,
                      decoration: _dotDecoration(dotColor, colors.surface),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.executedAt.localizedWithWeekday(context),
                        style: AppTextStyle.body.copyWith(
                          color: colors.text,
                          fontWeight: isFirst
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (intervalDays != null)
                      Text(
                        intervalDays! == 0
                            ? context.l10n.commonToday
                            : context.l10n.appDetailDaysInterval(intervalDays!),
                        style: AppTextStyle.caption.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                  ],
                ),
                if (entry.comment case final comment?)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: _dotSize + 12),
                    child: _HistoryComment(comment: comment),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryComment extends StatelessWidget {
  const _HistoryComment({required this.comment});

  final String comment;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          comment,
          style: AppTextStyle.caption.copyWith(color: colors.textSubtle),
        ),
      ),
    );
  }
}
