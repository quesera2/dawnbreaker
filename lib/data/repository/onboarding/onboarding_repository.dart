abstract interface class OnboardingRepository {
  bool isComplete();

  Future<void> complete();
}
