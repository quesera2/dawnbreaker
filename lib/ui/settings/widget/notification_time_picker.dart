import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/ui/common/components/app_button.dart';
import 'package:dawnbreaker/ui/common/components/app_wheel_picker.dart';
import 'package:flutter/material.dart';

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
            context.l10n.settingsNotificationTimePickerTitle,
            style: AppTextStyle.headline,
          ),
          const SizedBox(height: 16),
          AppWheelPicker(
            children: [
              WheelColumn<int>(
                items: _dayOffsets,
                selected: _dayOffset,
                controller: _dayController,
                flex: 3,
                labelOf: (offset) => offset == 0
                    ? context.l10n.settingsNotificationTimeSameDay
                    : context.l10n.settingsNotificationTimePrevDay,
                onChanged: (offset) => setState(() => _dayOffset = offset),
              ),
              WheelIntColumn(
                count: 24,
                selected: _hour,
                controller: _hourController,
                flex: 2,
                labelOf: (i) => i.toString().padLeft(2, '0'),
                onChanged: (i) => setState(() => _hour = i),
              ),
              WheelIntColumn(
                count: 60,
                selected: _minute,
                controller: _minuteController,
                flex: 2,
                labelOf: (i) => i.toString().padLeft(2, '0'),
                onChanged: (i) => setState(() => _minute = i),
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
