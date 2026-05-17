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

## Dart スタイル

Dart 3.7 以降の構文を積極的に使う：

- **enum 省略記法**: 型が推論できる文脈では `EnumClass.value` でなく `.value` と書く
  ```dart
  // Good
  state.copyWith(destination: .home)
  switch (mode) { .initial => ..., .fromSettings => ... }
  if (mode == .initial)

  // Avoid
  state.copyWith(destination: OnboardingDestination.home)
  ```
- **ワイルドカード**: 使わない引数は `(_, _)` と書く（`__` は古い書き方）

## アーキテクチャ

```
lib/
  app/          # App ウィジェット、テーマ定義
  core/         # 汎用ユーティリティ
  generated/    # 生成コード（手動変更しない）
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

## PR 作成

- シンプルな内容にとどめる
- PR 本文末尾に "powered by Claude Code" などのフッターは付けない