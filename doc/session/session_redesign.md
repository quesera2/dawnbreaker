# セッション管理の再設計

サインイン状態をリアクティブに持つのをやめ、決まったタイミングで非リアクティブに確かめる形に改める。

## 背景

### 今の作り

- `currentUserProvider` が `authStateChanges()` を購読し、`NoLogin` / `SignedInUser` を流す
- uid に属するリポジトリ（`taskRepositoryProvider`・`userSettingsRepositoryProvider`・`notificationTokenRepositoryProvider`）は
  `ref.watch(currentUserProvider)` で作られ、`NoLogin` では例外を投げる
- 他端末での削除や定期削除バッチでアカウントが消えると、トークン更新の失敗で SDK がローカルでサインアウトし、
  `currentUserProvider` が `NoLogin` になる。その瞬間にリポジトリと ViewModel が作り直されて build ごと失敗するため、
  サインイン必須の画面を `ShellRoute`（`SignedInShell`）でまとめ、配下を外してから `SessionExpiredMessage` を出している

### 問題

元凶は、セッションをリアクティブな値として持っていること。

- セッションの終わりが「値の変化」として下流へ伝わり、終わるべき画面が作り直されようとして壊れる
- それを防ぐために、ビルド順（祖先のシェルが同じフレームで先に子を外す）という暗黙の性質に頼っている
- シェルは自分で選んだログアウトとセッション切れを `ModalRoute.isActive` で推測して見分けている
- Firestore の購読エラーに受け手がない。`allTaskItems()` / `watchTaskById()` に `handleError` がなく、
  `combineLatest3` / `combineLatest4` も `onError` を受けないため、permission-denied が未処理のエラーとして
  `PlatformDispatcher.onError` から Crashlytics に `fatal: true` で記録されうる

なお 898e80b より前は「操作時の `TaskNotSignedInException` を `SessionExpiredMessage` に変換する」形だった。
これが破綻したのは操作時に検知する方針のせいではなく、`currentUserProvider` がリアクティブで、操作より先に
画面が壊れていたためである。リアクティブさを取り除けば、操作時の検知はそのまま成立する。

## 方針

1. **セッションは非リアクティブに持つ。** `currentUserProvider` は `authStateChanges()` を購読せず、
   アプリがユーザーを切り替えたときに明示的に読み直す
2. **R はサイレント、CUD はダイアログ。** 購読（`snapshots()`）の失敗はユーザーには見せず、non-fatal でログに残す。
   CUD の失敗がセッション切れによるものなら、セッション切れのダイアログを出す
3. **起動時と復帰時にセッションを確かめる。** CUD をしなくても、サーバー側で消されたことに気づけるようにする
4. **セッション切れは一度きりのイベントとして 1 か所で受ける。** ダイアログを出すのはアプリのルートの 1 か所だけにする
5. **アプリ起点のサインアウトは今の形を保つ。** ログアウト・アカウント削除は、先に画面から離れてからサインアウトする

## 詳細

### セッションの確認

`UserRepository` に 2 種類の確認を足す。

| 確認 | 中身 | 通信 | 使う場所 |
|---|---|---|---|
| ローカル | `FirebaseAuth.currentUser != null` | なし | CUD の前後 |
| サーバー | `currentUser.reload()` | あり（Auth API。Firestore の課金はかからない） | 起動時・復帰時 |

サーバー確認の結果は 3 値で返す。

- `valid` — セッションは生きている
- `expired` — `reload()` が `user-not-found` / `user-disabled` / `user-token-expired` で失敗した、または `currentUser` が既に null
- `unknown` — 通信エラーなど。オフラインをセッション切れと取り違えないよう、何もしない

### 起動時・復帰時の確認

定期削除バッチ（`cleanupInactiveAnonymousAccounts`）が消すのは、`lastRefreshTime` が保持日数より古い匿名ユーザー。
`lastRefreshTime` はアプリを前面で使っている間 SDK が進めるため、**バッチに消される時点でユーザーはアプリを使っていない**。
消されたあとにユーザーが最初に触れるのは、必ずコールドスタートかバックグラウンドからの復帰になる。

- `NotificationPermissionObserver` と同じ形の `SessionObserver`（keepAlive）を置く
- 起動時（`AppStartup.startDeferredWork`）と `AppLifecycleState.resumed` でサーバー確認を行う
- アプリがサインイン中だと思っている（`currentUserProvider` が `SignedInUser`）ときだけ確かめる。
  ログイン画面やチュートリアルにいる間は確かめない
