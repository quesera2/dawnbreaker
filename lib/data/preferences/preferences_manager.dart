import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_preferences_provider.dart';

part 'preferences_manager.g.dart';

@Riverpod(keepAlive: true)
PreferencesManager preferencesManager(Ref ref) =>
    PreferencesManager(preferences: ref.watch(sharedPreferencesProvider));

enum PreferenceKey {
  onboardingComplete('onboarding_complete'),
  notificationEnabled('notification_enabled');

  const PreferenceKey(this.rawKey);

  final String rawKey;
}

class PreferencesManager {
  const PreferencesManager({required SharedPreferences preferences})
    : _preferences = preferences;

  final SharedPreferences _preferences;

  bool getBool(PreferenceKey key, {bool defaultValue = false}) =>
      _preferences.getBool(key.rawKey) ?? defaultValue;

  Future<void> setBool(PreferenceKey key, {required bool value}) =>
      _preferences.setBool(key.rawKey, value);
}
