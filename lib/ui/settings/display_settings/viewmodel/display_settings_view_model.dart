import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository_impl.dart'
    show settingsRepositoryProvider;
import 'package:dawnbreaker/ui/settings/display_settings/viewmodel/display_settings_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'display_settings_view_model.g.dart';

@riverpod
class DisplaySettingsViewModel extends _$DisplaySettingsViewModel {
  late SettingsRepository _repository;

  @override
  DisplaySettingsUiState build() {
    _repository = ref.read(settingsRepositoryProvider);
    final subscription = _repository.watchHomeDisplayMode().listen((mode) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, displayMode: mode);
    });
    ref.onDispose(subscription.cancel);
    return const DisplaySettingsUiState();
  }

  Future<void> setDisplayMode(HomeDisplayMode mode) async {
    await _repository.setHomeDisplayMode(mode);
  }
}
