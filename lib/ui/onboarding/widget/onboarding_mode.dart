enum OnboardingMode {
  initial,
  fromSettings,

  /// アカウントを消したあとに戻ってきた状態。表示は [initial] と同じで、
  /// 遷移し切ってから削除の後始末（サインアウト）を行う
  afterAccountDeletion,
}
