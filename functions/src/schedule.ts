import {Temporal} from "@js-temporal/polyfill";

export type TaskType = "irregular" | "period" | "scheduled";

export type ScheduleUnit = "day" | "week" | "month";

export type ScheduleConfig = {
  scheduleValue: number;
  scheduleUnit: ScheduleUnit;
};

// スケジュール再計算のために呼び出し元がクエリで絞り込む直近件数の上限
export const scheduleHistoryLimit = 10;

/**
 * taskDefinitions の書き込みトリガーで、再計算が必要な変更かどうかを判定する
 * scheduleConfig が同値（あるいは両方 null）なら変更なしとみなす
 * @param {ScheduleConfig | null} a 比較対象1
 * @param {ScheduleConfig | null} b 比較対象2
 * @return {boolean} 両者が同値なら true
 */
export function isSameScheduleConfig(
  a: ScheduleConfig | null,
  b: ScheduleConfig | null,
): boolean {
  if (a == null || b == null) return a == null && b == null;
  return (
    a.scheduleValue === b.scheduleValue && a.scheduleUnit === b.scheduleUnit
  );
}

/**
 * taskType に応じた次回実行日 (nextScheduledAt) を求める
 * 実行履歴が空（lastExecutedAt が求まらない）場合は null を返す
 * @param {object} params
 * @param {TaskType} params.taskType 対象タスクの種別
 * @param {Temporal.ZonedDateTime[]} params.ascendingHistory 昇順の実行履歴
 * @param {number | null} params.scheduleValue 固定間隔のスケジュール値（"scheduled" のときのみ）
 * @param {ScheduleUnit | null} params.scheduleUnit 固定間隔の単位（"scheduled" のときのみ）
 * @return {Temporal.ZonedDateTime | null} 次回実行日、算出不能なら null
 */
export function computeScheduledAt(params: {
  taskType: TaskType;
  ascendingHistory: Temporal.ZonedDateTime[];
  scheduleValue: number | null;
  scheduleUnit: ScheduleUnit | null;
}): Temporal.ZonedDateTime | null {
  const {taskType, ascendingHistory, scheduleValue, scheduleUnit} = params;
  const lastExecutedAt = ascendingHistory.at(-1) ?? null;
  if (lastExecutedAt == null) return null;
  switch (taskType) {
  case "irregular":
    return null;
  case "period":
    return computePeriodNextAt(ascendingHistory, lastExecutedAt);
  case "scheduled":
    return computeFixedIntervalScheduledAt({
      lastExecutedAt,
      scheduleValue,
      scheduleUnit,
    });
  }
}

/**
 * period タスクの次回実行日（直近履歴の平均間隔から算出）を求める
 * @param {Temporal.ZonedDateTime[]} ascendingHistory 昇順の実行履歴
 * @param {Temporal.ZonedDateTime} lastExecutedAt 最終実行日時
 * @return {Temporal.ZonedDateTime | null} 次回実行日、算出不能なら null
 */
function computePeriodNextAt(
  ascendingHistory: Temporal.ZonedDateTime[],
  lastExecutedAt: Temporal.ZonedDateTime,
): Temporal.ZonedDateTime | null {
  const average = averageIntervalDays(ascendingHistory);
  if (average == null) return null;
  return lastExecutedAt.add({days: Math.round(average)});
}

/**
 * 固定間隔の次回実行日計算
 * @param {object} params
 * @param {Temporal.ZonedDateTime | null} params.lastExecutedAt 最終実行日時
 * @param {number | null} params.scheduleValue 固定間隔のスケジュール値
 * @param {ScheduleUnit | null} params.scheduleUnit 実行間隔の単位
 * @return {Temporal.ZonedDateTime | null} 次回実行日、算出不能なら null
 */
function computeFixedIntervalScheduledAt(params: {
  lastExecutedAt: Temporal.ZonedDateTime | null;
  scheduleValue: number | null;
  scheduleUnit: ScheduleUnit | null;
}): Temporal.ZonedDateTime | null {
  const {lastExecutedAt, scheduleValue, scheduleUnit} = params;
  if (lastExecutedAt == null || scheduleValue == null || scheduleUnit == null) {
    return null;
  }
  switch (scheduleUnit) {
  case "day":
    return lastExecutedAt.add({days: scheduleValue});
  case "week":
    return lastExecutedAt.add({weeks: scheduleValue});
  case "month":
    return lastExecutedAt.add({months: scheduleValue});
  }
}

/**
 * 実行間隔の平均日数を求める
 * @param {Temporal.ZonedDateTime[]} ascendingHistory 昇順の実行履歴
 * @return {number | null} 平均間隔日数、算出不能なら null
 */
function averageIntervalDays(
  ascendingHistory: Temporal.ZonedDateTime[],
): number | null {
  const intervals = intervalDaysForHistory(ascendingHistory);
  if (intervals.length === 0) return null;
  return intervals.reduce((sum, v) => sum + v, 0) / intervals.length;
}

/**
 * 隣接する実行日同士の間隔（日数）の配列を求める
 * @param {Temporal.ZonedDateTime[]} ascendingHistory 昇順の実行履歴
 * @return {number[]} 間隔日数の配列
 */
function intervalDaysForHistory(
  ascendingHistory: Temporal.ZonedDateTime[],
): number[] {
  return ascendingHistory.slice(1).map((zonedDateTime, i) =>
    zonedDateTime.toPlainDate().since(
      ascendingHistory[i].toPlainDate(), {largestUnit: "days"},
    ).days,
  );
}
