import {Temporal} from "@js-temporal/polyfill";

/**
 * ISO 文字列から UTC 固定の ZonedDateTime を作る。
 * @param {string} isoString 変換元の ISO 文字列
 * @return {Temporal.ZonedDateTime} UTC の ZonedDateTime
 */
export const zdt = (isoString: string): Temporal.ZonedDateTime =>
  Temporal.Instant.from(isoString).toZonedDateTimeISO("UTC");

/**
 * ZonedDateTime を比較用の文字列に落とす。
 * Temporal のオブジェクトは値を own enumerable property として持たない
 * （Reflect.ownKeys が空配列を返す）ため、toEqual に直接渡すと
 * 比較対象がゼロ個となり、どんな日時同士でも等価と判定されてしまう。
 * 日時のテストは必ずこの関数を通した文字列で比較すること。
 * @param {Temporal.ZonedDateTime | null} value 比較対象
 * @return {string | null} タイムゾーン付きの文字列、null ならそのまま null
 */
export const zonedDateTimeText = (
  value: Temporal.ZonedDateTime | null,
): string | null => value?.toString() ?? null;
