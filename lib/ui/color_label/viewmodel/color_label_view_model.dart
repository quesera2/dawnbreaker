import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository_impl.dart';
import 'package:dawnbreaker/ui/color_label/viewmodel/color_label_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'color_label_view_model.g.dart';

@riverpod
class ColorLabelViewModel extends _$ColorLabelViewModel {
  late SettingsRepository _repository;

  @override
  ColorLabelUiState build() {
    _repository = ref.read(settingsRepositoryProvider);
    _initialize();
    return const ColorLabelUiState();
  }

  Future<void> _initialize() async {
    final settings = await _repository.watchColorSettings().first;
    if (!ref.mounted) return;
    state = state.copyWith(isLoading: false, settings: settings);
  }

  void toggleMode() {
    state = state.copyWith(mode: state.mode == .edit ? .sort : .edit);
  }

  Future<void> updateAlias(TaskColor color, String alias) async {
    final updated = state.settings.map((s) {
      return s.color == color ? s.copyWith(alias: alias) : s;
    }).toList();
    state = state.copyWith(settings: updated);
    await _repository.setColorSettings(updated);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = List<ColorSetting>.from(state.settings);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    final reordered = [for (final (i, s) in list.indexed) s.copyWith(order: i)];
    state = state.copyWith(settings: reordered);
    await _repository.setColorSettings(reordered);
  }
}
