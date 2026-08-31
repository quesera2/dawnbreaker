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

## 設計方針

### アカウント間でタスクデータを移動しない

データの置き場は `users/{uid}` だけ。サインインでやることは uid を保つか、uid を乗り換えるかの
どちらかで、乗り換えるときは前の uid のデータを見捨てる。マージはしない。

判定に使うのは Auth の情報（credential が既に使われているか）だけで、`users/{uid}` にデータが
あるかどうかでは分岐しない。

### ゲストにはログアウトを出さない

匿名アカウントには credential がないため、ログアウトすると二度と戻れず不可逆なデータ喪失になる。

### ログアウト・アカウント削除で Firestore のオフラインキャッシュは消さない

- `clearPersistence()` は「主にテスト用で、安全な消去は試みない」と明記されており、プライバシー保護にならない
- キャッシュはパス単位で保持されるため、新しいセッションが `users/{旧uid}` を引くことはない
- キャッシュは既定 40MB 上限の LRU で自己管理される
- 実行時に `terminate()` を呼ぶと、以降その Firestore インスタンスは `clearPersistence()` 以外の
  全メソッドが `FirebaseException` を投げるようになり、サインインし直しても復帰できない
- 未送信の書き込みが残っていても、再送時にセキュリティルールで弾かれて捨てられる

### ルーティングは go_router の `redirect` に載せない

初期ルートは `main()` が `getUser()` を 1 度読んで決め、以降は命令的に遷移する。
ユーザーが切り替わる契機は「ゲスト作成」「ログアウト」「アカウント削除」しかなく、いずれも遷移先を
知っているコードが引き起こすため、受動的に待ち受ける必要がない。他端末での削除によるトークン失効も、
操作時のエラーとして検知する明示的な経路になる。

## Phase9

主題は Google サインイン。Phase8 でダミーだったボタンを配線し、匿名からの昇格までを通した。
Apple サインインは有料の Apple Developer Program が要るためドロップした
（→ 末尾「Apple Developer Program に登録したらやること」）。

- [x] **PR1: Google でログインして動く状態にする**
    - `google_sign_in` 追加＋ネイティブ設定（iOS reversed client id / URL scheme、Android SHA・OAuth クライアント）
    - credential 取得の seam を 1 メソッドに置き、`UserRepository.signInWithGoogle` を足す
    - <s>ID/Password</s> はサインイン・パスワードリマインドなどの画面が必要になるため廃止
- [x] **PR2: 匿名からの昇格**
    - 設定画面の「ログイン」から昇格モードで `/login` へ遷移し、`linkWithCredential` で uid ごと引き継ぐ
    - `credential-already-in-use` のときは警告ダイアログを出し、了承後に例外が持つ credential でサインインし直す。
      `fcmTokens` は旧 uid から `arrayRemove` し、新 uid へ `arrayUnion` する
    - ※ `firebase_auth_mocks` は匿名ユーザーの `linkWithCredential` を再現できない
      （リンク後も匿名のままだと決め打ちして assert する）ため、昇格が成功する経路だけ
      `MockUser` を継承して差し替えた。uid が保たれるかの確認は実機で行う
- [x] **PR3: リンク済みの設定出し分け＋ログアウト**
    - LoggedIn には「ログアウト / アカウント削除」を、ゲストには「ログイン」を出す
    - ログアウトは `fcmTokens` から `arrayRemove` → `deleteToken()` → ログイン画面へ遷移 → `signOut()` の順。
      `signOut()` を遷移より先に呼ぶと、ホーム画面が残ったまま `NoLogin` になりタスクの読み込みが例外になる
    - アカウント削除はスタブのまま Phase10 へ送った

## Phase10

主題はアカウントのライフサイクル。アカウント削除と、その取りこぼしを掃除する仕組みを入れる。

- [x] **PR1: アカウント削除**
    - functions に `deleteAccount` を `onCall` で追加する
        - `recursiveDelete(users/{uid})` → `admin.auth().deleteUser(uid)` の順で消す。
          逆順だとデータ削除に失敗したときユーザーがサインインできなくなり、
          自力で再実行できないまま `users/{uid}` が誰にも辿れないゴミとして残る。
          この順なら Auth が生きているので、もう一度削除を実行すれば続きから消せる
        - uid は引数で受けず `request.auth.uid` を使う。引数で受けると他人の uid を渡して消せてしまう
        - クライアントの `user.delete()` は `requires-recent-login` で失敗しうるため、Admin SDK 側で消す
    - クライアントは `cloud_functions` を追加し、`UserRepository.deleteAccount()` の中で
      `httpsCallable('deleteAccount')` を呼ぶ。リージョンは functions 側が未指定（`us-central1`）で
      クライアントの既定と一致するため設定は要らない
        - `FirebaseFunctionsException` は `UserRepositoryException` のサブクラスに変換する
        - `cloud_functions` にモックがないため、テストは `UserRepository` の Fake で差し替える
    - 設定画面が確認ダイアログ（`destruction`）→ `deleteToken()` → callable まで行い、
      消し終えてからチュートリアル先頭へ遷移する。最初の画面に戻すことで、完全に消えた雰囲気を出す。
      失敗したらその場で再試行を促す（消えたかどうかを曖昧にしないため、枠外タップでは閉じさせない）
    - `signOut()` と `removeCompletion()` だけは遷移先のチュートリアル画面
      （`OnboardingMode.afterAccountDeletion`）が行う。設定画面を残したままサインアウトすると、
      まだ生きている購読が `NoLogin` で走って例外になるため（ログアウトと同じ形）
    - 遷移が終わるまで送り出した画面は破棄されないため、後始末は入場アニメーションの完了を待つ。
      ログイン画面のログアウトが持っていたこの待ちは `AfterTransitionMixin` に括り出して共有した
    - 削除の実行を遷移先に寄せる形も試したが、消える前にチュートリアルへ移るため
      操作として腑に落ちず、消してから戻す形に落ち着けた
    - `signOut()` は計画になかったが要る。端末には消したユーザーのセッションが残るため、
      これがないとアプリを開き直したときに `/home` に入って、空のホームが出てしまう
    - `fcmTokens` の `arrayRemove` は不要（`users/{uid}` ごと消えるため）。端末側の `deleteToken()` は要る
    - `cloud_functions` を足すと `cloud_firestore` が 6.8.0 に上がり、
      `fake_cloud_firestore` 4.1.1 がコンパイルできなくなるため 4.2.0 へ上げた
