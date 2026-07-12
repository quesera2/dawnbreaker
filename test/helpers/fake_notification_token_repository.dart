import 'package:dawnbreaker/data/repository/user/notification_token_repository.dart';

class FakeNotificationTokenRepository implements NotificationTokenRepository {
  final List<String> addedTokens = [];
  final List<String> removedTokens = [];

  @override
  Future<void> addToken(String token) async => addedTokens.add(token);

  @override
  Future<void> removeToken(String token) async => removedTokens.add(token);
}
