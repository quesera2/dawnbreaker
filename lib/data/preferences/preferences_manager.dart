import 'package:dawnbreaker/data/preferences/preference_key.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_preferences_provider.dart';

part 'preferences_manager.g.dart';

@Riverpod(keepAlive: true)
PreferencesManager preferencesManager(Ref ref) =>
    PreferencesManager(preferences: ref.watch(sharedPreferencesProvider));

class PreferenceKeyDefinition {}

class PreferencesManager {
  const PreferencesManager({required SharedPreferences preferences})
    : _preferences = preferences;

  final SharedPreferences _preferences;

  T get<T>(PreferenceKey<T> key, {required T defaultValue}) {
    final value = switch (T) {
      const (bool) => _preferences.getBool(key.rawKey) as T?,
      const (String) => _preferences.getString(key.rawKey) as T?,
      const (int) => _preferences.getInt(key.rawKey) as T?,
      _ => throw UnsupportedError('Unsupported type: $T'),
    };
    return value ?? defaultValue;
  }

  Future<void> set<T>(PreferenceKey<T> key, T value) {
    return switch (T) {
      const (bool) => _preferences.setBool(key.rawKey, value as bool),
      const (String) => _preferences.setString(key.rawKey, value as String),
      const (int) => _preferences.setInt(key.rawKey, value as int),
      _ => throw UnsupportedError('Unsupported type: $T'),
    };
  }
}
