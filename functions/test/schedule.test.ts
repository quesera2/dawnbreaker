import {computeScheduledAt, isSameScheduleConfig} from "../src/schedule";
import {zdt, zonedDateTimeText} from "./helper/temporal";

describe("computeScheduledAt", () => {
  test("履歴が空のとき null を返す", () => {
    expect(computeScheduledAt({
      taskType: "scheduled",
      ascendingHistory: [],
      scheduleValue: 1,
      scheduleUnit: "day",
    })).toBeNull();
  });

  describe("irregular タスク", () => {
    test("常に null を返す", () => {
      const lastExecutedAt = zdt("2025-01-01T00:00:00Z");
      expect(computeScheduledAt({
        taskType: "irregular",
        ascendingHistory: [lastExecutedAt],
        scheduleValue: null,
        scheduleUnit: null,
      })).toBeNull();
    });
  });

  describe("period タスク", () => {
    test("履歴が1件のとき null を返す", () => {
      const lastExecutedAt = zdt("2025-01-01T00:00:00Z");
      expect(computeScheduledAt({
        taskType: "period",
        ascendingHistory: [lastExecutedAt],
        scheduleValue: null,
        scheduleUnit: null,
      })).toBeNull();
    });

    test("履歴が2件のとき 間隔の平均だけ後の日付を返す", () => {
      // 間隔: 31日 → 平均31日 → 2/1 + 31日 = 3/4
      const history = [
        zdt("2025-01-01T00:00:00Z"),
        zdt("2025-02-01T00:00:00Z"),
      ];
      expect(zonedDateTimeText(computeScheduledAt({
        taskType: "period",
        ascendingHistory: history,
        scheduleValue: null,
        scheduleUnit: null,
      }))).toBe("2025-03-04T00:00:00+00:00[UTC]");
    });

    test("履歴が3件のとき 全間隔の平均を使う", () => {
      // 間隔: 10日, 20日 → 平均15日 → 1/31 + 15日 = 2/15
      const history = [
        zdt("2025-01-01T00:00:00Z"),
        zdt("2025-01-11T00:00:00Z"),
        zdt("2025-01-31T00:00:00Z"),
      ];
      expect(zonedDateTimeText(computeScheduledAt({
        taskType: "period",
        ascendingHistory: history,
        scheduleValue: null,
        scheduleUnit: null,
      }))).toBe("2025-02-15T00:00:00+00:00[UTC]");
    });

    test("時刻成分を含む executedAt でも日付単位で間隔が計算される", () => {
      // 1日間隔: 15:00 → 翌日 09:00（時刻成分あり）
      const history = [
        zdt("2025-01-01T15:00:00Z"),
        zdt("2025-01-02T09:00:00Z"),
      ];
      // 1日間隔 → lastExecutedAt(1/2 09:00) + 1日 = 1/3 09:00
      expect(zonedDateTimeText(computeScheduledAt({
        taskType: "period",
        ascendingHistory: history,
        scheduleValue: null,
        scheduleUnit: null,
      }))).toBe("2025-01-03T09:00:00+00:00[UTC]");
    });
  });

  describe("scheduled タスク", () => {
    test("ScheduleUnit.day: 最後の実行日 + n日", () => {
      const lastExecutedAt = zdt("2025-01-01T00:00:00Z");
      expect(zonedDateTimeText(computeScheduledAt({
        taskType: "scheduled",
        ascendingHistory: [lastExecutedAt],
        scheduleValue: 14,
        scheduleUnit: "day",
      }))).toBe("2025-01-15T00:00:00+00:00[UTC]");
    });

    test("ScheduleUnit.week: 最後の実行日 + n週", () => {
      const lastExecutedAt = zdt("2025-01-01T00:00:00Z");
      expect(zonedDateTimeText(computeScheduledAt({
        taskType: "scheduled",
        ascendingHistory: [lastExecutedAt],
        scheduleValue: 2,
        scheduleUnit: "week",
      }))).toBe("2025-01-15T00:00:00+00:00[UTC]");
    });

    test("ScheduleUnit.month: 最後の実行日 + nヶ月", () => {
      const lastExecutedAt = zdt("2025-01-10T00:00:00Z");
      expect(zonedDateTimeText(computeScheduledAt({
        taskType: "scheduled",
        ascendingHistory: [lastExecutedAt],
        scheduleValue: 3,
        scheduleUnit: "month",
      }))).toBe("2025-04-10T00:00:00+00:00[UTC]");
    });

    test("ScheduleUnit.month: 加算先の月に存在しない日は月末に丸められる", () => {
      // 1/31 の1ヶ月後は2月末（2025年は平年なので28日）に丸める
      const lastExecutedAt = zdt("2025-01-31T00:00:00Z");
      expect(zonedDateTimeText(computeScheduledAt({
        taskType: "scheduled",
        ascendingHistory: [lastExecutedAt],
        scheduleValue: 1,
        scheduleUnit: "month",
      }))).toBe("2025-02-28T00:00:00+00:00[UTC]");
    });

    test("scheduleValue/scheduleUnit が欠損しているとき null を返す", () => {
      const lastExecutedAt = zdt("2025-01-01T00:00:00Z");
      expect(computeScheduledAt({
        taskType: "scheduled",
        ascendingHistory: [lastExecutedAt],
        scheduleValue: null,
        scheduleUnit: null,
      })).toBeNull();
    });
  });
});

describe("isSameScheduleConfig", () => {
  test("両方 null なら true", () => {
    expect(isSameScheduleConfig(null, null)).toBe(true);
  });

  test("片方だけ null なら false", () => {
    expect(isSameScheduleConfig(
      {scheduleValue: 1, scheduleUnit: "day"}, null,
    )).toBe(false);
    expect(isSameScheduleConfig(
      null, {scheduleValue: 1, scheduleUnit: "day"},
    )).toBe(false);
  });

  test("scheduleValue / scheduleUnit が共に同じなら true", () => {
    expect(isSameScheduleConfig(
      {scheduleValue: 1, scheduleUnit: "day"},
      {scheduleValue: 1, scheduleUnit: "day"},
    )).toBe(true);
  });

  test("scheduleValue が異なれば false", () => {
    expect(isSameScheduleConfig(
      {scheduleValue: 1, scheduleUnit: "day"},
      {scheduleValue: 2, scheduleUnit: "day"},
    )).toBe(false);
  });

  test("scheduleUnit が異なれば false", () => {
    expect(isSameScheduleConfig(
      {scheduleValue: 1, scheduleUnit: "day"},
      {scheduleValue: 1, scheduleUnit: "week"},
    )).toBe(false);
  });
});
