abstract interface class OnboardingRepository {
  Future<void> saveCompletion();

  Future<void> removeCompletion();
}
