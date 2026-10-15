# lib/ui

## UI 実装

画面・ウィジェットを作成・変更する際は必ず `material-3` スキル（`.agents/skills/material-3/`）をロードしてから実装すること。
コンポーネントやトークンの仕様は `DESIGN.md` を参照すること。

## スナックバー通知

- `SnackBarMessage` のサブクラスを定義し、ViewModel で `state.copyWith(snackBarMessage: ...)` にセット
- 画面側は `MessagesListenMixin` を `with` して `build()` 内で `listenMessages(provider)` を呼ぶだけで自動表示
- `ScaffoldMessenger` は `MaterialApp` レベルで共有されるため、**画面ポップ直前にセットしてもポップ先の画面でスナックバーが表示される**（登録・更新成功メッセージ等に活用）
- `messages_mixin.dart` の `_snackText` / `_snackActionLabel` スイッチに新しい型を追加すること
- SnackBar に取り消しアクションを付ける場合は `handler` に処理を渡す

## エラーハンドリング

Repository 側の例外の定義の仕方はルートの AGENTS.md「エラー処理」を参照。ここでは受け取った側の扱いを決める。

- ViewModel は例外を `ErrorMessage` サブクラスに変換して UiState にセット（文字列不可）
  - 例外のメッセージは英語でログにしか出さないため、画面に出す文言は必ず ARB から取る
  - 再試行可能なエラーは `handler` に retry 処理を渡す
  - 再試行不可なエラー（`TaskNotFoundErrorMessage` 等）は `handler` なし
- UiState は `ErrorMessage? errorMessage` を `BaseUiState` 経由で保持
- エラーダイアログは `ErrorDialogMixin` を `with` して `build()` 内で `listenError(provider)` を呼ぶ
  - `handler` あり → 「キャンセル」「再試行」ボタン
  - `handler` なし → 「OK」ボタンのみ

## 文言

画面の文言は ARB から取る。ARB の扱いは `lib/l10n/AGENTS.md` を参照。