- `expired` ならセッション切れのイベントを流す

コールドスタートでは、初期画面はローカルのセッションで `/home` に決まり、そのあと確認が `expired` を返してホームの上にダイアログが出る。
バッチは `users/{uid}` を消してから Auth のユーザーを消すため、ホームは空かキャッシュの残りが見える。
ダイアログで覆われ、OK でログイン画面へ送るので、この間の表示は問わない。

拾えないのは、この端末を前面で開いている最中に本人が別の端末で削除したとき。次の CUD か次の復帰までダイアログは出ないが、
本人の操作なので許容する。

### R：購読はサイレントに終わる

- `allTaskItems()` / `watchTaskById()` に `handleError` を足し、`TaskLoadException` に変換する
  （`watchNotificationSetting()` は既にそうなっている）
- `combineLatest3` / `combineLatest4` に `onError` を足し（`combineLatest2` と揃える）、呼び出し側は必ず渡す
- ViewModel は `logger.e` で残すだけで、ダイアログもスナックバーも出さない。画面は最後に受け取った値のまま残る
- permission-denied でセッション切れを判定しない、という今の方針は変えない

### CUD：セッション切れならダイアログ

- リポジトリの CUD は、書く前にローカル確認を行い、セッションがなければ `XxxSessionExpiredException` を投げる。
  オフラインで書き込みの完了を待ち続けることを避けるため、事前に確かめる
- 書き込みが失敗したときもローカル確認を行い、セッションがなくなっていれば同じ例外に変える
- 対象は `TaskRepository` の CUD と `UserSettingsRepository` の書き込み。
  例外はリポジトリごとに定義する（`AGENTS.md`「エラー処理」）。今の `XxxNotSignedInException` を置き換える
- 例外を投げるときに、セッション切れのイベントも流す（下記）。ViewModel はこの例外では自前のエラーダイアログを出さず、
  進捗表示を止めるだけにする

### セッション切れのイベント

- `SessionExpiryNotifier`（keepAlive）が `SessionExpiredEvent?`（他のイベントと同じく uuid の id を持つ）を持つ
- 起動時・復帰時の確認と、CUD の確認の両方がここへ流す
- 一度流したら、次にサインインするまで重ねて流さない
- アプリのルートの 1 か所が `ref.listen` し、`SessionExpiredMessage` を出す
- OK の後は `context.go('/login', extra: const LoginParam(executeLogout: true))` で、ログアウトと同じ経路に乗せる。
  遷移を待ってからの `deleteToken()` と `signOut()` をそのまま使えるため、消えたアカウント宛の通知も止まる

状態ではなくイベントなので、下流が作り直される連鎖は起きない。

### ユーザーの切り替えは明示的に読み直す

- `currentUserProvider` は `getUser()` を返すだけにし、`watchUser()` の購読をやめる
- ユーザーを切り替えたコードが、直後に `ref.invalidate(currentUserProvider)` する

| 契機 | 読み直す場所 |
|---|---|
| ゲストとして開始 | `LoginViewModel` のサインイン完了処理 |
| Google でサインイン・昇格 | 同上（今も `_registerToken` が読み直している） |
| 別アカウントへの乗り換え | 同上 |
| ログアウト | `LoginViewModel.signOut` の `signOut()` 直後 |
| アカウント削除 | `OnboardingViewModel.finishAccountDeletion` の `signOut()` 直後 |

- 昇格では uid が変わらず `Guest` → `LoggedIn` だけが変わる。uid に属するリポジトリは
  `ref.watch(currentUserProvider.select(...))` で uid だけを見て、昇格で作り直されないようにする

### シェルをなくす

- `NoLogin` が外から流れてこなくなるため、`SignedInShell` と `ShellRoute` は役目を終える。ルートを平らに戻す
- リポジトリの provider が `NoLogin` で例外を投げるのは残す。サインインしていないのにタスクを読もうとするのは
  プログラムの誤りであり、その不変条件を表している

### 変えないもの

- ログアウト・アカウント削除で「先に遷移し、入場アニメーションを待ってからサインアウトする」流れ
  （`LoginParam.executeLogout`・`AfterTransitionMixin`・`finishAccountDeletion`）
- 初期画面を `main()` で 1 度決めること。`redirect` は使わない
- 端末に残る Firestore のキャッシュの扱い（`doc/firestore/firebase_design.md`）

