import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:dawnbreaker/data/repository/user/notification_token_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firestore_notification_token_repository.g.dart';

@riverpod
Future<NotificationTokenRepository> notificationTokenRepository(Ref ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return switch (user) {
    LocalUser() => NoopNotificationTokenRepository(),
    FirebaseAppUser(:final id) => FirestoreNotificationTokenRepository(
      userId: id,
      firestore: FirebaseFirestore.instance,
    ),
  };
}

class NoopNotificationTokenRepository implements NotificationTokenRepository {
  @override
  Future<void> addToken(String token) async {}

  @override
  Future<void> removeToken(String token) async {}
}

class FirestoreNotificationTokenRepository
    implements NotificationTokenRepository {
  FirestoreNotificationTokenRepository({
    required this.userId,
    required this._firestore,
  });

  final String userId;
  final FirebaseFirestore _firestore;

  @override
  Future<void> addToken(String token) =>
      _updateTokens(FieldValue.arrayUnion([token]));

  @override
  Future<void> removeToken(String token) =>
      _updateTokens(FieldValue.arrayRemove([token]));

  /// users ドキュメントはタスクの親として存在しないことがあるため、
  /// update ではなく merge 付きの set で書き込む
  Future<void> _updateTokens(FieldValue tokens) => _firestore
      .collection('users')
      .doc(userId)
      .set({'fcmTokens': tokens}, SetOptions(merge: true));
}
