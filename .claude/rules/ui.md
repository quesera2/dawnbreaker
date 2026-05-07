---
paths:
  - "lib/ui/**/*.dart"
  - "lib/l10n/**/*.arb"
---

## UI 実装

画面・ウィジェットを作成・変更する際は必ず `material-3-skill` をロードしてから実装すること。
コンポーネントやトークンの仕様は `DESIGN.md` を参照すること。

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

## スナックバー通知

- `SnackBarMessage` のサブクラスを定義し、ViewModel で `state.copyWith(snackBarMessage: ...)` にセット
- 画面側は `MessagesListenMixin` を `with` して `build()` 内で `listenMessages(provider)` を呼ぶだけで自動表示
- `ScaffoldMessenger` は `MaterialApp` レベルで共有されるため、**画面ポップ直前にセットしてもポップ先の画面でスナックバーが表示される**（登録・更新成功メッセージ等に活用）
- `messages_mixin.dart` の `_snackText` / `_snackActionLabel` スイッチに新しい型を追加すること
- SnackBar に取り消しアクションを付ける場合は `handler` に処理を渡す

## エラーハンドリング

- Repository の例外は `sealed class TaskRepositoryException` のサブクラスとして定義（`lib/data/repository/task/task_repository_exception.dart`）
- ViewModel は例外を `ErrorMessage` サブクラスに変換して UiState にセット（文字列不可）
  - 再試行可能なエラーは `handler` に retry 処理を渡す
  - 再試行不可なエラー（`TaskNotFoundErrorMessage` 等）は `handler` なし
- UiState は `ErrorMessage? errorMessage` を `BaseUiState` 経由で保持
- エラーダイアログは `ErrorDialogMixin` を `with` して `build()` 内で `listenError(provider)` を呼ぶ
  - `handler` あり → 「キャンセル」「再試行」ボタン
  - `handler` なし → 「OK」ボタンのみ