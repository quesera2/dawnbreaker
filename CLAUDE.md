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
コンポーネントやトークンの仕様は `DESIGN.md` を参照すること。

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

## ローカライズ

- `flutter_intl` IDE プラグイン（Localizely）を使用
- ARB ファイル（`lib/l10n/intl_ja.arb`）を保存すると IDE が `lib/generated/` を自動生成する
- 生成ファイルはビルド成果物ではなく通常のソースファイルとしてコミット済み（`pubspec.yaml` に `generate: true` が不要な理由）
- Widget の `build` 内では `S.of(context).xxx`、Widget ツリー外では `S.current.xxx` でアクセス
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

## テスト方針

### テスト名の書き方

グループ名・テスト名には実装の詳細を混入させず、振る舞いを自然言語で記述する。

| Don't  | Do |
| --- | --- |
| null の場合 | コメントなしの場合<br />（nullの意味を説明） |
| `TaskSaveException`が throw されること | タスクが保存されないこと<br />（例外の結果が意味することを説明） |
| `taskScheduledConfigs` テーブルにレコードがない場合 | DBが異常な場合<br />（その状態が意味することを説明） |

### group の構成ルール

**Repository テスト**

前提状態が異なるテスト群は group をネストし、各 setUp で前提を作る。

```dart
group('updateExecution', () {
  late int taskId;

  setUp(() async {
    taskId = await repository.addTask(...);
  });

  group('コメントなしの場合', () {
    late TaskHistory history;

    setUp(() async {
      history = await repository.recordExecution(taskId, comment: null);
    });

    test('コメントを追加できる', () async { ... });
  });

  group('コメントありの場合', () {
    late TaskHistory history;

    setUp(() async {
      history = await repository.recordExecution(taskId, comment: '元のコメント');
    });

    test('コメントを削除できる', () async { ... });
  });
});
```

**ViewModel テスト**

```dart
group('XxxViewModel') {
  group('初期状態') { test(...) }   // ロード前
  group('ロード後') {               // ロード後に共通する全テストをここに置く
    group('メソッド名') {
      group('正常系') {
        // 入力バリエーションは for でまとめて検証する
        // 要因ごとに group を分けない（複合要因のバグが検出されなくなるため）
      }
      group('異常系') { test(...) }
    }
  }
}
```

## エラーハンドリング

- Repository の例外は `sealed class TaskRepositoryException` のサブクラスとして定義（`lib/data/repository/task/task_repository_exception.dart`）
- ViewModel は例外を `ErrorMessage` サブクラスに変換して UiState にセット（文字列不可）
  - 再試行可能なエラーは `handler` に retry 処理を渡す
  - 再試行不可なエラー（`TaskNotFoundErrorMessage` 等）は `handler` なし
- UiState は `ErrorMessage? errorMessage` を `BaseUiState` 経由で保持
- エラーダイアログは `ErrorDialogMixin` を `with` して `build()` 内で `listenError(provider)` を呼ぶ
  - `handler` あり → 「キャンセル」「再試行」ボタン
  - `handler` なし → 「OK」ボタンのみ