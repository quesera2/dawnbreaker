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
 * 最終アクティブ日時が放置とみなせるかを判定する。
 *
 * lastActiveAt が無い場合も放置として扱う。ゲスト作成と同時に書いており、
 * Firestore の書き込みはオフラインでもローカルキューに載るため、値が無いのは
 * 異常ケースにあたる。判定できないものを永久に残すより回収する
 * @param {Temporal.ZonedDateTime | null} lastActiveAt 最終アクティブ日時。
 *     フィールドが無ければ null
 * @param {Temporal.ZonedDateTime} threshold 放置とみなすしきい値
 * @return {boolean} 放置とみなせるなら true
 */
export function isInactive(
  lastActiveAt: Temporal.ZonedDateTime | null,
  threshold: Temporal.ZonedDateTime,
): boolean {
  if (lastActiveAt == null) return true;
  return Temporal.ZonedDateTime.compare(lastActiveAt, threshold) < 0;
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
