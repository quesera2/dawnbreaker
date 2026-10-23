# Firebase 設計

- 認証は Firebase Auth（匿名 / Google）で行う
- データは Firestore の `users/{uid}` 配下に置く（構造は `schema.md`）
- 以下の Cloud Functions を持つ
    - タスク更新を行った場合、スケジュール再計算を行う
    - 通知の送信処理を行う
    - アカウント削除時および放置アカウントの回収（データも削除する）

## 設計方針

### アカウント間でタスクデータを移動しない

アカウントごとに割り当てられた uid をもとに `users/{uid}` にデータを保持する。

- 初回サインインに uid を割り振られる
- 匿名サインインから Google アカウントサインインに昇格した場合は uid はそのまま維持される
- 匿名サインインからすでに存在する Google アカウントにログインした場合、現在のデータは破棄する

データのマージ処理は行わず、アカウント存在判定も判定に使うのは Auth の情報（credential が既に使われているか）だけを見てシンプルにする。

### ゲストにはログアウトを出さない

匿名アカウントは再ログインのための認証情報がないのでログアウトしたらデータを復元できないため。

もしユーザー自身の意思でローカルの認証情報を消した場合、ロストすることは許容とする。

### ログアウト・アカウント削除で Firestore のオフラインキャッシュは消さない

- `clearPersistence()` は「主にテスト用で、安全な消去は試みない」と明記されており、プライバシー保護にならない
- キャッシュはパス単位で保持されるため、新しいセッションが `users/{旧uid}` を引くことはない
- キャッシュは既定 40MB 上限の LRU で自己管理される
- 実行時に `terminate()` を呼ぶと、以降その Firestore インスタンスは `clearPersistence()` 以外の全メソッドが `FirebaseException` を投げるようになり、サインインし直しても復帰できない
- 未送信の書き込みが残っていても、再送時にセキュリティルールで弾かれて捨てられる

### ルーティングは go_router の `redirect` に載せない

初期画面は `main()` が `getUser()` を 1 度読んで決める。

ユーザーが切り替わる契機のうち「ゲスト作成」「ログアウト」「アカウント削除」は、いずれも遷移先を知っているコードが引き起こすため、`redirect` で待ち受ける必要がない。

例外は他端末での削除や定期削除によるセッション切れで、これだけはアプリの操作と無関係に起きる。これもサインイン状態を購読して `redirect` で受けるのではなく、決まった契機で確かめて一度きりの知らせとして受ける（「セッション切れの検知」）。購読すると、セッションが切れた瞬間に下流の画面が作り直されて壊れ、`redirect` は遷移中に旧画面を残すためそれを防げない。

### CloudStorage の課金体系を前提としたデータ処理を行う

- タスク詳細の実行履歴はページングし、一度にすべて読まない
- 実行履歴はタスク詳細画面でだけ読む。ホーム画面でタスクごとに履歴を読まない
- 復元などの一括書き込みは 500 件ずつのバッチに分ける
- タスク実行間隔はサーバーサイドで計算する

## 認証

- `AppUser` は `NoLogin` / `SignedInUser`（`Guest` / `LoggedIn`）の sealed 階層
- 起動時のルートは 3 分岐。`Guest` / `LoggedIn` はホーム、`NoLogin` は `onboarding_complete` に応じてチュートリアルかログイン画面
- ログイン画面の「ゲストではじめる」で匿名アカウントを作る。作成後、通知が OFF なら通知設定の誘導画面を挟んでからホームへ。通知への誘導はアカウント作成後に一本化している
- `users/{uid}` は作成時に初期化しない。通知設定か FCM トークンを書いたときに初めて作られる
- ID / パスワードでのサインインは、サインイン・パスワードリマインドなどの画面が要るため持たない

### Google サインインと匿名からの昇格

- 設定画面の「ログイン」から昇格モードで `/login` へ遷移し、`linkWithCredential` で uid ごと引き継ぐ
- `credential-already-in-use` のときは警告ダイアログを出し、了承後に例外が持つ credential で
  サインインし直す（uid の乗り換え）。`fcmTokens` は旧 uid から `arrayRemove` し、新 uid へ `arrayUnion` する
- 昇格では通知の誘導を挟まず、元の画面へ戻す

### ログアウト

- 設定画面は `LoggedIn` に「ログアウト / アカウント削除」を、ゲストに「ログイン」を出す
- ログアウトは `fcmTokens` から `arrayRemove` → `deleteToken()` → ログイン画面へ遷移 → `signOut()` の順。
  `signOut()` を遷移より先に呼ぶと、ホーム画面が残ったまま `NoLogin` になりタスクの読み込みが例外になる

## アカウント削除

Functions の `deleteAccount`（`onCall`）が消す。

