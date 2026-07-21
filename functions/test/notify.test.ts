import {
  computeNotifyAt,
  isSameNotificationSetting,
  NotificationSetting,
  parseNotificationSetting,
  shouldSendNotification,
} from "../src/notify";
import {zdt} from "./helper/temporal";

const setting = (
  override: Partial<NotificationSetting> = {},
): NotificationSetting => ({
  enabled: true,
  notifyDay: "today",
  hour: 9,
  minute: 0,
  ...override,
});

describe("computeNotifyAt", () => {
  describe("通知対象外", () => {
    test("nextScheduledAt が null のとき null を返す", () => {
      expect(computeNotifyAt({
        nextScheduledAt: null,
        setting: setting(),
        timeZone: "Asia/Tokyo",
      })).toBeNull();
    });

    test("通知設定がないとき null を返す", () => {
      expect(computeNotifyAt({
        nextScheduledAt: zdt("2025-01-10T00:00:00Z"),
        setting: null,
        timeZone: "Asia/Tokyo",
      })).toBeNull();
    });

    test("通知が無効のとき null を返す", () => {
      expect(computeNotifyAt({
        nextScheduledAt: zdt("2025-01-10T00:00:00Z"),
        setting: setting({enabled: false}),
        timeZone: "Asia/Tokyo",
      })).toBeNull();
    });

    test("タイムゾーンが null のとき null を返す", () => {
      expect(computeNotifyAt({
        nextScheduledAt: zdt("2025-01-10T00:00:00Z"),
        setting: setting(),
        timeZone: null,
      })).toBeNull();
    });

    test("タイムゾーンが不正なとき null を返す", () => {
      expect(computeNotifyAt({
        nextScheduledAt: zdt("2025-01-10T00:00:00Z"),
        setting: setting(),
        timeZone: "Not/AZone",
      })).toBeNull();
    });
  });

  describe("notifyDay", () => {
    test("today のとき nextScheduledAt 当日の指定時刻を返す", () => {
      // nextScheduledAt = 1/10 12:00 JST → 当日 9:00 JST
      expect(computeNotifyAt({
        nextScheduledAt: zdt("2025-01-10T03:00:00Z"),
        setting: setting({notifyDay: "today", hour: 9, minute: 0}),
        timeZone: "Asia/Tokyo",
      })).toEqual(zdt("2025-01-10T09:00:00+09:00[Asia/Tokyo]"));
    });

    test("yesterday のとき nextScheduledAt 前日の指定時刻を返す", () => {
      // nextScheduledAt = 1/10 12:00 JST → 前日 1/9 9:00 JST
      expect(computeNotifyAt({
        nextScheduledAt: zdt("2025-01-10T03:00:00Z"),
        setting: setting({notifyDay: "yesterday", hour: 9, minute: 0}),
        timeZone: "Asia/Tokyo",
      })).toEqual(zdt("2025-01-09T09:00:00+09:00[Asia/Tokyo]"));
    });

    test("月初の yesterday は前月末日になる", () => {
      // nextScheduledAt = 3/1 12:00 JST → 前日は 2/28（2025年は平年）
      expect(computeNotifyAt({
        nextScheduledAt: zdt("2025-03-01T03:00:00Z"),
        setting: setting({notifyDay: "yesterday", hour: 9, minute: 0}),
        timeZone: "Asia/Tokyo",
      })).toEqual(zdt("2025-02-28T09:00:00+09:00[Asia/Tokyo]"));
    });
  });

  describe("タイムゾーン", () => {
    test("日付はユーザーのタイムゾーンの壁時計で判定する", () => {
      // 1/10 23:00Z は JST では 1/11 08:00 なので、通知日は 1/11
      expect(computeNotifyAt({
        nextScheduledAt: zdt("2025-01-10T23:00:00Z"),
        setting: setting({notifyDay: "today", hour: 9, minute: 0}),
        timeZone: "Asia/Tokyo",
      })).toEqual(zdt("2025-01-11T09:00:00+09:00[Asia/Tokyo]"));
    });

    test("時刻はユーザーのタイムゾーンの壁時計として解決する", () => {
      // nextScheduledAt = 1/10 07:00 EST → 当日 9:00 EST (UTC-5)
      expect(computeNotifyAt({
        nextScheduledAt: zdt("2025-01-10T12:00:00Z"),
        setting: setting({notifyDay: "today", hour: 9, minute: 0}),
        timeZone: "America/New_York",
      })).toEqual(zdt("2025-01-10T09:00:00-05:00[America/New_York]"));
    });

    test("夏時間の切り替え日でもその日の壁時計時刻を返す", () => {
      // 2025-03-09 は New York の DST 開始日。9:00 は EDT (UTC-4) 側になる
      expect(computeNotifyAt({
        nextScheduledAt: zdt("2025-03-09T18:00:00Z"),
        setting: setting({notifyDay: "today", hour: 9, minute: 0}),
        timeZone: "America/New_York",
      })).toEqual(zdt("2025-03-09T09:00:00-04:00[America/New_York]"));
    });
  });

  test("hour / minute をそのまま壁時計時刻に使う", () => {
    // nextScheduledAt = 1/10 12:00 JST → 当日 22:30 JST
    expect(computeNotifyAt({
      nextScheduledAt: zdt("2025-01-10T03:00:00Z"),
      setting: setting({hour: 22, minute: 30}),
      timeZone: "Asia/Tokyo",
    })).toEqual(zdt("2025-01-10T22:30:00+09:00[Asia/Tokyo]"));
  });
});

