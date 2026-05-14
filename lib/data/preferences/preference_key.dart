class PreferenceKey<T> {
  const PreferenceKey(this.rawKey);
  final String rawKey;
}

const onboardingCompleteKey = PreferenceKey<bool>('onboarding_complete');
const notificationEnabledKey = PreferenceKey<bool>('notification_enabled');