- `recursiveDelete(users/{uid})` → `deleteUser(uid)` の順。逆順だとデータ削除に失敗したとき
  ユーザーがサインインできなくなり、`users/{uid}` が誰にも辿れないゴミとして残る。
  この順なら Auth が生きているので、もう一度削除を実行すれば続きから消せる
- `deleteUser` の `auth/user-not-found` は成功として返す。他端末で先に消されていると
  `recursiveDelete` は成功して `deleteUser` だけが失敗し、再試行しても直らないため。
  これで削除全体が冪等になる
- トークンが失効していると callable に認証が付かず `unauthenticated` で返る。
  クライアントはこれを「もう消えている」とみなして成功として扱う
- uid は引数で受けず `request.auth.uid` を使う。引数で受けると他人の uid を渡して消せてしまう
- クライアントの `user.delete()` は `requires-recent-login` で失敗しうるため、Admin SDK 側で消す

クライアントの流れ:

- 設定画面が確認ダイアログ → `deleteToken()` → callable まで行い、消し終えてからチュートリアル先頭へ遷移する。
  最初の画面に戻すことで、完全に消えた雰囲気を出す
- 失敗したらその場で再試行を促す。消えたかどうかを曖昧にしないため、枠外タップでは閉じさせない
- `signOut()` と `removeCompletion()` は遷移先のチュートリアル画面
  （`OnboardingMode.afterAccountDeletion`）が、入場アニメーションの完了を待ってから行う。
  設定画面を残したままサインアウトすると、まだ生きている購読が `NoLogin` で走って例外になるため
- `signOut()` がないと端末に消したユーザーのセッションが残り、開き直したときに空のホームが出る
- `fcmTokens` の `arrayRemove` は不要（`users/{uid}` ごと消えるため）。端末側の `deleteToken()` は要る

## セッション切れの検知

他端末での削除や定期削除（「放置アカウントの回収」）でアカウントが消えると、トークン更新の失敗で SDK がローカルでサインアウトする。

### セッションは購読しない

- `currentUserProvider` は `authStateChanges()` を購読せず、`getUser()` を keepAlive で持ち続ける。
  ユーザーを切り替えたコード（サインイン完了・ログアウト・アカウント削除）が直後に `ref.invalidate` で読み直す
- 購読すると、SDK がサインアウトした瞬間に uid に属するリポジトリが `NoLogin` で例外を投げ、
  それを `ref.watch` している ViewModel が build ごと失敗して画面が `ProviderException` で落ちる
- uid に属するリポジトリは `currentUserIdProvider` を見る。昇格では uid が変わらないため作り直されない
- リポジトリの provider が `NoLogin` で `XxxNotSignedInException` を投げるのは残す。
  サインインしていないのにリポジトリを使うのはプログラムの誤りであるため

### 確かめる契機

| 契機 | 確かめ方 | 見せ方 |
|---|---|---|
| 起動時・復帰時 | `SessionObserver` が `reload()` でサーバーに問い合わせる | セッション切れのダイアログ |
| 書き込み（CUD） | リポジトリが書く前と失敗時に `currentUser` を見る（通信なし） | セッション切れのダイアログ |
| 読み取り（購読） | 確かめない | 見せない。ログに残し、画面は最後の値のまま |

- 定期削除が消すのは `lastRefreshTime` が古い、つまりしばらく前面で使われていない匿名ユーザーに限られる。
  消されたあとに最初に触れるのは必ず起動か復帰になるため、操作をしなくてもここで気づける
- `reload()` が `user-not-found` / `user-disabled` / `user-token-expired` / `invalid-user-token` で失敗したら切れているとみなす。
  通信の失敗などは、オフラインをセッション切れと取り違えないよう何もしない
- 書き込みは、セッションがないとサーバーの応答が来ず完了を待ち続けるため、書く前に弾く。
  リポジトリごとの `XxxSessionExpiredException` を投げ、ViewModel は自前のエラーダイアログを出さない
- `permission-denied` では判定しない（ルールの設定ミスと区別できないため）。
  購読の失敗はセッション切れでも設定ミスでも、ユーザーには見せずにログへ残す
- 拾えないのは、この端末を前面で開いている最中に本人が別の端末で削除したとき。
  次の書き込みか次の復帰までダイアログは出ないが、本人の操作なので許容する

### 知らせ方

- 見つけたところが `SessionExpiry` に知らせる。状態ではなく一度きりの知らせで、サインインし直すまでは重ねて知らせない
- `App` が受けて `SessionExpiredMessage` を出す。再試行しても直らないので OK だけのダイアログにし、
  枠外タップ・システムバックでは閉じさせない
