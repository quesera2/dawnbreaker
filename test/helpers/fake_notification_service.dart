import 'dart:async';

import 'package:dawnbreaker/core/notification/notification_service.dart';

class FakeNotificationService implements NotificationService {
  FakeNotificationService({
    this.checkPermissionResult = true,
    this.permissionResult = true,
  });

  bool checkPermissionResult;
  bool permissionResult;
  bool checkPermissionCalled = false;
  bool requestPermissionCalled = false;
  int registerTokenCount = 0;

  /// 通知の状態を問い合わせられない状況を作る
  bool checkPermissionShouldThrow = false;

  /// 通知先の登録が失敗する状況を作る
  bool registerTokenShouldThrow = false;

  /// Firestore がオフラインのとき、書き込みの Future はサーバーの応答待ちで完了しない
  bool registerTokenNeverCompletes = false;

  @override
  Future<bool> checkPermission() async {
    checkPermissionCalled = true;
    if (checkPermissionShouldThrow) throw Exception('テストエラー');
    return checkPermissionResult;
  }

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalled = true;
    return permissionResult;
  }

  @override
  Future<void> registerToken() async {
    registerTokenCount++;
    if (registerTokenShouldThrow) throw Exception('テストエラー');
    if (registerTokenNeverCompletes) await Completer<void>().future;
  }
}
