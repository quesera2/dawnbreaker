sealed class OnboardingRepositoryException implements Exception {
  const OnboardingRepositoryException([this.message]);

  final String? message;

  @override
  String toString() => message ?? runtimeType.toString();
}

class OnboardingSaveException extends OnboardingRepositoryException {
  const OnboardingSaveException([super.message]);
}
