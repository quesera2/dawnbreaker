# Firestore Schema

## コレクション構造

```
users/
  {userId}/
    fields...（notificationSetting, fcmTokens）
    taskDefinitions/
      {taskDefinitionId}/
        fields...
        executions/
          {executionId}/
            fields...
```

## ドキュメント定義

### users

プッシュ通知の送信に使う設定・宛先情報を持つ。フィールドはクライアント（Flutter 側）の変更をトリガーに同期する。

#### notificationSetting

通知設定。クライアントの `NotificationSetting` モデルと同じフィールド構成で、設定変更のたびに同期する。
未設定（初回同期前）は通知しない。

| フィールド | 型 | 説明 |
|---|---|---|
| enabled | boolean | 通知の有効・無効 |
| notifyDay | string | `today` / `yesterday`。`nextScheduledAt` から見た通知日のオフセット |
| hour | number | 通知時刻（時）0-23 |
| minute | number | 通知時刻（分）0-59 |

#### fcmTokens

この端末群に紐づく FCM デバイストークンの一覧（`string[]`）。複数端末ログインを想定し配列で持つ。
クライアントがトークン取得・更新時に自身のトークンを配列に追加し、失効を検知した際は取り除く。

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

**キャッシュの更新タイミング**

`lastExecutedAt` / `nextScheduledAt` は以下のタイミングで再計算・書き戻す：

- 実行の追加・削除
- `scheduleConfig` の変更（`scheduled` のみ）

`period` の `nextScheduledAt` 再計算時は直近 10 件の `executions` を取得して使用する。
削除時は削除対象が最新かどうかに関わらず、常に直近 10 件を再取得して再計算する。

### executions（taskDefinitions のサブコレクション）

タスクの実行履歴。

| フィールド | 型 | 説明 |
|---|---|---|
| executedAt | timestamp | 実行日時 |
| comment | string? | メモ（任意）|

親タスクの ID はドキュメントパス（`taskDefinitions/{taskDefinitionId}/executions/...`）から得られるため、フィールドとしては持たない。