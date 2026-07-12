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

Phase7 で FCM 通知を検討していたら、通知・認証・データ移行が絡み合っていることが分かった。
個別に進めると手戻りするので、先に全体の方針を決めた。

### SQLite / LocalUser は廃止する

ローカル利用者もゲスト（匿名認証）として Firebase ユーザーにする。

一番大きな理由が、通知設定の置き場所が Firestore 一本になり、SharedPreferences と二重管理せずに済むこと。

サインイン時の SQLite → Firestore の移行処理・ `SQLiteTaskRepository` は削除する（drift は漂流していく）。

### アカウント間でタスクデータを移動しない

データの置き場は `users/{uid}` だけ。サインインでやることは uid を保つか、uid を乗り換えるかのどちらかで、乗り換えるときは前の uid のデータを見捨てる。マージはしない。

判定に使うのは Auth の情報だけで、`users/{uid}` にデータがあるかどうかは判定しない。その credential が既に Firebase アカウントに使われているかどうかを見る。

| 状況 | 挙動 |
|---|---|
| credential が未使用 | `linkWithCredential` で昇格。uid もデータもそのまま |
| credential が使用済み | 「現在の N 件のタスクは失われます」と警告し、了承後に `signInWithCredential`。ゲスト側のデータは捨てる |

移行先アカウントのタスクが 0 件だった（アカウントを作ったが放置していた）場合もデータは引き継がない。そこは自己責任ということで…。

警告に件数を出してキャンセルできるようにすることで、不意のデータ喪失は防ぐ。

### チュートリアルを認証の手前に置く

チュートリアルはオフラインで動く。その後のログイン画面で「ゲストではじめる」を押したときに、初めて匿名アカウントを作る。これで Phase10 の問題（初回アプリ起動時に通信できないとブラックアウトしたまま）が解決する。

`currentUser` はキャッシュを見る同期メソッドなので通信しないため。（iOS / Android では `Firebase.initializeApp()` の中で永続化されたセッションが復元されるため、その後に読めば値が入っている）

現在の実装だと、`getUser()` の中に `signInAnonymously()` を行っているが、これをログイン画面まで遅延させる。ルーティングは以下のようになる。

| 状態 | 遷移先 |
|---|---|
| `Guest` / `LoggedIn` | ホーム画面 |
| `NoLogin` かつ `onboarding_complete == false` | チュートリアル画面 |
| `NoLogin` かつ `onboarding_complete == true` | ログイン画面 |

`onboarding_complete`（`preference_key.dart` に既存）は「一度もサインインしていない」と「サインアウトした」を区別するために残す。`saveCompletion()` はチュートリアル完了時、`removeCompletion()` はアカウント削除時に呼ぶ。

他端末での削除によるトークン失効した場合は何らかの操作を行ったときにエラーとなるので、これを判定してダイアログを表示し、ログイン画面に移動させる。

### AppUser をネストした sealed にする

```dart
sealed class AppUser {}

/// 未サインイン、またはサインアウト後
final class NoLogin extends AppUser {}

/// サインイン済み。必ず uid を持つ
sealed class SignedInUser extends AppUser {
  String get id;
}

final class Guest extends SignedInUser { ... }     // 匿名
final class LoggedIn extends SignedInUser { ... }  // Google / Apple にリンク済み
```

未ログインのときの値の表現を `null` ではなく `NoLogin` という値にする。ユーザー情報は `Notifier<AppUser>` で受け渡しすることで、Phase3 で全 ViewModel を AsyncValue にしてしまった問題が解決する可能性がある。（要確認）

`SignedInUser` を挟んでおくと、`taskRepositoryProvider` が `id` を持つ型しか受け取らずに済む。
uid のないユーザーからリポジトリを作ろうとするコードが、そもそも書けなくなる。

### UserRepository の問い合わせと命令を分ける

今の `getUser()` は取得の名前をしているのに、ユーザーがいなければ匿名アカウントを作ってしまう。
これが `main()` で通信が走る原因で、「ゲストではじめる」を押したときにだけ作りたい、という要求も表現できない。

```dart
abstract interface class UserRepository {
  /// 永続化されたセッションを読むだけ。副作用なし・通信なし
  Stream<AppUser> watchUser();

  /// 「ゲストではじめる」を押したときにだけ呼ぶ
  Future<SignedInUser> signInAnonymously();

  Future<SignedInUser> signInWithGoogle();
  Future<SignedInUser> signInWithApple();
  Future<void> signOut();
  Future<void> deleteAccount();
}
```

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

## Phase7

