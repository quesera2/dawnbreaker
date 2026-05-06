import 'package:dawnbreaker/ui/settings/viewmodel/settings_ui_state.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_view_model.g.dart';

@riverpod
class SettingsViewModel extends _$SettingsViewModel {
  @override
  SettingsUiState build() {
    _initialize();
    return const SettingsUiState();
  }

  Future<void> _initialize() async {
    final info = await PackageInfo.fromPlatform();
    if (!ref.mounted) return;
    state = state.copyWith(isLoading: false, version: info.version);
  }
}
