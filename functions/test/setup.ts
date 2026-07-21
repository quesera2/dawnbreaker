import {expect} from "@jest/globals";
import {Temporal} from "@js-temporal/polyfill";

// Temporal のオブジェクトは値を own enumerable property として持たない
// （Reflect.ownKeys が空配列を返す）ため、既定の再帰比較では比較対象が
// ゼロ個となり、どんな日時同士でも等価と判定されてしまう。
// ZonedDateTime 同士は equals（瞬間・タイムゾーン・カレンダーを比較）で判定する。
expect.addEqualityTesters([
  function temporalEqualityTester(a: unknown, b: unknown) {
    if (a instanceof Temporal.ZonedDateTime &&
      b instanceof Temporal.ZonedDateTime) {
      return a.equals(b);
    }
    // 判定しない場合は undefined を返し、デフォルト比較にフォールバックする
    return undefined;
  },
]);
