import 'dart:async';

import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/data/repository/user/user_settings_repository.dart';

class FakeUserSettingsRepository implements UserSettingsRepository {
  FakeUserSettingsRepository({
    this.notificationSetting = const NotificationSetting(),
  });

  NotificationSetting notificationSetting;
  bool shouldThrow = false;
  int updateLastActiveAtCount = 0;

  final _controller = StreamController<NotificationSetting>.broadcast();

  @override
  Stream<NotificationSetting> watchNotificationSetting() async* {
    yield notificationSetting;
    yield* _controller.stream;
  }

  @override
  Future<void> setNotificationSetting(NotificationSetting setting) async {
    if (shouldThrow) throw Exception('failed to save notification setting');
    notificationSetting = setting;
    _controller.add(setting);
  }

  @override
  Future<void> updateLastActiveAt() async => updateLastActiveAtCount++;
}
