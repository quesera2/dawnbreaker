import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/ui/common/components/app_app_bar.dart';
import 'package:dawnbreaker/ui/common/components/app_list_cell.dart';
import 'package:dawnbreaker/ui/common/components/app_section_header.dart';
import 'package:dawnbreaker/ui/common/messages_mixin.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_mode.dart';
import 'package:dawnbreaker/ui/settings/viewmodel/settings_view_model.dart';
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
  @override
  Widget build(BuildContext context) {
    listenMessages(settingsViewModelProvider);
    final viewState = ref.watch(settingsViewModelProvider);
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
            ..._infoSection(context, viewState.version),
            if (kDebugMode) ..._debugSection(context),
          ],
        ),
      ),
    );
  }

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

  List<Widget> _debugSection(BuildContext context) {
    final colorScheme = context.appColorScheme;
    return [
      const SizedBox(height: 24),
      AppSectionHeader(
        title: Text(context.l10n.settingsSectionDebug),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      AppListCell(
        type: .single,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(context.l10n.settingsDebugGenerateDummyTasks),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.textMuted,
          ),
        ),
        onTap: () =>
            ref.read(settingsViewModelProvider.notifier).generateDummyTasks(),
      ),
    ];
  }
}
