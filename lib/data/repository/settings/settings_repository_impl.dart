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
  ref.onDispose(repo.dispose);
  return repo;
}

@Riverpod(keepAlive: true)
Stream<bool> notificationEnabled(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watchNotificationEnabled();

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._manager);

  final PreferencesManager _manager;
  final _notificationEnabledController = StreamController<bool>.broadcast();
  final _homeSortModeController = StreamController<HomeDisplayMode>.broadcast();
  final _colorSettingsController =
      StreamController<List<ColorSetting>>.broadcast();

  @override
  Stream<bool> watchNotificationEnabled() async* {
    yield _manager.get(notificationEnabledKey, defaultValue: false);
    yield* _notificationEnabledController.stream;
  }

  @override
  Future<void> setNotificationEnabled(bool value) async {
    await _manager.set(notificationEnabledKey, value);
    _notificationEnabledController.add(value);
  }

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

  void dispose() {
    _notificationEnabledController.close();
    _homeSortModeController.close();
    _colorSettingsController.close();
  }
}
