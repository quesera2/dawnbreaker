import 'package:dawnbreaker/data/preferences/preference_key.dart';
import 'package:dawnbreaker/data/preferences/preferences_manager.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository.dart';
import 'package:dawnbreaker/data/repository/onboarding/onboarding_repository_exception.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_repository_impl.g.dart';

@riverpod
OnboardingRepository onboardingRepository(Ref ref) =>
    OnboardingRepositoryImpl(ref.watch(preferencesManagerProvider));

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._manager);

  final PreferencesManager _manager;

  @override
  Future<void> saveCompletion() async {
    try {
      await _manager.set(onboardingCompleteKey, true);
    } catch (e) {
      throw OnboardingSaveException(e.toString());
    }
  }

  @override
  Future<void> removeCompletion() async {
    try {
      await _manager.set(onboardingCompleteKey, false);
    } catch (e) {
      throw OnboardingSaveException(e.toString());
    }
  }
}
