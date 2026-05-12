abstract interface class SettingsRepository {
  Stream<bool> watchNotificationEnabled();

  Future<void> setNotificationEnabled(bool value);
}
