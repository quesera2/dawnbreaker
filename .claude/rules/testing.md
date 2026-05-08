---
paths:
  - "test/**/*.dart"
---

## テスト方針

### テスト名の書き方

グループ名・テスト名には実装の詳細を混入させず、振る舞いを自然言語で記述する。

| Don't  | Do |
| --- | --- |
| null の場合 | コメントなしの場合<br />（nullの意味を説明） |
| `TaskSaveException`が throw されること | タスクが保存されないこと<br />（例外の結果が意味することを説明） |
| `taskScheduledConfigs` テーブルにレコードがない場合 | DBが異常な場合<br />（その状態が意味することを説明） |

### 正常系の入力バリエーション

同じ振る舞いを確認する入力バリエーションは `for` でまとめて検証する。要因ごとに `group` を分けない（複合要因のバグが検出されなくなるため）。

```dart
group('正常系', () {
  for (final (input, expected) in [
    ('掃除', 'そうじ'),
    ('洗濯', 'せんたく'),
  ]) {
    test('$input → $expected', () async {
      expect(await translate.translate(input), expected);
    });
  }
});
```

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
      group('正常系') { /* 入力バリエーションは for でまとめる */ }
      group('異常系') { test(...) }
    }
  }
}
```

### ViewModel テストの状態アクセスパターン

`container.read(provider)` を毎回インラインで書かず、`provider` / `viewModel` / `viewState` の3つを必要に応じて group スコープに宣言する。

- `provider` (`setUpContainer` で設定）
- `viewModel` (メソッド呼び出し用）
- `viewState` (`container.listen` で自動更新）

```dart
group('XxxViewModel', () {
  late ProviderContainer container;
  late XxxViewModelProvider provider;
  late XxxViewModel viewModel;
  late XxxUiState viewState;

  // ロード前の状態を検証する「初期状態」グループ用。container と provider だけ作る
  void setUpContainer({int? taskId}) {
    container = ProviderContainer(...);
    provider = xxxViewModelProvider(taskId: taskId ?? defaultId);
  }

  // ロード完了後を検証する「ロード後」グループ用。viewModel / viewState も準備する
  Future<void> setUpLoaded({int? taskId}) async {
    final id = taskId ?? defaultId;
    setUpContainer(taskId: id);
    await waitUntil(container, provider, (s) => !s.isLoading);
    viewModel = container.read(provider.notifier);
    container.listen(provider, (_, next) => viewState = next, fireImmediately: true);
  }

  test('...', () async {
    await viewModel.someAction();
    expect(viewState.someField, expected);   // container.read 不要
  });
});
```

`waitUntil` は `test/helpers/riverpod_test_helper.dart` に定義済み。