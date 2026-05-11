import 'package:flutter/widgets.dart';

abstract interface class NotificationService {
  Future<void> initialize();

  Future<void> setupChannels(BuildContext context);

  Future<void> requestPermission();
}
