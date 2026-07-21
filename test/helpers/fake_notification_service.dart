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

  @override
  Future<bool> checkPermission() async {
    checkPermissionCalled = true;
    return checkPermissionResult;
  }

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalled = true;
    return permissionResult;
  }

  @override
  Future<void> registerToken() async => registerTokenCount++;
}
