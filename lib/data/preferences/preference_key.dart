class PreferenceKey<T> {
  const PreferenceKey(this.rawKey);

  final String rawKey;
}

const onboardingCompleteKey = PreferenceKey<bool>('onboarding_complete');
const notificationSettingKey = PreferenceKey<String>('notification_setting');
const homeSortModeKey = PreferenceKey<String>('home_sort_mode');
const colorSettingsKey = PreferenceKey<List<String>>('color_settings');
const progressBarAnimationKey = PreferenceKey<bool>('progress_bar_animation');