- OK の後はログアウトと同じ経路（`LoginParam(executeLogout: true)`）に乗せ、遷移を待ってから
  トークンを捨ててサインアウトする
- 起動時の確認は `runApp` より前に始まるため、`App` は先に届いていた知らせも受け、
  Navigator ができるフレームを待ってから出す

## プッシュ通知

ローカル通知では他端末に通知を飛ばせないため、FCM で送り、送信の起点は Cloud Functions に置く。

- クライアントはトークンを `users/{uid}.fcmTokens` に登録する（詳細は `schema.md`）
- 通知設定とタイムゾーンは送信主体が Functions なので Firestore に置く。
  配色・表示モードなど端末固有の設定は SharedPreferences に残す
- 送信対象の予定時刻は `users/{uid}/notifications/{taskId}` の帳簿に書き出す
- FCM の送信 API に予約配信がないため、`sendScheduledNotifications` が 5 分間隔で帳簿を突き合わせ、
  その回の対象を `sendEach()` でまとめて送る
    - Cloud Tasks で通知ごとにジョブを積む方式は採らない。状態を帳簿とジョブの 2 箇所に持つと、
      予定の変更・取り消しで不整合が起きるため
- 帳簿の書き方と重複送信の防止（`lastNotifiedFor`）は `schema.md` を参照
- 失効したトークンは送信した Function が `fcmTokens` から取り除く

スケジュールの再計算も Functions が行う。`executions` の書き込みを拾う `onExecutionWritten` と、
`taskDefinitions` の書き込みを拾う `onTaskDefinitionWritten` が `lastExecutedAt` / `nextScheduledAt` を書き戻す。

## 放置アカウントの回収

定期実行の Function が 2 方向から回収する。削除は `deleteAccount` と同じく Firestore → Auth の順。

- `cleanupInactiveAnonymousAccounts`: 匿名のまま使われていないアカウントを Auth ごと消す。これが本来の目的
    - Auth を `listUsers()` で全走査する。Firestore の `users` を起点にすると、ゲストを作った直後に
      使われなくなって `users/{uid}` すら無いアカウント（まさに回収したい形）を拾えない
    - 最終アクティブ日時は Auth の `metadata.lastRefreshTime ?? creationTime`（ID トークンを最後に
      更新した時刻）。アプリを使っている間は Auth SDK が自動で進める
    - 連携済みユーザーは回収しない
- `cleanupOrphanedUserData`: Auth に存在しない uid の Firestore データを消す。Auth が先に消える経路
  （他端末からの削除、コンソールからの手動削除）やタイミングで取り残されたデータを片付ける安全網
    - Auth から消えた uid は戻らないので、猶予を置かずに消す
    - 親の `users/{uid}` が無くサブコレクションだけが残ることがあるため、`listDocuments()` で列挙する

運用:

- 匿名回収の猶予日数は `INACTIVE_ANONYMOUS_ACCOUNT_RETENTION_DAYS`（dev 3 日 / prod 想定 180 日）。
  `defineInt` と `.env.<プロジェクトID>` で環境ごとに変え、prod プロジェクトを作る際は `.env` を足すだけでよい
- `defineInt` の既定値は prod 想定の値にしている。`.env` を置き忘れたプロジェクトへデプロイしたとき、
  短い猶予のまま消しにいかないようにするため
- `.env.<プロジェクトID>` はルートの `.gitignore` の `*.env.*` で除外されるが、環境ごとの値をコミットしたいので
  `functions/.gitignore` の否定パターンで戻している
- 1 回の実行で削除する件数に上限を置く。`recursiveDelete` と `deleteUser` は重く、
  `maxInstances` が 1 なのでタイムアウトすると実行全体が落ちる。超過分は次回に回る
- `onSchedule` の Function はエミュレータで pubsub に publish しても発火しない（firebase-tools の制限）。
  動作確認はビルド済みの `lib/index.js` を読み込み、`<Function>.run({...})` を直接呼ぶ

## Apple Developer Program に登録したらやること

Sign in with Apple も APNs も capability の有効化に有料の Apple Developer Program が要り、
無料の Personal Team では有効化できない。どちらも登録するまで保留している。

### APNs（iOS のプッシュ通知）

- [ ] Push Notifications capability を有効化し、`aps-environment` の entitlements を追加する
      （現状 `ios/Runner` に entitlements ファイル自体がない）
- [ ] APNs 認証キー（.p8）を作り、Firebase コンソールに登録する

### Sign in with Apple

- [ ] Sign in with Apple の capability を有効化し、credential の取得元を足す
- [ ] ログイン画面に Apple ボタンを足す。マーク画像・文言・`SocialProvider.apple` は削除済みのため作り直す
- [ ] アカウント削除に Apple トークンの revoke（クライアント）を足す
