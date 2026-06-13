import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/ui/common/components/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef NotificationTime = ({int dayOffset, int hour, int minute});

class NotificationTimeTile extends StatelessWidget {
  const NotificationTimeTile({
    super.key,
    required this.setting,
    required this.onChanged,
  });

  final NotificationSetting setting;
  final ValueChanged<NotificationTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    final dayLabel = setting.dayOffset == 0
        ? context.l10n.settingsNotificationTimeSameDay
        : context.l10n.settingsNotificationTimePrevDay;
    final timeLabel =
        '$dayLabel '
        '${setting.hour.toString().padLeft(2, '0')}:'
        '${setting.minute.toString().padLeft(2, '0')}';

    return ListTile(
      title: Text(context.l10n.settingsNotificationTime),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeLabel,
            style: AppTextStyle.body.copyWith(color: c.textMuted),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_ios, size: 16, color: c.textMuted),
        ],
      ),
      onTap: () => _showPicker(context),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final result = await showModalBottomSheet<NotificationTime>(
      context: context,
      showDragHandle: true,
      builder: (_) => _NotificationTimePickerSheet(
        initialDayOffset: setting.dayOffset,
        initialHour: setting.hour,
        initialMinute: setting.minute,
      ),
    );
    if (result != null) {
      onChanged(result);
    }
  }
}

class _NotificationTimePickerSheet extends StatefulWidget {
  const _NotificationTimePickerSheet({
    required this.initialDayOffset,
    required this.initialHour,
    required this.initialMinute,
  });

  final int initialDayOffset;
  final int initialHour;
  final int initialMinute;

  @override
  State<_NotificationTimePickerSheet> createState() =>
      _NotificationTimePickerSheetState();
}

class _NotificationTimePickerSheetState
    extends State<_NotificationTimePickerSheet> {
  static const _itemExtent = 52.0;
  static const _wheelHeight = 200.0;
  static const _dayOffsets = [0, -1];

  late int _dayOffset;
  late int _hour;
  late int _minute;
  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _dayOffset = widget.initialDayOffset;
    _hour = widget.initialHour;
    _minute = widget.initialMinute;
    _dayController = FixedExtentScrollController(
      initialItem: _dayOffsets.indexOf(widget.initialDayOffset),
    );
    _hourController = FixedExtentScrollController(
      initialItem: widget.initialHour,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: widget.initialMinute,
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  TextStyle _wheelTextStyle(AppColorScheme c, bool isSelected) =>
      AppTextStyle.headline.copyWith(color: isSelected ? c.text : c.textMuted);

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
            context.l10n.settingsNotificationTimePickerTitle,
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
                        flex: 3,
                        child: ListWheelScrollView(
                          controller: _dayController,
                          itemExtent: _itemExtent,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (i) {
                            HapticFeedback.selectionClick();
                            setState(() => _dayOffset = _dayOffsets[i]);
                          },
                          children: _dayOffsets.map((offset) {
                            final label = offset == 0
                                ? context.l10n.settingsNotificationTimeSameDay
                                : context.l10n.settingsNotificationTimePrevDay;
                            return Center(
                              child: Text(
                                label,
                                style: _wheelTextStyle(c, offset == _dayOffset),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: ListWheelScrollView.useDelegate(
                          controller: _hourController,
                          itemExtent: _itemExtent,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (i) {
                            HapticFeedback.selectionClick();
                            setState(() => _hour = i);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 24,
                            builder: (context, i) => Center(
                              child: Text(
                                i.toString().padLeft(2, '0'),
                                style: _wheelTextStyle(c, i == _hour),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: ListWheelScrollView.useDelegate(
                          controller: _minuteController,
                          itemExtent: _itemExtent,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (i) {
                            HapticFeedback.selectionClick();
                            setState(() => _minute = i);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 60,
                            builder: (context, i) => Center(
                              child: Text(
                                i.toString().padLeft(2, '0'),
                                style: _wheelTextStyle(c, i == _minute),
                              ),
                            ),
                          ),
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
                  onPressed: () => Navigator.of(
                    context,
                  ).pop((dayOffset: _dayOffset, hour: _hour, minute: _minute)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
