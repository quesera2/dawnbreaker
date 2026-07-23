# Firebase移行計画

## Phase1

- [x] SQLite 版と同インターフェースで Firestore 版を作成できるようにモデルを整備 (#129)
    - id を int から String に変更

## Phase2

- [x] Firestore のスキーマモデルを作成 (#130)

## Phase3

- [x] Firebase Auth の匿名認証を使ってログインする処理を実装 (#131)
    - `TaskRepository` の取得が非同期になり、全 ViewModel が `AsyncNotifier` になった（Phase8 PR5 で解消）
- [x] pop を多重に実行してしまうバグ、EditorScreen の対応漏れを修正 (#132)

## Phase4

- [x] Phase3 でスタブにしていた FirestoreTaskRepository を実装 (#135, #137, #138, #139)
    - TaskHistory を TaskItem の子に持つモデルが NoSQL と噛み合っていないことがわかった

## Phase5

- [x] タスク詳細のタスク履歴をページング対応にする (#140)
    - ドキュメント単位課金のため、すべての履歴を一度に読まない
- [x] TaskHistory はタスク詳細画面でだけ読み込むように修正 (#142, #144)
    - ホーム画面でタスク N 件ごとに履歴 10 件を取得してしまう問題を解決

## Phase6

- [x] restoreTask を 500 件バッチ対応にし、`List<TaskItem>` を受け取れるように改修

## Phase7

主題は FCM プッシュ通知。ローカル通知では他端末に通知を飛ばせないため、送信トリガーを
Cloud Functions 側に移した。

- [x] ログイン画面実装に向けてアプリタイトルを決める
- [x] スケジュール再計算のロジックを Cloud Functions に移行する
    - `executions` の書き込みを拾う `onExecutionWritten` と、`taskDefinitions` の書き込みを拾う
      `onTaskDefinitionWritten` が `lastExecutedAt` / `nextScheduledAt` を書き戻す
- [x] **PR1: クライアントのトークン登録**
    - `firebase_messaging` によるトークンの取得・保存・更新購読、iOS の権限リクエスト
- [x] **PR2: 通知設定を Firestore へ移す**
    - `users` に `notificationSetting` / `timezone` / `lastActiveAt` を追加。
      配色・表示モードなど端末固有の設定は SharedPreferences に残す
- [x] **PR3: サーバーの `notifyAt` 帳簿**
    - 送信対象の予定時刻を `users/{uid}/notifications/{taskId}` に書き出す（詳細は `schema.md`）
- [x] **PR4: 送信 Function（Cloud Scheduler 5 分間隔）**
    - FCM の送信 API に予約配信がないため、`notifyAt` を定期的に突き合わせて送る方式を採った
    - 失効したトークンは `fcmTokens` から取り除く
- [x] **PR5: ローカル通知の廃止**
    - `flutter_local_notifications` による通知登録を廃止

## Phase8

主題は認証基盤の作り替え。SQLite / LocalUser を捨てて匿名認証に一本化し、ログイン画面までを用意した。
ソーシャルログインのボタンは置いたが配線はダミーで、全員が匿名（`Guest`）のまま新構造に載せ替えた。

- [x] **PR1: 型の作り替えと SQLite / drift の削除**
    - `AppUser` を `NoLogin` / `SignedInUser`（`Guest` / `LoggedIn`）の sealed 階層にする
    - `LocalUser` / `LocalUserRepository` / `SQLiteTaskRepositoryImpl` / drift 一式を削除
- [x] **PR2: `UserRepository` の問い合わせと命令を分ける**
    - `getUser()` から匿名サインインの副作用を取り除き、`watchUser()` と `signInAsGuest()` を足す
    - `currentUserProvider` を `Notifier<AppUser>` にする
- [x] **PR3: ログイン画面とアカウント作成フロー**
    - 「ゲストではじめる」だけを配線し、Google / Apple のボタンはダミーで置く
    - 作成後、通知が OFF なら通知設定の誘導画面を挟んでからホームへ
    - チュートリアルから通知のステップを削除し、通知への誘導はアカウント作成後に一本化
    - `users/{uid}` は作成時に初期化せず、通知を有効にしたときに初めて作られる
- [x] **PR4: `main()` から匿名サインインを外す**
    - `main()` は `initializeApp()` → `getUser()` で初期ルートを決める → スプラッシュを消す → `runApp()`
    - ルーティングは 3 分岐（`Guest`/`LoggedIn` → ホーム、`NoLogin` × `onboarding_complete` で
      チュートリアル / ログイン画面）
    - 旧 Phase10 の「初回起動 × オフラインで白画面」がここで解決した
- [x] **PR5: `AsyncNotifier` の巻き戻し**
    - `taskRepositoryProvider` を同期の `Provider` にし、Phase3 で `AsyncNotifier` にした
      ViewModel 群を `Notifier` に戻す

## 設計方針（Phase9 以降）

### アカウント間でタスクデータを移動しない

データの置き場は `users/{uid}` だけ。サインインでやることは uid を保つか、uid を乗り換えるかのどちらかで、乗り換えるときは前の uid のデータを見捨てる。マージはしない。

判定に使うのは Auth の情報だけで、`users/{uid}` にデータがあるかどうかは判定しない。その credential が既に Firebase アカウントに使われているかどうかを見る。

| 状況 | 挙動 |
|---|---|
| credential が未使用 | `linkWithCredential` で昇格。uid もデータもそのまま |
| credential が使用済み | 「現在の N 件のタスクは失われます」と警告し、了承後に `signInWithCredential`。ゲスト側のデータは捨てる |

移行先アカウントのタスクが 0 件だった（アカウントを作ったが放置していた）場合もデータは引き継がない。そこは自己責任ということで…。

警告に件数を出してキャンセルできるようにすることで、不意のデータ喪失は防ぐ。

### ゲストとリンク済みで操作を出し分ける

| ユーザー種別 | 設定画面に出す操作 |
|---|---|
| ゲスト（匿名） | ログイン のみ |
| リンク済み | ログアウト / アカウント削除 |

- ゲストに「ログアウト」は出さない。匿名アカウントには credential がないので、ログアウトすると二度と戻れず、不可逆なデータ喪失が起きてしまうため。
- リンク済みにログインを出さないの。別のアカウントにログインする場合は、一度ログアウトを挟む。
- ログアウトをするとユーザーをクリアして（Guest ではなく NoLogin になる）、ログイン画面へ行く。データはクラウドに残っているので、サインインし直せば戻ってくる。
- アカウント削除の行き先はチュートリアルの最初（NoLogin かつ `onboarding_complete` も消す）。最初の画面に戻ることで、完全にデータが消えたという雰囲気を出す。

※ アカウント削除があるのは、Apple のアカウント削除要件（App Store Review Guideline 5.1.1(v)）があるため。この制限は匿名ユーザーには掛からないので、ゲストは「アカウント削除」を用意しない。

### ルーティングは go_router の `redirect` に載せない

初期ルートは `main()` が `getUser()` を 1 度読んで決め、以降は命令的に遷移する。
ユーザーが切り替わる契機は「ゲスト作成」「ログアウト」「アカウント削除」しかなく、いずれも遷移先を
知っているコードが引き起こすため、受動的に待ち受ける必要がない。他端末での削除によるトークン失効も、
操作時のエラーとして検知する明示的な経路になる。

ログアウト時は「ログイン画面へ遷移してから `signOut()` を呼ぶ」順序にする。ホーム画面が破棄済みなら
`taskRepositoryProvider` を監視している者がいないため、`NoLogin` で例外を投げる経路に入らない。

## Phase9

主題はソーシャルログイン。Phase8 で作ったログイン画面にダミーで置いたボタンを配線し、匿名からの昇格を実装する。
ログアウト・アカウント削除は Phase10 に回すため、ここではスタブでよい（**このフェーズはストアに出さない**前提）。

- [ ] Google / Apple のサインインを配線する
  - 画面・「ゲストではじめる」・失敗時のエラーと再試行は Phase8 の PR3 で作成済み。
    ここで残っているのはダミーで置いた 2 つのボタンの中身
  - <s>ID/Password</s> はサインイン・パスワードリマインドなどの画面が必要になるため廃止
  - ブランド規定に沿ったボタンに仕上げる。PR3 のマークは公式アセットだが、寸法（Apple はタイトルが
    ボタン高さの 43%、ロゴの高さはボタンの高さ）までは追い込んでいない
  - 前回サインインしたプロバイダを SharedPreferences に記録し、ログイン画面で示す
    （Apple のプライベートリレー経由で別アカウントを作ってしまう事故を防ぐ）
- [ ] 匿名からの昇格を実装する
  - ログイン画面にモード（初回 / 昇格）を足し、昇格で来たときは「または」と「ゲストではじめる」を隠す。
    設定画面の「ログイン」から遷移するため、ゲストのままはじめる選択肢が意味を持たない
  - credential が未使用なら `linkWithCredential` で昇格（uid もデータもそのまま）
  - `credential-already-in-use` のときは警告ダイアログを出し、了承後にサインインし直す
    - 例外オブジェクトが持つ credential を使う（Apple は nonce の都合で元の credential を再利用できない）
    - サインイン前に `fcmTokens` から自端末のトークンを `arrayRemove` し、サインイン後に新 uid へ `arrayUnion` する
- [ ] チュートリアル画面にログインについての項目を追加する（旧 Phase9）
  - スキップの考え方を修正する必要があるかもしれない
- [ ] ログアウト・アカウント削除はスタブにしておく（本実装は Phase10）

## Phase10

主題はアカウントのライフサイクルと落穂拾い。ログアウト・削除・回収バッチを実装し、
ここで初めてストア公開に耐える状態にする（Apple のアカウント削除要件を満たすのもここ）。

- [ ] ログアウトを実装する（リンク済みユーザーのみ）
  - `fcmTokens` から `arrayRemove`（`signOut()` の前に）→ `deleteToken()` → `signOut()` → ログイン画面へ
  - Firestore のオフラインキャッシュは**消さない**
    - `clearPersistence()` は「主にテスト用で、安全な消去は試みない」と明記されており、プライバシー保護にならない
    - キャッシュはパス単位で保持されるため、新しいセッションが `users/{旧uid}` を引くことはない
    - キャッシュは既定 40MB 上限の LRU で自己管理される
    - 実行時に `terminate()` を呼ぶと、以降その Firestore インスタンスは `clearPersistence()` 以外の
      全メソッドが `FirebaseException` を投げるようになり、サインインし直しても復帰できない
    - 未送信の書き込みが残っていても、再送時にセキュリティルールで弾かれて捨てられる
- [ ] アカウント削除を実装する（callable function）
  - Apple トークンの revoke（クライアント）→ `recursiveDelete(users/{uid})` → `admin.auth().deleteUser(uid)`
  - クライアントの `user.delete()` は `requires-recent-login` で失敗しうるため、Admin SDK 側で消す
  - 削除後は `OnboardingRepository.removeCompletion()` を呼び、`NoLogin` かつ未視聴の状態にしてチュートリアルへ戻す
- [ ] 放置アカウントを回収する定期実行 Function を作る（削除の安全網）
  - Auth に存在しない uid の Firestore データを削除する
    （`auth/user-not-found` が確定した場合に限り、かつ `lastActiveAt` から一定期間経過していること）
  - 匿名かつ `lastActiveAt` から長期間更新のないアカウントを Auth ごと削除する
- [ ] 他端末でのアカウント削除によるトークン失効を、操作時のエラーとして検知しダイアログ経由でログイン画面へ誘導する
