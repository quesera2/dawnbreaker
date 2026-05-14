import 'dart:async';

import 'package:dawnbreaker/data/repository/settings/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({bool initialNotificationEnabled = true})
    : notificationEnabled = initialNotificationEnabled;

  bool notificationEnabled;
  final _controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> watchNotificationEnabled() async* {
    yield notificationEnabled;
    yield* _controller.stream;
  }

  @override
  Future<void> setNotificationEnabled(bool value) async {
    notificationEnabled = value;
    _controller.add(value);
  }
}