- [x] **PR2: 他端末で削除されたことの検知**
    - 削除されるとトークン更新が失敗して SDK がローカルでサインアウトするため、
      `authStateChanges()` → `currentUserProvider` が `NoLogin` → `taskRepositoryProvider` が
      `TaskNotSignedInException` を投げ、既存の例外として観測できる。
      `permission-denied` を見て判定する必要はない（ルール設定ミスと区別できないため、そうしない）
    - ViewModel の `catch` で `TaskNotSignedInException` だけ `TaskRepositoryException` の
      手前に分け、`SessionExpiredMessage` を出す（8 箇所）。再試行しても直らないので
      OK だけのダイアログにし、閉じるだけで済ませられないようにする。
      `dismissible: false` は枠外タップしか塞がないため、`AppDialog.show` に `PopScope` を足して
      システムバックも塞いだ（`DeleteAccountErrorMessage` も同じ意図なので一緒に効く）
    - OK の後の `/login` への遷移は、AppDialog の既存の仕組みに乗せる。ViewModel が
      `SessionExpiredMessage` の `secondaryHandler` に「ログインし直させる」アクションを渡し、
      それが `signInRequired` を UiState に立て、画面が listen して遷移する
      （アカウント削除の `AccountDeletedEvent` と同じ形）
    - `_requireSignIn` は 3 つの ViewModel に同じものが並ぶが、mixin に括り出しても
      `BaseUiState` からは `copyWith` を呼べず各 ViewModel に同じ行数が残るため、そのままにした
    - 検知はトークン更新の契機まで遅れるが、設計方針の「操作時のエラーとして検知する」と一致している
    - ログアウトでは「ホーム画面が残ったまま `NoLogin` にすると例外になる」ことを避けたが、
      ここではその例外が検知したい信号そのものになる
    - なお `taskRepositoryProvider` は Provider の build で投げるため、画面を開いたまま
      `NoLogin` になった場合はダイアログではなく ViewModel の再構築で例外が伝播する。
      「未サインインで Repository に触る状態そのものを不正扱いにする」既存方針のまま握り潰さない
    - `FakeTaskRepository` に `thrownException` を足し、メソッドごとの既定の例外の代わりに
      任意の例外を投げられるようにした。`fetchTaskHistory` だけは画面の初回ロードでも通るため
      `shouldThrow` では投げない（既存の異常系テストがロード前に失敗するため）
- [ ] **PR3: 放置アカウントを回収する定期実行 Function（削除の安全網）**
    - Auth に存在しない uid の Firestore データを削除する
      （`auth/user-not-found` が確定した場合に限り、かつ `lastActiveAt` から一定期間経過していること）
    - 匿名かつ `lastActiveAt` から長期間更新のないアカウントを Auth ごと削除する
    - しきい値は用途が違うので別々に持ち、`defineInt` と `.env.<プロジェクトID>` で環境ごとに変える。
      prod プロジェクトを作る際は `.env` を足すだけでよい形にする

      | 対象 | dev | prod 想定 |
      |---|---|---|
      | Auth に無い uid の Firestore データ（削除の失敗残骸） | 1日 | 7日 |
      | 匿名かつ長期間未使用のアカウント | 3日 | 180日 |

      dev で日数を分けるのは、片方だけ発火する状態を作って経路を切り分けられるようにするため

## Apple Developer Program に登録したらやること

Sign in with Apple も APNs も capability の有効化に有料の Apple Developer Program が要り、
無料の Personal Team では有効化できない。どちらも登録するまで保留している。

### APNs（iOS のプッシュ通知）

- [ ] Push Notifications capability を有効化し、`aps-environment` の entitlements を追加する
      （現状 `ios/Runner` に entitlements ファイル自体がない）
- [ ] APNs 認証キー（.p8）を作り、Firebase コンソールに登録する

### Sign in with Apple

- [ ] Sign in with Apple の capability を有効化し、credential の取得元を足す
- [ ] ログイン画面に Apple ボタンを戻す
- [ ] アカウント削除に Apple トークンの revoke（クライアント）を足す
