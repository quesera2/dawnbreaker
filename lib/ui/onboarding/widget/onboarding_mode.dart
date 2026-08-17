enum OnboardingMode {
  initial,
  fromSettings,

  /// 設定画面から削除を引き受けて開いた状態。表示は [initial] と同じで、
  /// 遷移し切ってからアカウントの削除を実行する
  executeAccountDeletion,
}
