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

### 通知の誘導はアカウントを作った後に置く

チュートリアルの中に通知許可のステップがあるが、通知設定の置き場は `users/{uid}` になった（Phase7 / PR2）。
アカウント作成をログイン画面まで遅らせると、**uid がない状態で `users/{uid}` に書こうとする**ことになり、
チュートリアルの通知ステップと `fcmTokens` の登録が成立しない。

そこで順序を次のように変える。

```
チュートリアル（オフライン・Firestore に書かない）
  → ログイン画面（「ゲストではじめる」/ Google / Apple）
  → アカウント作成・サインイン
  → users/{uid} の初期化
  → 通知が OFF なら通知 ON の誘導
  → ホーム画面
```

- チュートリアルの通知ステップは、**OS の許可を求めるだけ**にして Firestore には書かない
  （そもそもチュートリアルから通知の項目を外し、下記の誘導に一本化してもよい）
- `users/{uid}` の初期化でまとめて書く：`notificationSetting`（`enabled` は OS の許可状態から決める。
  許可されている＝通知を望んだとみなす）、`timezone`（端末の現在値）、`fcmTokens`、`lastActiveAt`
- 「ユーザーが通知を望んだか」をローカルに退避する必要はない。OS の許可状態がその答えを持っている
- `schema.md` の timezone は「書き込むのは**アカウント作成時**（9:00 ＋ 端末の現在タイムゾーン）」と
  もともと書いてあり、アカウント作成フックの存在を前提にしていた。ここで用意する

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
  AppUser getUser();

  /// 以降の変化を購読する
  Stream<AppUser> watchUser();

  /// 「ゲストではじめる」を押したときにだけ呼ぶ
  Future<Guest> signInAsGuest();

  Future<LoggedIn> signInWithGoogle();
  Future<LoggedIn> signInWithApple();
  Future<void> signOut();
  Future<void> deleteAccount();
}
```

サインインの各メソッドは `FirebaseAuth` の API 名をそのまま持ち上げず、アプリの語彙で名前を付ける。
匿名認証は「ゲストではじめる」という 1 つの操作としてしか現れないため `signInAsGuest()` とし、
戻り値も必ず匿名アカウントになることを型で示す。

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

- [x] **PR1: クライアントのトークン登録**
    - `firebase_messaging` を追加し、トークンの取得・`users/{uid}.fcmTokens` への `arrayUnion` での保存・
      `onTokenRefresh` の購読・iOS の権限リクエストを実装する
    - iOS は APNs キーの登録・Push Notifications の Capability・実機（シミュレータ不可）が要る
    - `NotificationPermissionObserver` は権限の要求元が変わるだけなので、ここでは役割の整理に留める
    - 検証: Firebase コンソールから手動でプッシュを投げ、実機に届くこと
    - ローカル通知はそのまま動かしておく（この PR では何も壊さない）
- [x] **PR2: 通知設定を Firestore へ移す**
    - `users` に `notificationSetting` / `timezone` を追加する（`SettingsRepository` から切り出す）。
      配色・表示モードなど端末固有の設定は SharedPreferences に残す
    - `timezone` は `flutter_timezone` で取得し、アカウント作成時と通知時刻の変更時にだけ書く
    - `lastActiveAt` もここで足す（使うのは Phase10 の放置アカウント回収）
    - この時点ではローカル通知が新しい設定ソースを読む形にして、動作を保つ
- [x] **PR3: サーバーの `notifyAt` 帳簿（送信はまだしない）**
    - `nextScheduledAt` / `notificationSetting` / `timezone` から `notifyAt` を算出する純粋関数を
      `schedule.ts` と同じ流儀（Temporal・Firestore を知らない）で書き、テストで固める
    - 書き込み先は `users/{uid}/notifications/{taskId}`。対象外（通知無効・`irregular`・未実行）は
      ドキュメントを作らず、`notifyAt` は `FieldValue.delete()` でフィールドごと消す
      （`null` を入れると範囲クエリにヒットするため。`schema.md` 参照）
    - 再計算の契機は `recalcScheduleCache` の後（そのタスク 1 件）と、
      `users` の `notificationSetting` / `timezone` の変更（そのユーザーの全タスク）
    - 検証: Firestore を直接見て `notifyAt` が期待通りに入る・消えることを確認する
- [x] **PR4: 送信 Function（Cloud Scheduler 5 分間隔）**
    - `collectionGroup('notifications').where('notifyAt', '<=', now)` で送信対象を引く
    - 重複送信の防止に `lastNotifiedFor` を使う。送信後に `scheduledAt` を書き、`notifyAt` を消す
    - `messaging/registration-token-not-registered` のトークンは `fcmTokens` から `arrayRemove` する
    - **COLLECTION_GROUP スコープのインデックスがここで要る。** コレクショングループクエリの
      インデックスは単一フィールドでも自動作成されないため、`firestore.indexes.json` と
      `firebase.json` の `firestore` セクションをこの PR で用意する
    - 検証: 実際にタスクの予定日を近づけて、実機に通知が届くこと
- [x] **PR5: ローカル通知の廃止**
    - `flutter_local_notifications` による通知登録を廃止する（`TaskNotificationSync` /
      `TaskNotificationSyncNotifier` / `NotificationPermissionObserver` の役割を見直す）
    - FCM が実機に届くと確認できた後にだけ行う

## Phase8

主題は認証基盤の作り替え。SQLite / LocalUser を捨てて匿名認証に一本化し、ログイン画面までを用意する。
ソーシャルログインのボタンは置くが配線はダミーで、全員が匿名（`Guest`）のまま新構造に載せ替える。
旧 Phase10 の「起動時ブラックアウト」もここで閉じる。

### 設計の決定事項

#### `AppUser` は同期で読める

`FirebaseAuth.instance.currentUser` はキャッシュを見る同期 getter で通信しない
（`Firebase.initializeApp()` の中で永続化されたセッションが復元されるため、その後に読めば値が入っている）。
つまり初期値を `await` せずに作れる。ここがこの Phase の設計全体の土台になる。

```dart
abstract interface class UserRepository {
  /// 永続化されたセッションを読むだけ。副作用なし・通信なし
  AppUser getUser();

