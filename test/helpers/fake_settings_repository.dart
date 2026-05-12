import 'package:dawnbreaker/data/repository/settings/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({bool initialNotificationEnabled = true})
    : _notificationEnabled = initialNotificationEnabled;

  bool _notificationEnabled;

  @override
  Stream<bool> watchNotificationEnabled() => Stream.value(_notificationEnabled);

  @override
  Future<void> setNotificationEnabled(bool value) async {
    _notificationEnabled = value;
  }
}
