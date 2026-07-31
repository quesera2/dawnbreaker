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
| credential が使用済み | ゲスト側にデータがあれば「いまのタスクは引き継がれません。サインインするとゲストで作成したタスクは失われ、元に戻せません」と警告し、了承後に `signInWithCredential`。ゲスト側のデータは捨てる |

移行先アカウントのタスクが 0 件だった（アカウントを作ったが放置していた）場合もデータは引き継がない。そこは自己責任ということで…。

件数は数えず、データがあるか（`limit(1)` の存在確認）だけを見る。データがある旨を警告して
キャンセルできるようにすることで、不意のデータ喪失は防ぐ。

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

主題は Google サインイン。Phase8 で作ったログイン画面にダミーで置いたボタンのうち Google を配線し、
匿名からの昇格を実装する。
ログアウト・アカウント削除は Phase10 に回すため、ここではスタブでよい（**このフェーズはストアに出さない**前提）。

Apple サインインは Sign In with Apple の capability が有料の Apple Developer Program 必須のため、
ストアに出さない Phase9 では**一旦ドロップ**する。ただし後から差し込めるよう、credential の取得元を
抽象化し、`UserRepository` は `OAuthCredential` を汎用に受ける形にしておく。詳細は
「Apple サインインは将来対応」を参照。

各 PR は、マージした時点で実機で操作して確認できる単位に切る（UI からネイティブ設定まで1機能を通す）。
依存は PR1 → PR2 → PR3 と一方向に増やす。

- [x] **PR1: Google でログインして動く状態にする**
    - `google_sign_in` 追加＋ネイティブ設定（iOS reversed client id / URL scheme、Android SHA・OAuth クライアント）
    - credential 取得の seam を薄く1メソッドに置き、`UserRepository.signInWithGoogle` を足す
      （Apple は将来 sibling を足すだけにする。今は Google 1つなので抽象化を作り込みすぎない）
    - ログイン画面の Google ボタンを実配線。画面・「ゲストではじめる」・失敗時のエラーと再試行、
      サインイン後の通知誘導/ホーム振り分け（`_resolveDestination`）は Phase8 PR3 で作成済みのものに載せる
    - Apple ボタンはログイン画面から一旦下ろす。`SocialProvider` は `google` / `apple` の両値を残す
    - <s>ID/Password</s> はサインイン・パスワードリマインドなどの画面が必要になるため廃止
    - ※ ネイティブ設定は CI で検証できないため実機確認が要る
- [x] **PR2: 匿名からの昇格**
    - 設定画面のゲスト向け「ログイン」導線を正規化し、昇格モードで `/login` へ遷移する
      （現状はデバッグ項目 `settingsDebugOpenLogin` しかない。ここが昇格の入り口になる）
    - ログイン画面にモード（初回 / 昇格）を足し、昇格で来たときは「または」と「ゲストではじめる」を隠す
    - credential が未使用なら `linkWithCredential` で昇格（uid もデータもそのまま）
    - `credential-already-in-use` のときは警告ダイアログ（`loginSwitchAccount*` を ARB に追加）を出し、
      了承後にサインインし直す
        - 例外オブジェクトが持つ credential を使う
        - サインイン前に `fcmTokens` から自端末のトークンを `arrayRemove` し、サインイン後に新 uid へ `arrayUnion` する
    - ※ `firebase_auth_mocks` は `credential-already-in-use` は仕込めるが、匿名ユーザーの
      `linkWithCredential` は再現できない（リンク後も匿名のままだと決め打ちして assert する）。
      昇格が成功する経路だけ `MockUser` を継承して差し替えた。実際に uid が保たれるかは実機確認が要る
- [x] **PR3: リンク済みの設定出し分け＋ログアウト/削除スタブ**
    - LoggedIn には「ログアウト / アカウント削除」を、ゲストには「ログイン」を出す（設計方針の表どおり）
    - 昇格（PR2）が入って初めて LoggedIn に到達できるため、このPRは最後に置く
    - ログアウトはここで実装した（Phase10 から前倒し）。アカウント削除はスタブのまま

### Apple サインインは将来対応（要有料アカウント）

Sign In with Apple は App ID に紐づく Service capability で、有効化には有料の Apple Developer Program が要る。
無料の Personal Team では有効化できない。加えて審査ガイドライン 5.1.1(v)（他社ソーシャルログインを出すなら
Sign In with Apple も出す）自体がストア公開＝有料アカウントを前提にしている。

そのため Apple はストア公開が視野に入る段階（Phase10 前後）に回す。Phase9 では以下を残し、
Apple 追加を「credential 取得元を 1 つ足してボタンを再表示するだけ」に留める。

- credential 取得を抽象化し、`UserRepository` は `OAuthCredential` を汎用に受ける
- `SocialProvider` に `apple` を残す（ボタンは非表示）
- 昇格の `linkWithCredential` / `credential-already-in-use` 経路はプロバイダに依存しない作りにする
  （Apple は nonce の都合で元の credential を再利用できないため、例外が持つ credential を使う設計が効く）

Apple のプライベートリレー経由で誤って別アカウントを作っても、初回ログインは uid を切り替えるだけで
どちらのデータも消さないため、正しいプロバイダで入り直せば元の `users/{uid}` に戻って復元される。
回復可能なので「前回プロバイダを記録して事前に防ぐ」対策は入れない。

## Phase10

主題はアカウントのライフサイクルと落穂拾い。ログアウト・削除・回収バッチを実装し、
ここで初めてストア公開に耐える状態にする（Apple のアカウント削除要件を満たすのもここ）。

- [x] ログアウトを実装する（リンク済みユーザーのみ）※ 他に依存しないため Phase9 PR3 で先行実装した
  - `fcmTokens` から `arrayRemove` → `deleteToken()` → ログイン画面へ → `signOut()`
    （`signOut()` は遷移の後。ホーム画面が残ったまま `NoLogin` にすると、タスクの読み込みが例外になる）
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
