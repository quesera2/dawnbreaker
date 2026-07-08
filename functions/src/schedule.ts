export type TaskType = "irregular" | "period" | "scheduled";

export type ScheduleUnit = "day" | "week" | "month";

// スケジュール再計算のために呼び出し元がクエリで絞り込む直近件数の上限
export const scheduleHistoryLimit = 10;

const dayMs = 24 * 60 * 60 * 1000;

/**
 * taskType に応じた次回実行日 (nextScheduledAt) を求める
 * lastExecutedAt が null（実行履歴なし）の場合は呼び出し元で判定して呼ばないこと
 * @param {object} params 計算に必要なパラメータ
 * @return {Date | null} 次回実行日、算出不能なら null
 */
export function computeScheduledAt(params: {
  taskType: TaskType;
  ascendingHistory: Date[];
  lastExecutedAt: Date;
  scheduleValue: number | null;
  scheduleUnit: ScheduleUnit | null;
}): Date | null {
  const {
    taskType, ascendingHistory, lastExecutedAt, scheduleValue, scheduleUnit,
  } = params;
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
 * @param {Date[]} ascendingHistory 昇順の実行履歴
 * @param {Date} lastExecutedAt 最終実行日時
 * @return {Date | null} 次回実行日、算出不能なら null
 */
function computePeriodNextAt(
  ascendingHistory: Date[],
  lastExecutedAt: Date
): Date | null {
  const average = averageIntervalDays(ascendingHistory);
  if (average == null) return null;
  return new Date(lastExecutedAt.getTime() + Math.round(average) * dayMs);
}

/**
 * 固定間隔の次回実行日計算（Dart 版と同じ役割）
 * @param {object} params 計算に必要なパラメータ
 * @return {Date | null} 次回実行日、算出不能なら null
 */
function computeFixedIntervalScheduledAt(params: {
  lastExecutedAt: Date | null;
  scheduleValue: number | null;
  scheduleUnit: ScheduleUnit | null;
}): Date | null {
  const {lastExecutedAt, scheduleValue, scheduleUnit} = params;
  if (lastExecutedAt == null || scheduleValue == null || scheduleUnit == null) {
    return null;
  }
  switch (scheduleUnit) {
  case "day":
    return new Date(lastExecutedAt.getTime() + scheduleValue * dayMs);
  case "week":
    return new Date(lastExecutedAt.getTime() + scheduleValue * 7 * dayMs);
  case "month": {
    const day = lastExecutedAt.getUTCDate();
    const next = new Date(lastExecutedAt.getTime());
    next.setUTCDate(1);
    next.setUTCMonth(next.getUTCMonth() + scheduleValue);
    // 加算先の月に存在しない日（例: 1/31 の1ヶ月後は2月末）は月末に丸める
    const daysInNextMonth = new Date(
      Date.UTC(next.getUTCFullYear(), next.getUTCMonth() + 1, 0)
    ).getUTCDate();
    next.setUTCDate(Math.min(day, daysInNextMonth));
    return next;
  }
  }
}

/**
 * 実行間隔の平均日数を求める
 * @param {Date[]} ascendingHistory 昇順の実行履歴
 * @return {number | null} 平均間隔日数、算出不能なら null
 */
function averageIntervalDays(
  ascendingHistory: Date[]
): number | null {
  const intervals = intervalDaysForHistory(ascendingHistory);
  if (intervals.length === 0) return null;
  return intervals.reduce((sum, v) => sum + v, 0) / intervals.length;
}

/**
 * 隣接する実行日同士の間隔（日数）の配列を求める
 * @param {Date[]} ascendingHistory 昇順の実行履歴
 * @return {number[]} 間隔日数の配列
 */
function intervalDaysForHistory(
  ascendingHistory: Date[]
): number[] {
  return ascendingHistory.slice(1).map((date, i) =>
    Math.round(
      (truncateTimeUtc(date) - truncateTimeUtc(ascendingHistory[i])) / dayMs
    )
  );
}

/**
 * 日付部分だけを UTC ミリ秒に切り詰める
 * @param {Date} date 対象の日時
 * @return {number} UTC 日付の epoch ミリ秒
 */
function truncateTimeUtc(date: Date): number {
  return Date.UTC(
    date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()
  );
}
