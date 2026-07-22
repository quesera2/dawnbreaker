import 'dart:async';

import 'package:dawnbreaker/data/model/notification_setting.dart';
import 'package:dawnbreaker/data/repository/user/user_settings_repository.dart';
import 'package:dawnbreaker/data/repository/user/user_settings_repository_exception.dart';

class FakeUserSettingsRepository implements UserSettingsRepository {
  FakeUserSettingsRepository({
    this.notificationSetting = const NotificationSetting(),
  });

  NotificationSetting notificationSetting;

  /// 読み取り時にエラーとするか
  bool fetchShouldThrow = false;

  /// 書き込み時にエラーとするか
  bool saveShouldThrow = false;

  /// Firestore がオフラインのとき、書き込みの Future はサーバーの応答待ちで完了しない
  bool neverCompletes = false;
  int updateLastActiveAtCount = 0;

  final _controller = StreamController<NotificationSetting>.broadcast();

  @override
  Stream<NotificationSetting> watchNotificationSetting() async* {
    yield notificationSetting;
    yield* _controller.stream;
  }

  @override
  Future<NotificationSetting> fetchNotificationSetting() async {
    if (fetchShouldThrow) throw const UserSettingsLoadException('テストエラー');
    return notificationSetting;
  }

  @override
  Future<void> setNotificationSetting(NotificationSetting setting) async {
    if (saveShouldThrow) throw const UserSettingsSaveException('テストエラー');
    if (neverCompletes) await Completer<void>().future;
    notificationSetting = setting;
    _controller.add(setting);
  }

  @override
  Future<void> setNotificationEnabled(bool enabled) async {
    if (saveShouldThrow) throw const UserSettingsSaveException('テストエラー');
    if (neverCompletes) await Completer<void>().future;
    notificationSetting = notificationSetting.copyWith(enabled: enabled);
    _controller.add(notificationSetting);
  }

  @override
  Future<void> updateLastActiveAt() async {
    if (saveShouldThrow) throw const UserSettingsSaveException('テストエラー');
    updateLastActiveAtCount++;
  }
}
