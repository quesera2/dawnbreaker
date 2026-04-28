import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_exception.dart';

class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository({this.shouldThrow = false});

  bool shouldThrow;

  @override
  Future<void> saveCompletion() async {
    if (shouldThrow) throw const OnboardingSaveException('テストエラー');
  }
}
