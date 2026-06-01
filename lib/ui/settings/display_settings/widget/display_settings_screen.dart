import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/ui/common/components/app_app_bar.dart';
import 'package:dawnbreaker/ui/common/components/app_list_cell.dart';
import 'package:dawnbreaker/ui/settings/display_settings/viewmodel/display_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DisplaySettingsScreen extends ConsumerWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(displaySettingsViewModelProvider);
    final viewModel = ref.read(displaySettingsViewModelProvider.notifier);

    final colorScheme = context.appColorScheme;
    final divider = Divider(height: 1, color: colorScheme.divider);
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.settingsSectionDisplay,
        onBack: () => context.pop(),
      ),
      body: viewState.isLoading
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, padding.bottom + 16),
              child: RadioGroup<HomeDisplayMode>(
                groupValue: viewState.displayMode!,
                onChanged: (v) => viewModel.setDisplayMode(v!),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppListCell(
                      type: .top,
                      child: RadioListTile<HomeDisplayMode>(
                        value: .timeline,
                        title: Text(context.l10n.settingsDisplayHomeTimeline),
                        subtitle: Text(
                          context.l10n.settingsDisplayHomeTimelineSubtitle,
                        ),
                      ),
                    ),
                    divider,
                    AppListCell(
                      type: .bottom,
                      child: RadioListTile<HomeDisplayMode>(
                        value: .byColor,
                        title: Text(context.l10n.settingsDisplayHomeByColor),
                        subtitle: Text(
                          context.l10n.settingsDisplayHomeByColorSubtitle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
