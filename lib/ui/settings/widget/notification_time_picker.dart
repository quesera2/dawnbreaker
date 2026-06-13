import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/ui/common/components/app_button.dart';
import 'package:dawnbreaker/ui/common/components/app_wheel_picker.dart';
import 'package:flutter/material.dart';

typedef NotificationTime = ({NotifyDay notifyDay, int hour, int minute});

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
    final dayLabel = switch (setting.notifyDay) {
      NotifyDay.today => context.l10n.settingsNotificationTimeSameDay,
      NotifyDay.yesterday => context.l10n.settingsNotificationTimePrevDay,
    };
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
        initialNotifyDay: setting.notifyDay,
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
    required this.initialNotifyDay,
    required this.initialHour,
    required this.initialMinute,
  });

  final NotifyDay initialNotifyDay;
  final int initialHour;
  final int initialMinute;

  @override
  State<_NotificationTimePickerSheet> createState() =>
      _NotificationTimePickerSheetState();
}

class _NotificationTimePickerSheetState
    extends State<_NotificationTimePickerSheet> {
  late NotifyDay _notifyDay;
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _notifyDay = widget.initialNotifyDay;
    _hour = widget.initialHour;
    _minute = widget.initialMinute;
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
              WheelColumn<NotifyDay>(
                items: NotifyDay.values,
                initialSelected: _notifyDay,
                flex: 3,
                labelOf: (day) => switch (day) {
                  NotifyDay.today =>
                    context.l10n.settingsNotificationTimeSameDay,
                  NotifyDay.yesterday =>
                    context.l10n.settingsNotificationTimePrevDay,
                },
                onChanged: (day) => setState(() => _notifyDay = day),
              ),
              WheelColumn.integers(
                count: 24,
                initialSelected: _hour,
                flex: 2,
                labelOf: (i) => i.toString().padLeft(2, '0'),
                onChanged: (i) => setState(() => _hour = i),
              ),
              WheelColumn.integers(
                count: 60,
                initialSelected: _minute,
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
                  ).pop((notifyDay: _notifyDay, hour: _hour, minute: _minute)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
