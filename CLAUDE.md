# dawnbreaker

定期的なタスクを管理する Flutter アプリ（iOS / Android）。

## Flutter バージョン管理

**fvm を使用しているため、`flutter` コマンドは必ず `fvm flutter` に置き換えること。**

使用チャンネル: `stable`

## Tech Stack

- **Flutter** (fvm 管理)
- **状態管理**: Riverpod
- **モデル**: Freezed
- **ルーティング**: go_router
- **データ永続化** drift

## コード生成

モデルや ViewModel を変更したら必ず実行：

```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

## UI 実装                                                                                                                                                                                                                                              
                                                                                                          
画面・ウィジェットを作成・変更する際は必ず `material-3-skill` をロードしてから実装すること。   

## アーキテクチャ

```
lib/
  app/          # App ウィジェット、テーマ定義
  core/         # 汎用ユーティリティ（context_extension 等）
  data/
    model/      # Freezed モデル
    repository/ # Repository インターフェースと実装
  ui/
    common/     # BaseUiState, ErrorMessage, ErrorDialogMixin 等の共通クラス
    home/
      viewmodel/  # RiverpodViewModel, FreezedUiState
      widgets/    # Screen
```

- ViewModel は `@riverpod` アノテーションで生成
- UI State は `@freezed` で定義、`copyWith` で更新、`BaseUiState` を implements すること
- 画面のルートは `XXXPage` ではなく `XXXScreen`

## ローカライズ

- `context.l10n.xxx` でアクセス（`lib/core/context_extension.dart` の extension）
- ARB キーの命名規則: **プレフィクスを必ずつける**
  - 画面固有の文言: `画面名Xxx`（例: `homeNoTasksYet`）
  - Repository エラー文言: `リポジトリ名ErrorXxx`（例: `taskErrorLoadFailed`）

## エラーハンドリング

- Repository の例外は `sealed class TaskRepositoryException` のサブクラスとして定義（`lib/data/repository/task/task_repository_exception.dart`）
- ViewModel は例外を `ErrorMessage` サブクラスに変換して UiState にセット（文字列不可）
  - 再試行可能なエラーは `handler` に retry 処理を渡す
  - 再試行不可なエラー（`TaskNotFoundErrorMessage` 等）は `handler` なし
- UiState は `ErrorMessage? errorMessage` を `BaseUiState` 経由で保持
- エラーダイアログは `ErrorDialogMixin` を `with` して `build()` 内で `listenError(provider)` を呼ぶ
  - `handler` あり → 「キャンセル」「再試行」ボタン
  - `handler` なし → 「OK」ボタンのみ