- [x] ログイン画面実装に向けてアプリタイトルを決める
- [x] ローカルで行っているロジックを Cloud Functions に移行する
    - Firebase 基盤で複数端末が同一ログインを共有できるようにすると、タスク通知も端末間で共有する必要が生じる。
      ローカル通知だけでは他端末に通知を飛ばせないため、FCM 経由でのプッシュ通知送信が必要になり、その送信トリガーは
      クライアント側でなく Cloud Functions 側に持たせざるを得ない
    - 移行前は `recordExecution` / `updateExecution` / `deleteExecution` / `restoreTask` がいずれもクライアント側で
      `_computeSchedule` を実行し、`lastExecutedAt` / `nextScheduledAt`（`cachedScheduledAt`）をキャッシュフィールドとして
      タスクドキュメントに直接書き込んでいた（`firestore_task_repository_impl.dart`）
    - 移行後は、executions サブコレクションへの書き込みをトリガーにした `onExecutionWritten` が、
      親 `taskDefinitions` の `lastExecutedAt` / `nextScheduledAt` を再計算して書き戻す（クライアントは `_computeSchedule` を持たなくなった）
- [x] `taskType` / `scheduleConfig` の変更時に `nextScheduledAt` が再計算されない不具合を修正する
    - `updateTask` はクライアントで再計算しなくなったが、`executions` を書き換えないため
      `onExecutionWritten` でも拾えず、次に実行を記録するまで古い値が残っていた
    - `taskDefinitions` の書き込みトリガー（`onTaskDefinitionWritten`）を追加した
      （再帰を止めるガードは `schema.md` を参照）
### FCM プッシュ通知（設計）

- <s>同じトリガーに FCM 送信を追加する</s>
  FCM の送信 API に予約配信はなく（`projects.messages.send` は即時送信のみ）、
  `onExecutionWritten` も実行履歴の書き込み時にしか発火しない。通知を送りたいのは未来の
  `nextScheduledAt` から算出した時刻なので、 **Cloud Scheduler による定期実行の Function**（5 分間隔）を
  別に用意し、`notifyAt` を検索キーにして送信対象を引く（詳細は `schema.md`）
- Cloud Tasks でタスクごとに個別のジョブを積む方式も検討したが、入力が変わるたびに
  予約済みジョブの取り消しが必要になり、取り消しと Firestore 書き込みが同一トランザクションに
  入らないため二重送信・送信漏れを原理的に塞げない。「望ましい状態（`notifyAt`）を書いて
  定期的に突き合わせる」方式なら再計算が単なる上書きになり、取り消しが不要になるため採用しない
- `notifyAt` / `lastNotifiedFor` はサーバーだけが読み書きする帳簿なので `taskDefinitions` に置かず
  `users/{uid}/notifications/{taskId}` を新設する。クライアントが `snapshots()` で購読している
  ドキュメントに送信記録を書くと、表示が変わらないのに全端末へ再配信され、
  タスク件数ぶんの読み取りが課金されてしまうため

### FCM プッシュ通知（PR の区切り）

区切りの原則は3つ。**単独でマージしても壊れない**こと、**ローカル通知を最後まで生かす**こと
（FCM が実機に届くと確認できるまで通知機能を失わない）、**実機依存の詰まりどころを先に潰す**こと
（iOS の APNs で止まると後続が全部止まるため）。

- [ ] **PR1: クライアントのトークン登録**
    - `firebase_messaging` を追加し、トークンの取得・`users/{uid}.fcmTokens` への `arrayUnion` での保存・
      `onTokenRefresh` の購読・iOS の権限リクエストを実装する
    - iOS は APNs キーの登録・Push Notifications の Capability・実機（シミュレータ不可）が要る
    - `NotificationPermissionObserver` は権限の要求元が変わるだけなので、ここでは役割の整理に留める
    - 検証: Firebase コンソールから手動でプッシュを投げ、実機に届くこと
    - ローカル通知はそのまま動かしておく（この PR では何も壊さない）
- [ ] **PR2: 通知設定を Firestore へ移す**
    - `users` に `notificationSetting` / `timezone` を追加する（`SettingsRepository` から切り出す）。
      配色・表示モードなど端末固有の設定は SharedPreferences に残す
    - `timezone` は `flutter_timezone` で取得し、アカウント作成時と通知時刻の変更時にだけ書く
    - `lastActiveAt` もここで足す（使うのは Phase10 の放置アカウント回収）
    - この時点ではローカル通知が新しい設定ソースを読む形にして、動作を保つ
