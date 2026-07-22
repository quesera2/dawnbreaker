sealed class UserRepositoryException implements Exception {
  const UserRepositoryException([this.message]);

  final String? message;

  @override
  String toString() => message ?? runtimeType.toString();
}

class SignInException extends UserRepositoryException {
  const SignInException([super.message]);
}
