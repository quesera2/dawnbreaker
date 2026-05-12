import 'dart:async';

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
  final _controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> watchNotificationEnabled() async* {
    yield _manager.getBool(.notificationEnabled, defaultValue: true);
    yield* _controller.stream;
  }

  @override
  Future<void> setNotificationEnabled(bool value) async {
    await _manager.setBool(.notificationEnabled, value: value);
    _controller.add(value);
  }

  void dispose() => _controller.close();
}