describe("parseNotificationSetting", () => {
  test("正しい map をそのまま読み取る", () => {
    expect(parseNotificationSetting({
      enabled: true,
      notifyDay: "yesterday",
      hour: 22,
      minute: 30,
    })).toEqual({
      enabled: true,
      notifyDay: "yesterday",
      hour: 22,
      minute: 30,
    });
  });

  test("hour / minute が範囲外なら丸める", () => {
    expect(parseNotificationSetting({
      enabled: true,
      notifyDay: "today",
      hour: 99,
      minute: -1,
    })).toEqual({
      enabled: true,
      notifyDay: "today",
      hour: 23,
      minute: 0,
    });
  });

  test.each([
    ["未設定", null],
    ["map でない", "enabled"],
    ["enabled がない", {notifyDay: "today", hour: 9, minute: 0}],
    ["notifyDay が不正",
      {enabled: true, notifyDay: "tomorrow", hour: 9, minute: 0}],
    ["hour が数値でない",
      {enabled: true, notifyDay: "today", hour: "9", minute: 0}],
    ["minute が整数でない",
      {enabled: true, notifyDay: "today", hour: 9, minute: 0.5}],
  ])("%s のとき null を返す", (_, value) => {
    expect(parseNotificationSetting(value)).toBeNull();
  });
});

describe("isSameNotificationSetting", () => {
  test("両方 null なら true", () => {
    expect(isSameNotificationSetting(null, null)).toBe(true);
  });

  test("片方だけ null なら false", () => {
    expect(isSameNotificationSetting(setting(), null)).toBe(false);
  });

  test("全フィールドが同値なら true", () => {
    expect(isSameNotificationSetting(setting(), setting())).toBe(true);
  });

  test.each([
    ["enabled", {enabled: false}],
    ["notifyDay", {notifyDay: "yesterday" as const}],
    ["hour", {hour: 10}],
    ["minute", {minute: 30}],
  ])("%s が異なれば false", (_, override) => {
    expect(isSameNotificationSetting(setting(), setting(override))).toBe(false);
  });
});

describe("shouldSendNotification", () => {
  test("lastNotifiedFor が null なら true（未送信）", () => {
    expect(shouldSendNotification(
      zdt("2025-01-10T09:00:00Z"),
      null,
    )).toBe(true);
  });

  test("lastNotifiedFor が scheduledAt と一致すれば false（送信済み）", () => {
    expect(shouldSendNotification(
      zdt("2025-01-10T09:00:00Z"),
      zdt("2025-01-10T09:00:00Z"),
    )).toBe(false);
  });

  test("lastNotifiedFor が scheduledAt と異なれば true（予定が変わったので再送）", () => {
    expect(shouldSendNotification(
      zdt("2025-01-11T09:00:00Z"),
      zdt("2025-01-10T09:00:00Z"),
    )).toBe(true);
  });
});
