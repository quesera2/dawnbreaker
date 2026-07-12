import 'dart:async';

import 'package:dawnbreaker/data/model/color_setting.dart';
import 'package:dawnbreaker/data/model/home_display_mode.dart';
import 'package:dawnbreaker/data/preferences/preference_key.dart';
import 'package:dawnbreaker/data/preferences/preferences_manager.dart';
import 'package:dawnbreaker/data/repository/settings/settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_repository_impl.g.dart';

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  final manager = ref.watch(preferencesManagerProvider);
  final repo = SettingsRepositoryImpl(manager);
  ref.onDispose(() => unawaited(repo.dispose()));
  return repo;
}

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._manager);

  final PreferencesManager _manager;
  final _homeSortModeController = StreamController<HomeDisplayMode>.broadcast();
  final _colorSettingsController =
      StreamController<List<ColorSetting>>.broadcast();
  final _progressBarAnimationController = StreamController<bool>.broadcast();

  @override
  Stream<HomeDisplayMode> watchHomeDisplayMode() async* {
    yield HomeDisplayMode.fromString(
      _manager.get(homeSortModeKey, defaultValue: ''),
    );
    yield* _homeSortModeController.stream;
  }

  @override
  Future<void> setHomeDisplayMode(HomeDisplayMode value) async {
    await _manager.set(homeSortModeKey, value.rawKey);
    _homeSortModeController.add(value);
  }

  @override
  Stream<List<ColorSetting>> watchColorSettings() async* {
    final stored = _manager.get(
      colorSettingsKey,
      defaultValue: const <String>[],
    );
    yield ColorSetting.fromStringList(stored);
    yield* _colorSettingsController.stream;
  }

  @override
  Future<void> setColorSettings(List<ColorSetting> settings) async {
    await _manager.set(colorSettingsKey, ColorSetting.toStringList(settings));
    _colorSettingsController.add(settings);
  }

  @override
  Stream<bool> watchProgressBarAnimationEnabled() async* {
    yield _manager.get(progressBarAnimationKey, defaultValue: true);
    yield* _progressBarAnimationController.stream;
  }

  @override
  Future<void> setProgressBarAnimationEnabled(bool value) async {
    await _manager.set(progressBarAnimationKey, value);
    _progressBarAnimationController.add(value);
  }

  Future<void> dispose() async {
    await _homeSortModeController.close();
    await _colorSettingsController.close();
    await _progressBarAnimationController.close();
  }
}
