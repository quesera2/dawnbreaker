import {Temporal} from "@js-temporal/polyfill";

/**
 * `nextScheduledAt` から見た通知日のオフセット。
 * クライアントの `NotifyDay` enum と同じ値を Firestore に保存している。
 */
export type NotifyDay = "today" | "yesterday";

/**
 * ユーザー単位の通知設定（全タスク共通）。タスクごとの個別設定は持たない。
 * `users/{uid}.notificationSetting` に対応する。
 */
export type NotificationSetting = {
  enabled: boolean;
  notifyDay: NotifyDay;
  hour: number; // 通知する時刻（時）。0–23
  minute: number; // 通知する時刻（分）。0–59
};

const notifyDayOffsets: Record<NotifyDay, number> = {
  today: 0,
  yesterday: -1,
};

/**
 * users の書き込みトリガーで、再計算が必要な変更かどうかを判定する
 * 両方 null なら変更なしとみなす
 * @param {NotificationSetting | null} a 比較対象1
 * @param {NotificationSetting | null} b 比較対象2
 * @return {boolean} 両者が同値なら true
 */
export function isSameNotificationSetting(
  a: NotificationSetting | null,
  b: NotificationSetting | null,
): boolean {
  if (a == null || b == null) return a == null && b == null;
  return (
    a.enabled === b.enabled &&
    a.notifyDay === b.notifyDay &&
    a.hour === b.hour &&
    a.minute === b.minute
  );
}

/**
 * `users/{uid}.notificationSetting` の生データを NotificationSetting に読み替える。
 * 未設定・型違い・範囲外の値を含む場合は null（通知しない）を返す。
 * クライアントの `NotificationSetting.fromMap` と同じ寛容さで、
 * サーバー側のデータが壊れていても通知処理が落ちないようにするため。
 * @param {unknown} value Firestore から読んだ notificationSetting フィールド
 * @return {NotificationSetting | null} 通知設定、解釈できなければ null
 */
export function parseNotificationSetting(
  value: unknown,
): NotificationSetting | null {
  if (value == null || typeof value !== "object") return null;

  const {enabled, notifyDay, hour, minute} = value as Record<string, unknown>;
  if (typeof enabled !== "boolean") return null;
  if (notifyDay !== "today" && notifyDay !== "yesterday") return null;
  if (!isInteger(hour) || !isInteger(minute)) return null;

  return {
    enabled,
    notifyDay,
    hour: clamp(hour, 0, 23),
    minute: clamp(minute, 0, 59),
  };
}

/**
 * 通知時刻 (notifyAt) を求める。
 * 「`nextScheduledAt` に `notifyDay` のオフセットを加えた日付」の「`hour`:`minute`」を
 * `timeZone` 上の壁時計時刻として解決した瞬間を返す。
 * 通知対象でないとき（通知設定なし・通知無効・タイムゾーン不正、
 * および `irregular` や未実行で nextScheduledAt が null）は null を返す。
 * 呼び出し側はこの場合 notifyAt フィールドを削除する（schema.md 参照）。
 * @param {object} params
 * @param {Temporal.ZonedDateTime | null} params.nextScheduledAt 次回実行予定日時
 * @param {NotificationSetting | null} params.setting ユーザーの通知設定
 * @param {string | null} params.timeZone IANA タイムゾーン名（例 `Asia/Tokyo`）
 * @return {Temporal.ZonedDateTime | null} 通知時刻、通知対象外なら null
 */
export function computeNotifyAt(params: {
  nextScheduledAt: Temporal.ZonedDateTime | null;
  setting: NotificationSetting | null;
  timeZone: string | null;
}): Temporal.ZonedDateTime | null {
  const {nextScheduledAt, setting, timeZone} = params;
  if (nextScheduledAt == null) return null;
  if (setting == null || !setting.enabled) return null;
  if (timeZone == null || !isValidTimeZone(timeZone)) return null;

  // nextScheduledAt をユーザーのタイムゾーンの壁時計日付に落とし、notifyDay を加算する
  const targetDate = nextScheduledAt
    .withTimeZone(timeZone)
    .toPlainDate()
    .add({days: notifyDayOffsets[setting.notifyDay]});

  // その日付の hour:minute を timeZone の壁時計時刻として解決する
  return targetDate.toZonedDateTime({
    timeZone,
    plainTime: new Temporal.PlainTime(setting.hour, setting.minute),
  });
}

/**
 * notifications ドキュメントを送信対象とすべきか判定する。
 * 対象は「lastNotifiedFor が scheduledAt と一致しないもの」（重複送信の防止）。
 * notifyAt <= now である前提はクエリ側で絞り込まれているため、ここでは見ない。
 * @param {Temporal.ZonedDateTime} scheduledAt 送信元となった nextScheduledAt の値
 * @param {Temporal.ZonedDateTime | null} lastNotifiedFor 通知済みの scheduledAt の値
 * @return {boolean} 送信すべきなら true
 */
export function shouldSendNotification(
  scheduledAt: Temporal.ZonedDateTime,
  lastNotifiedFor: Temporal.ZonedDateTime | null,
): boolean {
  return lastNotifiedFor == null || !lastNotifiedFor.equals(scheduledAt);
}

/**
 * IANA タイムゾーン名として解決できるかを判定する
 * @param {string} timeZone 判定対象
 * @return {boolean} 解決できれば true
 */
function isValidTimeZone(timeZone: string): boolean {
  try {
    Temporal.Instant.fromEpochMilliseconds(0).toZonedDateTimeISO(timeZone);
    return true;
  } catch {
    return false;
  }
}

/**
 * 整数かどうかを判定する。
 * Number.isInteger は述語を返さないため対象が unknown のまま残り、
 * 呼び出し側でキャストが要る。型ガードとして包むことでキャストを不要にする。
 * @param {unknown} value 判定対象
 * @return {boolean} 整数なら true
 */
function isInteger(value: unknown): value is number {
  return Number.isInteger(value);
}

/**
 * 値を下限・上限の範囲に収める
 * @param {number} value 対象の値
 * @param {number} min 下限
 * @param {number} max 上限
 * @return {number} 範囲に収めた値
 */
function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}