- [ ] **PR3: サーバーの `notifyAt` 帳簿（送信はまだしない）**
    - `nextScheduledAt` / `notificationSetting` / `timezone` から `notifyAt` を算出する純粋関数を
      `schedule.ts` と同じ流儀（Temporal・Firestore を知らない）で書き、テストで固める
    - 書き込み先は `users/{uid}/notifications/{taskId}`。対象外（通知無効・`irregular`・未実行）は
      ドキュメントを作らず、`notifyAt` は `FieldValue.delete()` でフィールドごと消す
      （`null` を入れると範囲クエリにヒットするため。`schema.md` 参照）
    - 再計算の契機は `recalcScheduleCache` の後（そのタスク 1 件）と、
      `users` の `notificationSetting` / `timezone` の変更（そのユーザーの全タスク）
    - 検証: Firestore を直接見て `notifyAt` が期待通りに入る・消えることを確認する
- [ ] **PR4: 送信 Function（Cloud Scheduler 5 分間隔）**
    - `collectionGroup('notifications').where('notifyAt', '<=', now)` で送信対象を引く
    - 重複送信の防止に `lastNotifiedFor` を使う。送信後に `scheduledAt` を書き、`notifyAt` を消す
    - `messaging/registration-token-not-registered` のトークンは `fcmTokens` から `arrayRemove` する
    - **COLLECTION_GROUP スコープのインデックスがここで要る。** コレクショングループクエリの
      インデックスは単一フィールドでも自動作成されないため、`firestore.indexes.json` と
      `firebase.json` の `firestore` セクションをこの PR で用意する
    - 検証: 実際にタスクの予定日を近づけて、実機に通知が届くこと
- [ ] **PR5: ローカル通知の廃止**
    - `flutter_local_notifications` による通知登録を廃止する（`TaskNotificationSync` /
      `TaskNotificationSyncNotifier` / `NotificationPermissionObserver` の役割を見直す）
    - FCM が実機に届くと確認できた後にだけ行う

## Phase8

ろぐいn主題は認証基盤の作り替え。SQLite / LocalUser を捨てて匿名認証に一本化し、Phase9 のログイン画面が
乗る土台を用意する。ソーシャルログインはまだ入れず、全員が匿名（`Guest`）のまま新構造に載せ替える。
旧 Phase10 の「起動時ブラックアウト」もここで閉じる。

- [ ] `AppUser` を `NoLogin` / `SignedInUser`（`Guest` / `LoggedIn`）の sealed 階層に作り替える
  - `LocalUser` を削除し、`SQLiteTaskRepositoryImpl` と drift を削除する
  - `LocalUserRepository` も不要になり、`UserRepository` の実装は 1 つになる
- [ ] `UserRepository` から `getUser()` を廃止し、問い合わせ（`watchUser()`）と命令（`signInAnonymously()` 等）を分ける
  - `getUser()` は取得の名前でありながら匿名アカウントを作る副作用を持っており、これが起動時ブラックアウトの原因
- [ ] `currentUserProvider` を `authStateChanges()` ベースの `Stream<AppUser>` に作り替え、
      `taskRepositoryProvider` を `SignedInUser` の下流に置く
  - 併せて、ホーム画面到達時点でユーザーの存在が保証されるなら ViewModel 群を `AsyncNotifier` から
    戻せる可能性がある（Phase3 で非同期化したもの）。実際に見てから判断する
- [ ] `main()` から匿名サインインを外し、復元済みの認証状態から初期ルートを決める
  - 読み取りは通信を伴わないため失敗しない。スプラッシュは `runApp()` の直前に 1 度だけ消す
  - ルーティングは 3 分岐（`Guest`/`LoggedIn` → ホーム、`NoLogin` × `onboarding_complete` でチュートリアル/ログイン）
  - これで旧 Phase10 の「初回起動 × オフラインで `runApp()` に到達せず白画面」が解決する
    （原因は `getUser()` 内の `signInAnonymously()`。読み取りではなくサインインを外すのが要点）

## Phase9

主題はソーシャルログイン。Phase8 の土台の上にログイン画面を作り、匿名からの昇格を実装する。
ログアウト・アカウント削除は Phase10 に回すため、ここではスタブでよい（**このフェーズはストアに出さない**前提）。

- [ ] ログイン画面を作成する
  - 「ゲストではじめる」・Google・Apple のサインインを用意する
  - <s>ID/Password</s> はサインイン・パスワードリマインドなどの画面が必要になるため廃止
  - サインインは通信を伴うため、失敗したらこの画面上にエラーと再試行を出す（オフライン時の初回起動）
  - 前回サインインしたプロバイダを SharedPreferences に記録し、ログイン画面で示す
    （Apple のプライベートリレー経由で別アカウントを作ってしまう事故を防ぐ）
- [ ] 匿名からの昇格を実装する
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