import {isAnonymous, isInactive, thresholdFrom} from "../src/cleanup";
import {zdt} from "./helper/temporal";

describe("thresholdFrom", () => {
  test("猶予日数だけ過去に戻した日時を返す", () => {
    expect(thresholdFrom(zdt("2025-01-10T03:00:00Z"), 3))
      .toEqual(zdt("2025-01-07T03:00:00Z"));
  });

  test("猶予日数が 0 のとき現在日時をそのまま返す", () => {
    const now = zdt("2025-01-10T03:00:00Z");
    expect(thresholdFrom(now, 0)).toEqual(now);
  });
});

describe("isInactive", () => {
  const threshold = zdt("2025-01-07T03:00:00Z");

  test("最終アクティブ日時がしきい値より古いとき true を返す", () => {
    expect(isInactive(zdt("2025-01-07T02:59:59Z"), threshold)).toBe(true);
  });

  test("最終アクティブ日時がしきい値と同じとき false を返す", () => {
    expect(isInactive(zdt("2025-01-07T03:00:00Z"), threshold)).toBe(false);
  });

  test("最終アクティブ日時がしきい値より新しいとき false を返す", () => {
    expect(isInactive(zdt("2025-01-07T03:00:01Z"), threshold)).toBe(false);
  });

  test("最終アクティブ日時が無いとき true を返す", () => {
    expect(isInactive(null, threshold)).toBe(true);
  });
});

describe("isAnonymous", () => {
  test("サインインプロバイダを持たないとき true を返す", () => {
    expect(isAnonymous({providerData: []})).toBe(true);
  });

  test("サインインプロバイダを持つとき false を返す", () => {
    expect(isAnonymous({providerData: [{providerId: "google.com"}]}))
      .toBe(false);
  });
});
