# Firestore Schema

## コレクション構造

```
users/
  {userId}/
    fields...（notificationSetting, fcmTokens, timezone, lastActiveAt）
    taskDefinitions/
      {taskDefinitionId}/
        fields...
        executions/
          {executionId}/
            fields...
    notifications/
      {taskDefinitionId}/
        fields...
```

`taskDefinitions` はクライアントが読み書きするデータ、`notifications` は Cloud Functions だけが
読み書きするサーバー側の帳簿。クライアントが `snapshots()` で購読するドキュメントに
通知の送信記録を書き込むと、表示が変わらないのに全端末へ再配信され読み取りが課金されるため分けている。

## ドキュメント定義

### users

プッシュ通知の送信に必要な設定・宛先と、放置アカウント回収のための最終アクティブ日時を持つ。
ドキュメント ID は Firebase Auth の uid。匿名ユーザー・リンク済みユーザーのいずれも同じ構造。

#### notificationSetting

通知設定（map）。クライアントの `NotificationSetting` モデルと同じフィールド構成。
このアプリでは通知設定を端末ローカルではなく Firestore に持つ（送信主体が Cloud Functions のため）。
未設定（`null`）の場合は通知しない。

| フィールド | 型 | 説明 |
|---|---|---|
| enabled | boolean | 通知の有効・無効 |
| notifyDay | string | `today` / `yesterday`。`nextScheduledAt` から見た通知日のオフセット |
| hour | number | 通知時刻（時）0-23 |
| minute | number | 通知時刻（分）0-59 |

#### fcmTokens

アカウントに紐づく FCM デバイストークンの一覧（`string[]`）。複数端末ログインを想定し配列で持つ。

- クライアントはトークン取得時・更新時（`onTokenRefresh`）に `arrayUnion` で自身のトークンを追加する
- ログアウト時は `signOut()` の**前に** `arrayRemove` で取り除く。順序が逆だとセキュリティルールで書き込めない
- 送信時に `messaging/registration-token-not-registered` が返ったトークンは、送信元の Function が `arrayRemove` で回収する

ログアウト時の削除を怠ると、同一端末に後からサインインした別ユーザーへ前ユーザーの通知が届く。

#### timezone

IANA タイムゾーン ID（`Asia/Tokyo` など）。`notificationSetting` の `hour` / `minute` は
このタイムゾーン上の壁時計時刻として解釈する。クライアントが `flutter_timezone` で取得した値を書き込む。

書き込むのは `notificationSetting` を書くときだけで、常にセットで書く。初回は通知を有効にしたとき
（誘導画面か設定画面）で、以降は通知時刻を変更したとき。
1 ユーザー 1 タイムゾーンとし、アプリ起動・レジュームごとの追随はしない。
そのため、タイムゾーンをまたいで移動したユーザーの通知は、通知時刻を再設定するまで
移動前の壁時計時刻で送られる（仕様）。

#### lastActiveAt

最終アクティブ日時（timestamp）。放置された匿名アカウントを定期実行の Function が回収する際の判定に使う。
`isAnonymous` ではなくこのフィールドを基準にする。

### taskDefinitions

タスクの定義情報とキャッシュフィールド。

| フィールド | 型 | 説明 |
|---|---|---|
| taskType | string | `irregular`（不定期）/ `period`（周期）/ `scheduled`（固定間隔）|
| icon | string | アイコン識別子 |
| name | string | タスク名 |
| furigana | string | ふりがな（ソート用） |
| color | string | `none` / `red` / `blue` / `yellow` / `green` / `orange` |
| scheduleConfig | map? | `scheduled` のみ設定。`irregular` / `period` は null |
| scheduleConfig.scheduleValue | number | 固定間隔の数値 |
| scheduleConfig.scheduleUnit | string | `day` / `week` / `month` |
| lastExecutedAt | timestamp? | 最終実行日時（キャッシュ）。初回実行前は null |
| nextScheduledAt | timestamp? | 次回実行予定日時（キャッシュ）。初回実行前および `irregular` は常に null |

**taskType ごとの nextScheduledAt 計算方法**

| taskType | 計算方法 |
|---|---|
| `irregular` | 常に null |
| `period` | 直近 10 件の実行間隔（日数）の単純平均を `lastExecutedAt` に加算 |
| `scheduled` | `lastExecutedAt + scheduleConfig`（固定値） |

**なぜ nextScheduledAt をキャッシュするのか**

`scheduled` は `lastExecutedAt` があればクライアントで導出できるが、`period` は直近 10 件の
`executions` を読まないと求められない。ホーム画面は全タスクを表示するため、導出させると
タスク N 件 × 履歴 10 件のドキュメント読み取りが毎回発生する（#142 で解消した問題そのもの）。
ドキュメント単位課金を避けるために事前計算して 1 フィールドに畳んでいる。

**キャッシュの更新タイミング**

`lastExecutedAt` / `nextScheduledAt` は以下のタイミングで Cloud Functions が再計算・書き戻す：

- 実行の追加・更新・削除（`onExecutionWritten`）
- `taskType` / `scheduleConfig` の変更（`onTaskDefinitionWritten`）

`period` の `nextScheduledAt` 再計算時は直近 10 件の `executions` を取得して使用する。
削除時は削除対象が最新かどうかに関わらず、常に直近 10 件を再取得して再計算する。

`taskType` の変更は `scheduled` が絡まなくても再計算する。`irregular` → `period` は
`nextScheduledAt` が null のままになり（次に実行を記録するまで予定日が表示されない）、
`period` → `irregular` は古い `nextScheduledAt` が残る。後者は表示には出ないが、
`notifications` の `notifyAt` の算出元になるため放置しない。

