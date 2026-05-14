import 'package:dawnbreaker/data/preferences/preference_key.dart';
import 'package:dawnbreaker/data/preferences/preferences_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePreferencesManager extends PreferencesManager {
  FakePreferencesManager._(SharedPreferences prefs, {this.shouldThrow = false})
    : super(preferences: prefs);

  bool shouldThrow;

  static Future<FakePreferencesManager> create({
    Map<String, Object> mockValues = const {},
    bool shouldThrow = false,
  }) async {
    SharedPreferences.setMockInitialValues(mockValues);
    return FakePreferencesManager._(
      await SharedPreferences.getInstance(),
      shouldThrow: shouldThrow,
    );
  }

  @override
  Future<void> set<T>(PreferenceKey<T> key, T value) {
    if (shouldThrow) throw Exception('storage error');
    return super.set(key, value);
  }
}