  /// 以降の変化を購読する
  Stream<AppUser> watchUser();

  /// 「ゲストではじめる」を押したときにだけ呼ぶ
  Future<Guest> signInAsGuest();

  Future<LoggedIn> signInWithGoogle();
  Future<LoggedIn> signInWithApple();
  Future<void> signOut();
  Future<void> deleteAccount();
}
```

`getUser()` は名前を残し、匿名アカウントを作る副作用だけを取り除く。問題だったのは取得と生成が
1 つのメソッドに同居していたことであって、名前そのものではない。

#### `currentUserProvider` は `Notifier<AppUser>` にする（`AsyncNotifier` にしない）

Riverpod では `build()` が `Future` を返すかどうかで消費側が `AsyncValue` を被るかが決まる。
初期値が同期で作れる以上、`AsyncNotifier` にする理由がない。

```dart
@riverpod
class CurrentUser extends _$CurrentUser {
  @override
  AppUser build() {
    final repository = ref.watch(userRepositoryProvider);
    final subscription = repository.watchUser().listen((user) => state = user);
    ref.onDispose(subscription.cancel);
    return repository.getUser();  // 同期・通信なし
  }
}
```

更新の出所が非同期（Stream）であることと、初期値が同期であることは別問題で、型に現れるのは後者だけ。
Phase3 で全 ViewModel が `AsyncNotifier` になったのは `getUser()` の中で通信していたためなので、
根元から通信を外せば連鎖ごと解ける（PR5）。

リポジトリを直接呼ばずプロバイダを挟むのは、変更を Riverpod の依存グラフに載せるため。
`ref.watch(userRepositoryProvider).getUser()` と書くとリポジトリのインスタンスは不変なので二度と
再構築されず、ログアウトしても `taskRepositoryProvider` が古い uid を掴んだままになる。

#### ルーティングは go_router の `redirect` に載せない

初期ルートは `main()` が `getUser()` を 1 度読んで決め、以降は命令的に遷移する。
ユーザーが切り替わる契機は「ゲスト作成」「ログアウト」「アカウント削除」しかなく、いずれも遷移先を
知っているコードが引き起こすため、受動的に待ち受ける必要がない。他端末での削除によるトークン失効も、
操作時のエラーとして検知する明示的な経路になる。

`redirect` に載せると、アカウント作成直後は `Guest` になるため「`SignedInUser` → ホーム」の規則が
通知設定の誘導画面を飛ばしてしまい、フロー中のルートを除外する例外を書く羽目になる。
ログアウト時に「遷移してから `signOut()`」の順序が取れなくなるのも `redirect` を置いた場合。

#### `taskRepositoryProvider` は `SignedInUser` しか受け取らない

`NoLogin` を渡されたら `StateError` を投げる。ただしログアウト時に「ログイン画面へ遷移してから
`signOut()` を呼ぶ」順序にすれば、ホーム画面が破棄済みで `taskRepositoryProvider` を監視している者が
いないため、この経路には入らない（Phase10 で実装する際の順序）。

### PR の区切り

原則は Phase7 と同じで、**単独でマージしても壊れない**こと。認証は温まったセッションでは何も起きず
初回起動でだけ壊れるため、各 PR の検証には新規インストール（セッションなし）・再起動（セッションあり）・
**機内モード × 新規インストール** を含める。

- [x] **PR1: 型の作り替えと SQLite / drift の削除**
    - `AppUser` を `NoLogin` / `SignedInUser`（`Guest` / `LoggedIn`）の sealed 階層にする
    - `LocalUser` / `LocalUserRepository` / `SQLiteTaskRepositoryImpl` / drift 一式を削除する
    - `taskRepositoryProvider` / `FirestoreUserSettingsRepository` / `FirestoreNotificationTokenRepository` の
      ユーザー種別による分岐が消える
    - この時点では `getUser()` が匿名アカウントを作り続けるので、`NoLogin` は到達しない型として入るだけ
    - 未リリースのため、ローカルに残っている drift のデータは捨ててよい
- [x] **PR2: `UserRepository` の問い合わせと命令を分ける（挙動は変えない）**
    - `getUser()` から匿名サインインの副作用を取り除き、`watchUser()` と `signInAsGuest()` を足す
    - `currentUserProvider` を `Notifier<AppUser>` にする
    - **`main()` は `NoLogin` のときだけ `signInAsGuest()` を明示的に呼び続ける。** 挙動を変えないための
      措置で、これを外すのは PR4。無条件に呼ばないのは、`FirebaseAuth.signInAnonymously()` が
      「すでに匿名ユーザーがいればそれを返すが、匿名でないユーザーがいる場合はサインアウトさせる」
      仕様のため。Phase8 では `LoggedIn` に到達しないが、Phase9 で social login が入った瞬間に
      「起動しただけでログイン済みユーザーが匿名に置き換わる」壊れ方をする
    - **`taskRepositoryProvider` のシグネチャは `Future` のまま維持する。** ここで同期化すると全 ViewModel が
      一斉にコンパイルエラーになり、PR が認証と無関係な差分で埋まる
    - `build()` の中で `state` に代入することは Riverpod では許されないが、Stream の配送は購読時に値が
      あっても必ずマイクロタスク以降になるため、`listen()` のコールバックが `build()` 中に走ることはない
    - `authStateChanges()` は購読時に現在値を 1 回流すため、初期値は `getUser()` と合わせて 2 度届く。
      `AppUser` の値等価（PR1 で実装済み）がこの 2 度目を吸収する。`.skip(1)` で捨てる方法は
      「必ず即座に流す」前提に依存し、値がずれた場合に本物の変化を落とすので採らない
    - `watchUser()` に `SettingsRepositoryImpl.watchHomeDisplayMode()` のような
      「冒頭で `yield` して現在値を足す」処理は**要らない**。初期値は `getUser()` が供給しており、
      Stream に求めているのは以降の変化だけだから。あちらで `yield` が要るのは、土台の
      `StreamController` が現在値を再生せず、購読者が他に初期値を得る手段を持たないため
- [x] **PR3: ログイン画面とアカウント作成フロー**
    - ログイン画面を作る。「ゲストではじめる」だけを配線し、Google / Apple のボタンはダミーで置く
    - サインインは通信を伴うため、失敗したらこの画面上にエラーと再試行を出す
    - 作成後、通知が OFF なら通知設定の誘導画面を挟んでからホームへ。戻る操作はキャンセル扱いでホームへ
      進み、以降は設定画面から明示的に有効化する
    - チュートリアルから通知のステップを削除する。書き込み先の uid がない時点で許可を求めても
      `users/{uid}` に保存できないため、通知への誘導はアカウント作成後の画面に一本化する
    - <s>アカウント作成時に `users/{uid}` を初期化する</s> **初期化はしない。**
      `users/{uid}` は通知を有効にしたときに初めて作られる
        - `notificationSetting` は未設定なら `NotificationSetting.fromMap(null)` がデフォルト（通知 OFF）を
          返すため、作成時に書いても読み取り結果が変わらない
        - チュートリアルで許可を求めなくなったので、作成時点の OS の許可状態は必ず未回答になる。
          「許可状態から `enabled` を決める」は常に `false` を書くだけになり、`fcmTokens` も必ず空になる
        - `timezone` は通知の誘導画面・設定画面の `setNotificationSetting()` が
          `notificationSetting` と一緒に書く。通知が無効なうちは送信対象にならないので、
          先に書いておく必要がない
        - `lastActiveAt` は起動のたびに `updateLastActiveAt()` が書く
        - これにより `additionalUserInfo.isNewUser` での分岐も不要になる。既存アカウントの設定を
          初期値で潰さないための備えだったが、そもそも初期値を書かない
        - ドキュメントが存在しなくても、購読はデフォルト値を返し、サブコレクションも作れる
- [x] **PR4: `main()` から匿名サインインを外す**
    - `main()` は `initializeApp()` → `getUser()` で初期ルートを決める → スプラッシュを消す → `runApp()`
    - ルーティングは 3 分岐（`Guest`/`LoggedIn` → ホーム、`NoLogin` × `onboarding_complete` で
      チュートリアル / ログイン画面）
    - `registerToken()` / `updateLastActiveAt()` をユーザーがいる前提の場所に置き直す。`NoLogin` で
      起動しうるようになるため、現在の `main()` の呼び出し位置では壊れる
    - **ここで旧 Phase10 の「初回起動 × オフラインで `runApp()` に到達せず白画面」が解決する**
      （原因は `getUser()` 内の `signInAnonymously()`。読み取りではなくサインインを外すのが要点）
    - 検証: 機内モード × 新規インストールでチュートリアルまで到達すること
- [x] **PR5: `AsyncNotifier` の巻き戻し**
    - `taskRepositoryProvider` を同期の `Provider` にし、Phase3 で `AsyncNotifier` にした ViewModel 群を
      `Notifier` に戻す
    - 機械的だが大量の差分になるため、認証の正しさとは分けて最後に置く
    - **着手条件は PR4 の検証完了。** 混ぜるとリグレッションの切り分けができなくなる

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