`taskType` / `scheduleConfig` の変更は `executions` を書き換えないため `onExecutionWritten` では拾えず、
`taskDefinitions` の書き込みトリガーが別に必要になる。このとき `nextScheduledAt` は表示に使うので
`taskDefinitions` 自身に書き戻すことになり、その書き込みがトリガーを再発火させる。

そのため、変更前後で `taskType` / `scheduleConfig` が同一なら何もせず抜けるガードを入れる。
ユーザーの編集による発火は通り抜け、キャッシュ書き戻しによる 2 回目の発火はここで止まる
（`onExecutionWritten` が `nextScheduledAt` を書き戻したときの発火も同様に素通りする）。
Firestore のトリガーは at-least-once のため、いずれにせよ冪等に書く必要がある。

### executions（taskDefinitions のサブコレクション）

タスクの実行履歴。

| フィールド | 型 | 説明 |
|---|---|---|
| executedAt | timestamp | 実行日時 |
| comment | string? | メモ（任意）|

親タスクの ID はドキュメントパス（`taskDefinitions/{taskDefinitionId}/executions/...`）から得られるため、フィールドとしては持たない。

### notifications

プッシュ通知の送信に使うサーバー側の帳簿。ドキュメント ID は対応する `taskDefinitionId`。
Cloud Functions だけが読み書きし、クライアントは参照しない（セキュリティルールで読み書きを禁止する）。

| フィールド | 型 | 説明 |
|---|---|---|
| notifyAt | timestamp | 通知時刻。送信対象を引くための検索キー。**対象外ならフィールドごと削除する** |
| scheduledAt | timestamp | この `notifyAt` の算出元となった `nextScheduledAt` の値。`notifyAt` と同時に削除する |
| lastNotifiedFor | timestamp? | 通知済みの `scheduledAt` の値。重複送信の防止に使う |

通知対象のないタスク（通知が無効・`irregular`・未実行）はドキュメントを作らない。

対象だったタスクが対象外に変わったときは `notifyAt` / `scheduledAt` を削除するが、
ドキュメント自体は消さない。`lastNotifiedFor` を残すためで、これを消すと
通知設定を OFF → ON したときに `nextScheduledAt` が変わっていないタスクの
`notifyAt` が同じ過去時刻に再計算され、送信済みの通知がもう一度飛ぶ。
通知設定はユーザー単位なので、OFF/ON 一回で期限切れタスク全部が再通知されることになる。

その結果、一度も通知されないまま対象外になったタスクにはフィールドのないドキュメントが残る。
タスク数が上限で、タスク削除時に `onTaskDefinitionDeleted` がドキュメントごと消すため許容する。

`notifyAt` を `null` にしてはいけない理由と再計算のタイミングは「プッシュ通知」を参照。

## プッシュ通知

FCM の送信 API に予約配信はない（`projects.messages.send` は即時送信のみ）。
そのため Cloud Scheduler による定期実行の Function（5 分間隔）が、送信すべきタスクを都度引いて送る。

**送信対象の抽出**

`notifyAt` は「`nextScheduledAt` に `notifyDay` のオフセットを加えた日付」の「`hour`:`minute`」を
`users/{userId}.timezone` 上の壁時計時刻として解決した UTC の瞬間。定期実行の Function は
コレクショングループクエリ 1 本で送信対象を引く。

```
collectionGroup('notifications').where('notifyAt', '<=', now)
```

`userId` と `taskDefinitionId` はドキュメントパスから得られる。通知の本文に使うタスク名は
`taskDefinitions/{taskDefinitionId}` を、送信先の `fcmTokens` は `users/{userId}` を、
それぞれ送信時に読んで解決する。

Firestore の範囲比較は型をまたいで行われ `null` は全ての `timestamp` より前に並ぶため、
`notifyAt` に `null` を入れると上記クエリにヒットしてしまう。対象外にするときは
`FieldValue.delete()` で**フィールドごと削除**すること。フィールドが存在しないドキュメントは
インデックスに載らず、クエリ結果にも読み取りコストにも現れない。

**notifyAt の再計算タイミング**

| 契機 | 対象 |
|---|---|
| `nextScheduledAt` の変化（実行履歴の追加・更新・削除） | そのタスク 1 件 |
| `taskType` / `scheduleConfig` の変更 | そのタスク 1 件 |
| `notificationSetting`（`timezone` を含む）の変更 | そのユーザーの全タスク |

`fcmTokens` の増減では再計算しない。送信先は送信時に `users/{userId}` を読んで解決するため、
端末が増減しても既存の `notifyAt` は正しいまま。

**lastNotifiedFor（重複送信の防止）**

送信対象は「`notifyAt` を過ぎており、かつ `lastNotifiedFor` が `scheduledAt` と一致しないもの」。
送信後に `lastNotifiedFor` へ `scheduledAt` を書き込み、`notifyAt` を削除する。

`notifyAt` の削除だけでは足りない。ユーザーが通知時刻を前倒しすると再計算で `notifyAt` が
復活し、同じ `scheduledAt` について再送されてしまうため。`notifyAt` は「探すための鍵」、
`lastNotifiedFor` は「送ったことの記録」として役割を分ける。

「通知時刻がこの実行回の担当時間帯に入るもの」という条件で絞る方式（状態を持たない方式）も
考えられるが、ユーザーが通知時刻を変更した直後に送信漏れ・二重送信が起き、Function の実行が
1 回失敗するとその回の通知が落ちるため採用しない。

**無効トークンの回収**

送信結果が `messaging/registration-token-not-registered` のトークンは、送信元の Function が
`users/{userId}.fcmTokens` から `arrayRemove` する。