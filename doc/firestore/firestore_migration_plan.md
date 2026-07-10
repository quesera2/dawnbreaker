# Firebase移行計画

## Phase1

- [x] SQLite 版と同インターフェースで Firestore 版を作成できるようにモデルを整備 (#129)
    - id を int から String に変更

## Phase2

- [x] Firestore のスキーマモデルを作成 (#130)

## Phase3

- [x] Firebase Auth の匿名認証を使ってログインする処理を実装 (#131)
    - Firebase 認証が必要なため、TaskRepository の取得が非同期となったため、全ての ViewModel を
      AsyncNotifier にする必要が生じた
- [x] pop を多重に実行してしまうバグ、EditorScreen の対応漏れを修正 (#132)

## Phase4

- [x] Phase3 でスタブにしていた FirestoreTaskRepository を実装 (#135)
    - truncateTime に夏時間バグがあったのを修正
- 設定情報を初回に取得するときに Crashlytics に送っていたのが調査の弊害になっていたため修正 (#137)
- [x] AI 実装の品質改善 (#138)
- TaskHistory を TaskItem の子に持つという実装が NoSQL と噛み合っていないことがわかった
    - #135 の当初の実装で TaskHistory を消す時に親タスクをすべてスキャンする実装になっておりこれを修正させた
    - しかしこの修正は実際には機能しおらず、追加されたフィールドは参照されていなかった (#139)

## Phase5

- [x] タスク詳細のタスク履歴をページング対応にするように変更 (#140)
    - ドキュメント単位課金のため、すべての履歴を一度に読まないようにする
    - SQLite 版はコストがないのでそのまま、Firestore 版だけ 10 件ずつ読むように修正
- [x] TaskItem と一緒に TaskHistory を取得するという従来のモデルにそもそも問題があったので、タスク詳細画面でだけ
  TaskHistory のリストを読み込むように修正 (#142)
    - これによりホーム画面でタスク N 件ごとに履歴 10 件を取得してしまう問題を解決
- [x] 
  #142の修正を見たところ想定と違う部分があった（履歴をストリーミングしてシンプルに読み込んで欲しかった）ので、修正 (
  #144)

## Phase6

- [x] restoreTask が500件バッチに対応していないのを修正するとともに、`List<TaskItem>` を受け取れるように改修する

## 設計方針（Phase7 以降）

Phase7 の検討中に、通知・認証・データ移行が互いに絡んでいることが分かったため、先に全体方針を決めた。

**SQLite / LocalUser を廃止し、全ユーザーを Firebase ユーザーにする。**
ローカル利用者はゲスト（匿名認証）として扱う。これにより次が一度に解決する。

- 通知設定の置き場所が Firestore 一本になる（SharedPreferences と Firestore に分裂しない）
- サインイン時の SQLite → Firestore のデータ移行が不要になる
- `TaskRepository` の実装が 1 つになり、drift とその周辺のテストを削除できる

代償として、初回起動時にネットワークが必須になる（2 回目以降は Firestore のオフライン永続化で動く）。
また「クラウドにデータを置かない」利用形態は提供できなくなる。

**データはアカウント間を移動しない。マージという概念を持たない。**
`users/{uid}` が唯一のデータの置き場で、サインインは「uid を保つ」か「uid を乗り換える（＝前のデータを捨てる）」の
どちらかしかない。判定は Auth レベルの「その credential が既に Firebase アカウントに使われているか」だけで行う。

| 状況 | 挙動 |
|---|---|
| credential が未使用 | `linkWithCredential` で昇格。uid もデータもそのまま |
| credential が使用済み | 「現在の N 件のタスクは失われます」と警告し、了承後に `signInWithCredential`。ゲスト側のデータは捨てる |

移行先が空のアカウントだった場合もデータは引き継がない（稀なケースのために移送コードを恒久的に保守しない）。
警告に件数を出してキャンセルできるようにすることで、不意のデータ喪失は防ぐ。

**チュートリアルを認証の手前に置き、アカウント作成を明示的な操作にする。**
チュートリアルはオフラインで動作させ、その後のログイン画面で「ゲストではじめる」を押した時点で匿名アカウントを作る。
`main()` での認証待ちがなくなるため、Phase10 の問題（認証失敗でアプリが起動しない）がここで解決する。

ルーティングは 3 分岐になる。

| 状態 | 遷移先 |
|---|---|
| ユーザーあり | ホーム |
| ユーザーなし・チュートリアル未視聴 | チュートリアル |
| ユーザーなし・チュートリアル視聴済み | ログイン画面 |

チュートリアル視聴フラグは SharedPreferences に残す。ログアウト直後のコールドスタートでは
`currentUser == null` となり、フラグがないと「未オンボーディング」と区別できないため。

**ゲストとリンク済みで操作を出し分ける。**

| ユーザー種別 | 設定画面に出す操作 |
|---|---|
| ゲスト（匿名） | ログイン のみ |
| リンク済み | ログアウト / アカウント削除 |

ゲストにログアウトを出さない。匿名アカウントには credential がなく、サインアウトすると二度と戻れないため、
「ログアウト」という名前で不可逆なデータ喪失が起きてしまう。逆にリンク済みにログインは出さない。

ログアウトはログイン画面に戻る（データはクラウドに残り、サインインし直せば復帰する）。
アカウント削除はチュートリアルの最初に戻る（チュートリアルフラグも消す）。
「最初の画面に戻る」という体験そのものが、不可逆であることの最も強いシグナルになる。

なお、Apple のアカウント削除要件（App Store Review Guideline 5.1.1(v)）は
「アカウント作成をサポートするアプリ」が対象であり、匿名ユーザーには掛からない。

## Phase7

- [x] ログイン画面実装に向けてアプリタイトルを決める
- [x] ローカルで行っているロジックを Cloud Functions に移行する
    - Firebase 基盤で複数端末が同一ログインを共有できるようにすると、タスク通知も端末間で共有する必要が生じる。
      ローカル通知だけでは他端末に通知を飛ばせないため、FCM 経由でのプッシュ通知送信が必要になり、その送信トリガーは
      クライアント側でなく Cloud Functions 側に持たせざるを得ない
    - 現状 `recordExecution` / `updateExecution` / `deleteExecution` / `restoreTask` はいずれもクライアント側で
      `_computeSchedule` を実行し、`lastExecutedAt` / `nextScheduledAt`（`cachedScheduledAt`）をキャッシュフィールドとして
      タスクドキュメントに直接書き込んでいる（`firestore_task_repository_impl.dart`）
    - - 移行後はこれらのキャッシュ書き込みをクライアントではなく Cloud Functions 側（executions サブコレクションへの
  トリガー等）で行い
- [ ] `taskType` / `scheduleConfig` の変更時に `nextScheduledAt` が再計算されない不具合を修正する
    - `updateTask` はクライアントで再計算しなくなったが、`executions` を書き換えないため
      `onExecutionWritten` でも拾えず、次に実行を記録するまで古い値が残る
    - `taskDefinitions` の書き込みトリガーを追加する（再帰を止めるガードは `schema.md` を参照）
- [ ] FCM プッシュ通知を実装し、ローカル通知を廃止する
    - <s>同じトリガーに FCM 送信を追加する</s>
      FCM の送信 API に予約配信はなく（`projects.messages.send` は即時送信のみ）、
      `onExecutionWritten` も実行履歴の書き込み時にしか発火しない。通知を送りたいのは未来の
      `nextScheduledAt` から算出した時刻なので、**Cloud Scheduler による定期実行の Function**（5 分間隔）を
      別に用意し、`notifyAt` を検索キーにして送信対象を引く（詳細は `schema.md`）
    - Cloud Tasks でタスクごとに個別のジョブを積む方式も検討したが、入力が変わるたびに
      予約済みジョブの取り消しが必要になり、取り消しと Firestore 書き込みが同一トランザクションに
      入らないため二重送信・送信漏れを原理的に塞げない。「望ましい状態（`notifyAt`）を書いて
      定期的に突き合わせる」方式なら再計算が単なる上書きになり、取り消しが不要になるため採用しない
    - `users` に `notificationSetting` / `fcmTokens` / `timezone` / `lastActiveAt` を追加する
    - `users/{uid}/notifications/{taskId}` を新設し、既存タスクへのバックフィルを行う
      - `notifyAt` / `lastNotifiedFor` はサーバーだけが読み書きする帳簿なので `taskDefinitions` に置かない。
        クライアントが `snapshots()` で購読しているドキュメントに送信記録を書くと、表示が変わらないのに
        全端末へ再配信され、タスク件数ぶんの読み取りが課金されてしまうため
    - 通知設定を SharedPreferences から Firestore に移す（`SettingsRepository` から切り出す）。
      配色・表示モードなど端末固有の設定は SharedPreferences に残す
    - クライアントに `firebase_messaging` を追加し、トークンの取得・`arrayUnion` での保存・
      `onTokenRefresh` の購読・iOS の権限リクエストを実装する
    - 送信結果が `messaging/registration-token-not-registered` のトークンは Function 側で `arrayRemove` する
    - `flutter_local_notifications` による通知登録を廃止する（`TaskNotificationSync` /
      `TaskNotificationSyncNotifier` / `NotificationPermissionObserver` の役割を見直す）

## Phase8

- [ ] `AppUser` から `LocalUser` を削除し、`SQLiteTaskRepositoryImpl` と drift を削除する
- [ ] `currentUserProvider` を `authStateChanges()` ベースの `Stream<AppUser?>` に作り替え、
      `taskRepositoryProvider` をその下流に置く
- [ ] `main()` から認証待ちを外し、go_router の `redirect` で 3 分岐のルーティングを実装する
- [ ] ログイン画面を作成する
  - 「ゲストではじめる」・Google・Apple のサインインを用意する
  - <s>ID/Password</s> はサインイン・パスワードリマインドなどの画面が必要になるため廃止
  - 前回サインインしたプロバイダを SharedPreferences に記録し、ログイン画面で示す
    （Apple のプライベートリレー経由で別アカウントを作ってしまう事故を防ぐ）
- [ ] `credential-already-in-use` のときに警告ダイアログを出し、了承後にサインインし直す
  - 例外オブジェクトが持つ credential を使う（Apple は nonce の都合で元の credential を再利用できない）
  - サインイン前に `fcmTokens` から自端末のトークンを `arrayRemove` し、サインイン後に新 uid へ `arrayUnion` する
- [ ] ログアウトを実装する（リンク済みユーザーのみ）
  - `signOut()` の前に `fcmTokens` から `arrayRemove` し、`deleteToken()` も呼ぶ
  - Firestore のオフラインキャッシュは uid 単位ではないため、`terminate()` → `clearPersistence()` で消す
    （購読中のリスナーがあると失敗するため、`ProviderContainer` の作り直しを検討する）
- [ ] アカウント削除を実装する（callable function）
  - Apple トークンの revoke（クライアント）→ `recursiveDelete(users/{uid})` → `admin.auth().deleteUser(uid)`
  - クライアントの `user.delete()` は `requires-recent-login` で失敗しうるため、Admin SDK 側で消す
  - 削除後はチュートリアルフラグも消して最初の画面に戻す
- [ ] 放置アカウントを回収する定期実行 Function を作る（安全網）
  - Auth に存在しない uid の Firestore データを削除する
    （`auth/user-not-found` が確定した場合に限り、かつ `lastActiveAt` から一定期間経過していること）
  - 匿名かつ `lastActiveAt` から長期間更新のないアカウントを Auth ごと削除する

## Phase9

- [ ] チュートリアル画面にログインについての項目を追加する
  - スキップの考え方を修正する必要があるかもしれない

## Phase10

- [x] <s>アプリ起動時に Firebase にログインできなかった場合にアプリが main で停止してしまう問題を修正</s>
  - Phase8 でチュートリアルを認証の手前に置き、`main()` から認証待ちを外すことで解決する