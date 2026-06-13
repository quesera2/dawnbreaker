import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/ui/settings/viewmodel/settings_ui_state.dart';
import 'package:dawnbreaker/ui/common/components/app_app_bar.dart';
import 'package:dawnbreaker/ui/common/components/app_list_cell.dart';
import 'package:dawnbreaker/ui/common/components/app_section_header.dart';
import 'package:dawnbreaker/ui/common/messages_mixin.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_mode.dart';
import 'package:dawnbreaker/ui/settings/viewmodel/settings_view_model.dart';
import 'package:dawnbreaker/ui/settings/widget/notification_time_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with MessagesListenMixin<SettingsScreen> {
  late SettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(settingsViewModelProvider.notifier);
  }

  @override
  Widget build(BuildContext context) {
    listenMessages(settingsViewModelProvider);
    final viewState = ref.watch(settingsViewModelProvider);

    if (viewState.isLoading) {
      return const Scaffold();
    }

    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.settingsTitle,
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, padding.bottom + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._notificationSection(context, viewState: viewState),
            const SizedBox(height: 24),
            ..._displaySection(
              context,
              displayMode: viewState.displayMode,
              progressBarAnimationEnabled:
                  viewState.progressBarAnimationEnabled,
            ),
            const SizedBox(height: 24),
            ..._infoSection(context, viewState.version),
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              ..._debugSection(context, _viewModel),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _notificationSection(
    BuildContext context, {
    required SettingsUiState viewState,
  }) {
    final colorScheme = context.appColorScheme;
    final divider = Divider(height: 1, color: colorScheme.divider);
    final setting = viewState.notificationSetting;
    return [
      AppSectionHeader(
        title: Text(context.l10n.settingsSectionNotification),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      AppListCell(
        type: setting.enabled ? .top : .single,
        child: ListTile(
          title: Text(context.l10n.settingsNotificationTitle),
          trailing: Switch(
            value: setting.enabled,
            onChanged: viewState.isNotificationUpdating
                ? null
                : _viewModel.setNotificationEnabled,
          ),
        ),
      ),
      if (setting.enabled) ...[
        divider,
        AppListCell(
          type: .bottom,
          child: NotificationTimeTile(
            setting: setting,
            onChanged: (t) => _viewModel.setNotificationTime(
              dayOffset: t.dayOffset,
              hour: t.hour,
              minute: t.minute,
            ),
          ),
        ),
      ],
    ];
  }

  List<Widget> _displaySection(
    BuildContext context, {
    required HomeDisplayMode displayMode,
    required bool progressBarAnimationEnabled,
  }) {
    final colorScheme = context.appColorScheme;
    final divider = Divider(height: 1, color: colorScheme.divider);
    return [
      AppSectionHeader(
        title: Text(context.l10n.settingsSectionDisplay),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      AppListCell(
        type: .top,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(context.l10n.settingsDisplayType),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _displayModeLabel(context, displayMode),
                style: AppTextStyle.body.copyWith(color: colorScheme.textMuted),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.textMuted,
              ),
            ],
          ),
        ),
        onTap: () => context.push('/settings/display'),
      ),
      divider,
      AppListCell(
        type: .middle,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(context.l10n.settingsColorGroupTitle),
          subtitle: Text(context.l10n.settingsColorGroupSubtitle),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.textMuted,
          ),
        ),
        onTap: () => context.push('/settings/color-labels'),
      ),
      divider,
      AppListCell(
        type: .bottom,
        child: ListTile(
          title: Text(context.l10n.settingsDisplayProgressBarAnimation),
          trailing: Switch(
            value: progressBarAnimationEnabled,
            onChanged: _viewModel.setProgressBarAnimationEnabled,
          ),
        ),
      ),
    ];
  }

  String _displayModeLabel(BuildContext context, HomeDisplayMode mode) =>
      switch (mode) {
        .timeline => context.l10n.settingsDisplayHomeTimeline,
        .byColor => context.l10n.settingsDisplayHomeByColor,
      };

  List<Widget> _infoSection(BuildContext context, String version) {
    final colorScheme = context.appColorScheme;
    final divider = Divider(height: 1, color: colorScheme.divider);
    return [
      AppSectionHeader(
        title: Text(context.l10n.settingsSectionInfo),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      AppListCell(
        type: .top,
        child: ListTile(
          title: Text(context.l10n.settingsVersion),
          trailing: Text(version, style: AppTextStyle.caption),
        ),
      ),
      divider,
      AppListCell(
        type: .middle,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(context.l10n.settingsTutorial),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.textMuted,
          ),
        ),
        onTap: () =>
            context.push('/onboarding', extra: OnboardingMode.fromSettings),
      ),
      divider,
      AppListCell(
        type: .bottom,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(context.l10n.settingsLicense),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.textMuted,
          ),
        ),
        onTap: () => context.push('/settings/licenses'),
      ),
    ];
  }

  List<Widget> _debugSection(
    BuildContext context,
    SettingsViewModel viewModel,
  ) {
    final colorScheme = context.appColorScheme;
    final divider = Divider(height: 1, color: colorScheme.divider);
    return [
      AppSectionHeader(
        title: Text(context.l10n.settingsSectionDebug),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      AppListCell(
        type: .top,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(context.l10n.settingsDebugGenerateDummyTasks),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.textMuted,
          ),
        ),
        onTap: () => viewModel.generateDummyTasks(),
      ),
      divider,
      AppListCell(
        type: .middle,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(context.l10n.settingsDebugDeleteAllTasks),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.textMuted,
          ),
        ),
        onTap: () => viewModel.deleteAllTasks(),
      ),
      divider,
      AppListCell(
        type: .middle,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(context.l10n.settingsDebugResetTutorialFlag),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.textMuted,
          ),
        ),
        onTap: () => viewModel.deleteTutorialFlag(),
      ),
      divider,
      AppListCell(
        type: .middle,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(context.l10n.settingsDebugLogPendingNotifications),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.textMuted,
          ),
        ),
        onTap: () => viewModel.logPendingNotifications(),
      ),
      divider,
      AppListCell(
        type: .bottom,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(context.l10n.settingsDebugResetColorSettings),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.textMuted,
          ),
        ),
        onTap: () => viewModel.resetColorSettings(),
      ),
    ];
  }
}
