import {Temporal} from "@js-temporal/polyfill";

/**
 * 猶予日数から、これより古い最終アクティブ日時を放置とみなすしきい値を求める
 * @param {Temporal.ZonedDateTime} now 現在日時
 * @param {number} retentionDays 猶予日数
 * @return {Temporal.ZonedDateTime} しきい値
 */
export function thresholdFrom(
  now: Temporal.ZonedDateTime,
  retentionDays: number,
): Temporal.ZonedDateTime {
  return now.subtract({days: retentionDays});
}

/**
 * 最終アクティブ日時が放置とみなせるかを判定する
 * @param {Temporal.ZonedDateTime} lastActiveAt 最終アクティブ日時
 * @param {Temporal.ZonedDateTime} threshold 放置とみなすしきい値
 * @return {boolean} 放置とみなせるなら true
 */
export function isInactive(
  lastActiveAt: Temporal.ZonedDateTime,
  threshold: Temporal.ZonedDateTime,
): boolean {
  return Temporal.ZonedDateTime.compare(lastActiveAt, threshold) < 0;
}

/**
 * Auth のユーザー情報から最終アクティブ日時を求める。
 *
 * lastRefreshTime は ID トークンを最後に更新した時刻で、アプリを使っている間は
 * Auth SDK が自動で進める。作成直後から埋まるが、型の上では無いことがあるため
 * 作成日時で補う
 * @param {object} metadata Auth のユーザーのメタデータ
 * @param {string | null} [metadata.lastRefreshTime] ID トークンを最後に更新した時刻
 * @param {string} metadata.creationTime 作成日時
 * @return {Temporal.ZonedDateTime} 最終アクティブ日時
 */
export function lastActiveAtOf(metadata: {
  lastRefreshTime?: string | null;
  creationTime: string;
}): Temporal.ZonedDateTime {
  const time = metadata.lastRefreshTime ?? metadata.creationTime;
  return Temporal.Instant.fromEpochMilliseconds(Date.parse(time))
    .toZonedDateTimeISO("UTC");
}

/**
 * 匿名ユーザーかどうかを判定する。
 *
 * Admin SDK の UserRecord には isAnonymous がないため、サインインプロバイダを
 * 1 つも持たないことを匿名の条件とする。カスタムトークンのユーザーも同じ形になるが、
 * このアプリは使っていない
 * @param {object} user 判定対象のユーザー
 * @param {unknown[]} user.providerData サインインプロバイダの一覧
 * @return {boolean} 匿名なら true
 */
export function isAnonymous(user: {providerData: unknown[]}): boolean {
  return user.providerData.length === 0;
}
