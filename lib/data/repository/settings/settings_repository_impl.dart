import 'dart:async';

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
  Stream<HomeDisplayMode> watchHomeSortType() async* {
    yield HomeDisplayMode.fromString(
      _manager.get(homeSortModeKey, defaultValue: ''),
    );
    yield* _homeSortModeController.stream;
  }

  @override
  Future<void> setHomeSortType(HomeDisplayMode value) async {
    await _manager.set(homeSortModeKey, value.rawKey);
    _homeSortModeController.add(value);
  }

  void dispose() {
    _notificationEnabledController.close();
    _homeSortModeController.close();
  }
}
