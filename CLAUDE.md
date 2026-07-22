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

## 変数・識別子の命名

略語・省略形は使わない。ただし以下は Dart/Flutter の慣習として許容する：

- `ref`（Riverpod の Ref）
- `e` / `s`（catch ブロックのエラー・スタックトレース）
- `i`（ループカウンタ）
- `_` / `(_, _)`（未使用引数）
- `ctx`（BuildContext）

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

## エラー処理

- **例外はリポジトリごとに定義する。** `StateError` などの汎用型を投げず、
  `xxx_repository_exception.dart` に `sealed class XxxRepositoryException` を作り、その下に具体的な型を並べる
- **例外のメッセージは英語で書く。** ログ・Crashlytics に出るものであり、ユーザーには見せない
  （ユーザーに見せる文言は l10n を通す）
- `!`（null assertion）で潰さない。`Null check operator used on a null value` としか残らず原因が読めないため、
  何が起きたかを書いた例外を投げる

## クラスのメンバー順序

**呼び出し元のメソッドを先に書き、そこから呼び出されるメソッドを後に書く。** これは public → private だけでなく、private メソッド同士（private が別の private を呼ぶ場合）にも適用する。1つの private メソッドが複数箇所から呼ばれる場合は、最後の呼び出し元より後ろに置く。

Widget クラスの場合はこの原則に従うと次の順になる：

1. フィールド（static const → インスタンス変数）
2. ライフサイクル（`initState` → `didUpdateWidget` → `dispose`）
3. `build`
4. プライベートメソッド（`_xxx`）

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