## タスク

上から順に、1 つずつ PR にできる単位に分けている。T6 と T7 は同時か、T6 → T7 の順で入れる
（T7 を先に入れると、外から来る `NoLogin` で画面が壊れる問題が戻る）。

### T1. 購読エラーを受け止める（R サイレント）

- `allTaskItems()` / `watchTaskById()` に `handleError` を足して `TaskLoadException` に変換する
- `combineLatest3` / `combineLatest4` に `onError` を足す
- `HomeViewModel`・`SettingsViewModel`・`AppDetailViewModel` で `onError` を渡し、`logger.e` で残す
- テスト：購読がエラーを流しても未処理のエラーにならず、画面の状態が変わらないこと

他のタスクと独立しており、今の設計のままでも Crashlytics に fatal で記録される問題をなくせる。

### T2. セッション確認の API

- `UserRepository` にローカル確認（`hasSession()`）とサーバー確認（`verifySession()` → `valid` / `expired` / `unknown`）を足す
- `FirebaseUserRepository` で実装する。`reload()` のエラーコードを 3 値に振り分ける
- テスト：エラーコードごとの振り分け。テスト用の Fake にも足す

### T3. セッション切れのイベントとダイアログ

- `SessionExpiryNotifier` と `SessionExpiredEvent` を作る。重ねて流さないこと、サインインで解除されることまで含める
- アプリのルートで `ref.listen` して `SessionExpiredMessage` を出し、OK で `executeLogout` の経路へ送る
- `SessionExpiredMessage` のコメントを新しい出どころに合わせる
- テスト：Notifier の単体テスト

### T4. 起動時・復帰時の確認

- `SessionObserver`（keepAlive、`WidgetsBindingObserver`）を作り、`AppStartup.startDeferredWork` で起動する
- 起動時と `resumed` で、サインイン中のときだけ `verifySession()` を呼び、`expired` でイベントを流す
- テスト：`valid` / `expired` / `unknown` と未サインインのそれぞれで、イベントを流すかどうか

### T5. CUD でのセッション確認

- `TaskRepository` の CUD と `UserSettingsRepository` の書き込みに、事前と失敗時のローカル確認を入れる
- `TaskSessionExpiredException` / `UserSettingsSessionExpiredException` を定義し、`XxxNotSignedInException` を整理する
- 例外を投げるときにイベントを流す（リポジトリに `SessionExpiryNotifier` への通知口を注入する）
- 各 ViewModel は、この例外では自前のエラーダイアログを出さず進捗表示を止める
- テスト：セッションがないときの CUD が例外とイベントになること、ViewModel が自前のダイアログを出さないこと

### T6. `currentUserProvider` を非リアクティブにする

- `currentUserProvider` から `watchUser()` の購読を外す（`UserRepository.watchUser()` も不要なら消す）
- ユーザーを切り替える 5 か所に `ref.invalidate(currentUserProvider)` を入れる
- uid に属するリポジトリの provider を、uid だけを `select` する形にする
- `SettingsViewModel` の `ref.listen(currentUserProvider)`（昇格後の表示更新）が読み直しで動くことを確かめる
- `AppUser` の値等価のコメント（`watchUser()` から同じ値が 2 度来る件）を見直す
- テスト：`current_user_provider_test` の書き換え、各サインイン経路で読み直されること

### T7. シェルをなくす

- `SignedInShell` を消し、`app_router.dart` の `ShellRoute` を平らなルートに戻す
- テスト：ルーティングの既存テストが通ること

### T8. ドキュメント

- `doc/firestore/firebase_design.md` の「ルーティングは go_router の `redirect` に載せない」と
  「他端末で削除されたことの検知」を新しい形に書き換える
- この文書の「背景」以外を `firebase_design.md` に取り込み、この文書は消すか、経緯として残す

## 実機での確認

- バックグラウンドの間に Firebase コンソールから匿名ユーザーを消す → 復帰でダイアログ → OK でログイン画面
- 消したあとにコールドスタート → ホームの上にダイアログ
- 機内モードで復帰 → 何も出ない。オンラインに戻して再度復帰 → ダイアログ
- SDK がローカルでサインアウトしたあとにタスクを保存 → ダイアログ。Crashlytics に fatal が出ないこと
- 設定からログアウト・アカウント削除 → ダイアログが出ないこと
- ゲストから Google へ昇格 → ホームのデータが作り直されず、設定の表示がログイン済みに変わること
