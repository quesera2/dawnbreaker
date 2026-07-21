import {Temporal} from "@js-temporal/polyfill";

/**
 * ISO 文字列から ZonedDateTime を作る。
 * `2025-01-10T09:00:00+09:00[Asia/Tokyo]` のようにタイムゾーン注釈が
 * 付いていればその値をそのまま使う。注釈がなければ瞬間として解釈し、
 * UTC のタイムゾーンに置く。
 * @param {string} isoString 変換元の ISO 文字列
 * @return {Temporal.ZonedDateTime} 変換した ZonedDateTime
 */
export const zdt = (isoString: string): Temporal.ZonedDateTime =>
  isoString.includes("[") ?
    Temporal.ZonedDateTime.from(isoString) :
    Temporal.Instant.from(isoString).toZonedDateTimeISO("UTC");
