abstract interface class OnboardingRepository {
  Future<void> enableNotificationSettings();

  Future<void> saveCompletion();

  Future<void> removeCompletion();
}
