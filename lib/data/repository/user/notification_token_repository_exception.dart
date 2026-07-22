sealed class NotificationTokenRepositoryException implements Exception {
  const NotificationTokenRepositoryException([this.message]);

  final String? message;

  @override
  String toString() => message ?? runtimeType.toString();
}

class NotificationTokenNotSignedInException
    extends NotificationTokenRepositoryException {
  const NotificationTokenNotSignedInException([super.message]);
}
