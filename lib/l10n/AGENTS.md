# lib/l10n

## ローカライズ

- Flutter 標準の `flutter gen-l10n` を使用（`l10n.yaml` で設定済み）
- ARB ファイル: `lib/l10n/app_ja.arb`（テンプレート）、`lib/l10n/app_en.arb`
- 生成ファイル（`lib/l10n/app_localizations*.dart`）はソースとしてコミット済み
- アクセスは `context.l10n.xxx`（`lib/core/util/context_extension.dart` の extension 経由）
- ARB キーの命名規則: **プレフィクスを必ずつける**
  - 画面固有の文言: `画面名Xxx`（例: `homeNoTasksYet`）
  - Repository エラー文言: `リポジトリ名ErrorXxx`（例: `taskErrorLoadFailed`）
  - 複数画面で使う汎用文言: `commonXxx`（例: `commonToday`、`commonOk`、`commonCancel`）
    - 「今日」「OK」「キャンセル」「再試行」「取り消し」などの汎用語もこのルールで命名する
