import {computeScheduledAt} from "./schedule";

describe("computeScheduledAt", () => {
  describe("irregular タスク", () => {
    test("常に null を返す", () => {
      const lastExecutedAt = new Date("2025-01-01");
      expect(computeScheduledAt({
        taskType: "irregular",
        ascendingHistory: [lastExecutedAt],
        lastExecutedAt,
        scheduleValue: null,
        scheduleUnit: null,
      })).toBeNull();
    });
  });

  describe("period タスク", () => {
    test("履歴が1件のとき null を返す", () => {
      const lastExecutedAt = new Date("2025-01-01");
      expect(computeScheduledAt({
        taskType: "period",
        ascendingHistory: [lastExecutedAt],
        lastExecutedAt,
        scheduleValue: null,
        scheduleUnit: null,
      })).toBeNull();
    });

    test("履歴が2件のとき 間隔の平均だけ後の日付を返す", () => {
      // 間隔: 31日 → 平均31日 → 2/1 + 31日 = 3/4
      const history = [new Date("2025-01-01"), new Date("2025-02-01")];
      expect(computeScheduledAt({
        taskType: "period",
        ascendingHistory: history,
        lastExecutedAt: history[1],
        scheduleValue: null,
        scheduleUnit: null,
      })).toEqual(new Date("2025-03-04"));
    });

    test("履歴が3件のとき 全間隔の平均を使う", () => {
      // 間隔: 10日, 20日 → 平均15日 → 1/31 + 15日 = 2/15
      const history = [
        new Date("2025-01-01"),
        new Date("2025-01-11"),
        new Date("2025-01-31"),
      ];
      expect(computeScheduledAt({
        taskType: "period",
        ascendingHistory: history,
        lastExecutedAt: history[2],
        scheduleValue: null,
        scheduleUnit: null,
      })).toEqual(new Date("2025-02-15"));
    });

    test("時刻成分を含む executedAt でも日付単位で間隔が計算される", () => {
      // 1日間隔: 15:00 → 翌日 09:00（時刻成分あり）
      const history = [
        new Date("2025-01-01T15:00:00Z"),
        new Date("2025-01-02T09:00:00Z"),
      ];
      // 1日間隔 → lastExecutedAt(1/2 09:00) + 1日 = 1/3 09:00
      expect(computeScheduledAt({
        taskType: "period",
        ascendingHistory: history,
        lastExecutedAt: history[1],
        scheduleValue: null,
        scheduleUnit: null,
      })).toEqual(new Date("2025-01-03T09:00:00Z"));
    });
  });

  describe("scheduled タスク", () => {
    test("ScheduleUnit.day: 最後の実行日 + n日", () => {
      const lastExecutedAt = new Date("2025-01-01");
      expect(computeScheduledAt({
        taskType: "scheduled",
        ascendingHistory: [lastExecutedAt],
        lastExecutedAt,
        scheduleValue: 14,
        scheduleUnit: "day",
      })).toEqual(new Date("2025-01-15"));
    });

    test("ScheduleUnit.week: 最後の実行日 + n週", () => {
      const lastExecutedAt = new Date("2025-01-01");
      expect(computeScheduledAt({
        taskType: "scheduled",
        ascendingHistory: [lastExecutedAt],
        lastExecutedAt,
        scheduleValue: 2,
        scheduleUnit: "week",
      })).toEqual(new Date("2025-01-15"));
    });

    test("ScheduleUnit.month: 最後の実行日 + nヶ月", () => {
      const lastExecutedAt = new Date("2025-01-10");
      expect(computeScheduledAt({
        taskType: "scheduled",
        ascendingHistory: [lastExecutedAt],
        lastExecutedAt,
        scheduleValue: 3,
        scheduleUnit: "month",
      })).toEqual(new Date("2025-04-10"));
    });

    test("ScheduleUnit.month: 加算先の月に存在しない日は月末に丸められる", () => {
      // 1/31 の1ヶ月後は2月末（2025年は平年なので28日）に丸める
      const lastExecutedAt = new Date("2025-01-31");
      expect(computeScheduledAt({
        taskType: "scheduled",
        ascendingHistory: [lastExecutedAt],
        lastExecutedAt,
        scheduleValue: 1,
        scheduleUnit: "month",
      })).toEqual(new Date("2025-02-28"));
    });

    test("scheduleValue/scheduleUnit が欠損しているとき null を返す", () => {
      const lastExecutedAt = new Date("2025-01-01");
      expect(computeScheduledAt({
        taskType: "scheduled",
        ascendingHistory: [lastExecutedAt],
        lastExecutedAt,
        scheduleValue: null,
        scheduleUnit: null,
      })).toBeNull();
    });
  });
});
