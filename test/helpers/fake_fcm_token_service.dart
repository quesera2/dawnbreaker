import 'package:dawnbreaker/core/notification/fcm_token_service.dart';

class FakeFcmTokenService implements FcmTokenService {
  int registerTokenCount = 0;

  @override
  Future<void> registerToken() async => registerTokenCount++;
}
