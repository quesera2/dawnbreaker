import {Temporal} from "@js-temporal/polyfill";
import {setGlobalOptions} from "firebase-functions";
import {
  onDocumentDeleted,
  onDocumentWritten,
} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore, Timestamp} from "firebase-admin/firestore";
import {
  computeScheduledAt,
  isSameScheduleConfig,
  ScheduleConfig,
  TaskType,
  scheduleHistoryLimit,
} from "./schedule";
import {
  computeNotifyAt,
  isSameNotificationSetting,
  NotificationSetting,
  parseNotificationSetting,
} from "./notify";

setGlobalOptions({maxInstances: 1});

initializeApp();

/**
 * 実行履歴 (executions) の作成・更新・削除をトリガーに、
 * 親タスク定義 (taskDefinitions) の lastExecutedAt / nextScheduledAt を再計算する。
 * dawnbreaker (Flutter) 側の recordExecution / updateExecution /
 * deleteExecution が各々の末尾で行っていたスケジュール再計算を
 * サーバー側に集約したもの。
 */
export const onExecutionWritten = onDocumentWritten(
  "users/{userId}/taskDefinitions/{taskId}/executions/{executionId}",
  async (event) => {
    const {userId, taskId} = event.params;
    const userRef = getFirestore().collection("users").doc(userId);

    const taskDefSnap = await taskDefinitionRef(userRef, taskId).get();
    const taskDefData = taskDefSnap.data();
    if (taskDefData == null) {
      // タスク削除時、onTaskDefinitionDeleted が executions を掃除する過程で
      // 本トリガーが発火した場合に毎回通る正常系のため info に留める
      logger.info("taskDefinition not found", {userId, taskId});
      return;
    }

    await recalcScheduleCache(
      userRef,
      taskId,
      taskDefData.taskType as TaskType,
      (taskDefData.scheduleConfig ?? null) as ScheduleConfig | null,
    );
  },
);

/**
 * タスク定義 (taskDefinitions) の taskType / scheduleConfig の変更をトリガーに、
 * nextScheduledAt を再計算する。executions を書き換えない変更のため
 * onExecutionWritten では拾えない（詳細は schema.md）。
 * 変更前後で taskType / scheduleConfig が同一なら、再計算結果の書き戻しによる
 * 再発火とみなして何もせず抜ける。
 */
export const onTaskDefinitionWritten = onDocumentWritten(
  "users/{userId}/taskDefinitions/{taskId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    if (afterData == null) return; // 削除は onTaskDefinitionDeleted が担当
    if (beforeData == null) return; // 初回書き込み時はまだタスクがないので再計算不要

    const afterTask = afterData.taskType as TaskType;
    const afterConfig =
      (afterData.scheduleConfig ?? null) as ScheduleConfig | null;
    const beforeConfig =
      (beforeData.scheduleConfig ?? null) as ScheduleConfig | null;
    if (
      beforeData.taskType === afterTask &&
      isSameScheduleConfig(beforeConfig, afterConfig)
    ) {
      return;
    }

    const {userId, taskId} = event.params;
    const userRef = getFirestore().collection("users").doc(userId);
    await recalcScheduleCache(userRef, taskId, afterTask, afterConfig);
  },
);

/**
 * taskDefinitions の lastExecutedAt / nextScheduledAt を実行履歴から再計算し書き戻し、
 * 再計算後の nextScheduledAt をもとに notifications の帳簿も更新する
 * @param {FirebaseFirestore.DocumentReference} userRef 対象ユーザーへの参照
 * @param {string} taskId 対象タスク定義の ID
 * @param {TaskType} taskType 対象タスクの種別
 * @param {ScheduleConfig | null} config scheduleConfig（scheduled のみ）
 * @return {Promise<void>} 完了を示す Promise
 */
async function recalcScheduleCache(
  userRef: FirebaseFirestore.DocumentReference,
  taskId: string,
  taskType: TaskType,
  config: ScheduleConfig | null,
): Promise<void> {
  const taskDefRef = taskDefinitionRef(userRef, taskId);
  // irregular は nextScheduledAt を持たず lastExecutedAt しか使わないため、
  // 平均間隔計算用の直近 scheduleHistoryLimit 件をまとめて読む必要がない
  const historyLimit = taskType === "irregular" ? 1 : scheduleHistoryLimit;
  const executionsSnap = await taskDefRef
    .collection("executions")
    .orderBy("executedAt")
    .limitToLast(historyLimit)
    .get();
  const ascendingHistory: Temporal.ZonedDateTime[] = executionsSnap.docs.map(
    (doc) => toZonedDateTime(doc.data().executedAt as Timestamp),
  );

  const lastExecutedAt = ascendingHistory.at(-1) ?? null;
  const scheduledAt = computeScheduledAt({
    taskType,
    ascendingHistory,
    scheduleValue: config?.scheduleValue ?? null,
    scheduleUnit: config?.scheduleUnit ?? null,
  });

  await taskDefRef.update({
    lastExecutedAt: lastExecutedAt ?
      Timestamp.fromMillis(lastExecutedAt.epochMilliseconds) :
      null,
    nextScheduledAt: scheduledAt ?
      Timestamp.fromMillis(scheduledAt.epochMilliseconds) :
      null,
  });

  // scheduledAt が null なら通知設定によらず対象外なので、users の読み取りを省く
  const userData = scheduledAt != null ? (await userRef.get()).data() : null;
  await syncNotifyAt({
    userRef,
    taskId,
    scheduledAt,
    setting: parseNotificationSetting(userData?.notificationSetting),
    timeZone: (userData?.timezone ?? null) as string | null,
  });
}

/**
 * users の notificationSetting / timezone の変更をトリガーに、
 * そのユーザーの全タスクの notifyAt を再計算する。
 * nextScheduledAt は変わらないが通知時刻の算出結果が変わるため、
 * recalcScheduleCache の経路では拾えない。
 * fcmTokens / lastActiveAt など notifyAt に影響しないフィールドの更新でも
 * 発火するため、通知に関わる変更がなければ何もせず抜ける。
 */
export const onUserWritten = onDocumentWritten(
  "users/{userId}",
  async (event) => {
    const afterSnap = event.data?.after;
    const afterData = afterSnap?.data();
    if (afterSnap == null || afterData == null) return; // 削除時は再計算不要

    const beforeData = event.data?.before.data();
    const beforeSetting = parseNotificationSetting(
      beforeData?.notificationSetting,
    );
    const afterSetting = parseNotificationSetting(
      afterData.notificationSetting,
    );
    const beforeTimeZone = (beforeData?.timezone ?? null) as string | null;
    const afterTimeZone = (afterData.timezone ?? null) as string | null;
    if (
      isSameNotificationSetting(beforeSetting, afterSetting) &&
      beforeTimeZone === afterTimeZone
    ) {
      return;
    }

    const userRef = afterSnap.ref;
    const taskDefsSnap = await userRef.collection("taskDefinitions").get();
    await Promise.all(taskDefsSnap.docs.map((doc) => {
      const nextScheduledAt = doc.data().nextScheduledAt as Timestamp | null;
      return syncNotifyAt({
        userRef,
        taskId: doc.id,
        scheduledAt: nextScheduledAt ?
          toZonedDateTime(nextScheduledAt) :
          null,
        setting: afterSetting,
        timeZone: afterTimeZone,
      });
    }));
  },
);

/**
 * notifications/{taskId} の notifyAt を算出して書き戻す。
 * 通知対象外なら notifyAt を null にせずフィールドごと削除する
 * （null は範囲クエリにヒットしてしまうため。schema.md 参照）。
 * 対象外のタスクはドキュメント自体を作らないので、既存ドキュメントがなければ何もしない。
 * @param {object} params
 * @param {FirebaseFirestore.DocumentReference} params.userRef 対象ユーザーへの参照
 * @param {string} params.taskId 対象タスク定義の ID
 * @param {Temporal.ZonedDateTime | null} params.scheduledAt 次回実行予定日時
 * @param {NotificationSetting | null} params.setting ユーザーの通知設定
 * @param {string | null} params.timeZone ユーザーのタイムゾーン
 * @return {Promise<void>} 完了を示す Promise
 */
async function syncNotifyAt(params: {
  userRef: FirebaseFirestore.DocumentReference;
  taskId: string;
  scheduledAt: Temporal.ZonedDateTime | null;
  setting: NotificationSetting | null;
  timeZone: string | null;
}): Promise<void> {
  const {userRef, taskId, scheduledAt, setting, timeZone} = params;
  const notificationRef = userRef.collection("notifications").doc(taskId);
  const notifyAt = computeNotifyAt({
    nextScheduledAt: scheduledAt,
    setting,
    timeZone,
  });

  if (scheduledAt == null || notifyAt == null) {
    const notificationSnap = await notificationRef.get();
    if (!notificationSnap.exists) return;
    // lastNotifiedFor は重複送信の防止に使うため残す
    await notificationRef.update({
      notifyAt: FieldValue.delete(),
      scheduledAt: FieldValue.delete(),
    });
    return;
  }

  await notificationRef.set({
    notifyAt: Timestamp.fromMillis(notifyAt.epochMilliseconds),
    scheduledAt: Timestamp.fromMillis(scheduledAt.epochMilliseconds),
  }, {merge: true});
}

/**
 * タスク定義 (taskDefinitions) の削除をトリガーに、
 * Firestore がカスケード削除しない実行履歴 (executions) サブコレクションと、
 * そのタスクの通知帳簿 (notifications) をお掃除する。
 * taskDefinitions が消えた後に executions を削除するため、それぞれの削除で
 * onExecutionWritten が発火すること自体は止められないのでそのままとしている。
 */
export const onTaskDefinitionDeleted = onDocumentDeleted(
  "users/{userId}/taskDefinitions/{taskId}",
  async (event) => {
    const {userId, taskId} = event.params;
    const db = getFirestore();
    const userRef = db.collection("users").doc(userId);

    await db.recursiveDelete(
      taskDefinitionRef(userRef, taskId).collection("executions"),
    );
    await userRef.collection("notifications").doc(taskId).delete();
  },
);

/**
 * ユーザー配下のタスク定義への参照を組み立てる
 * @param {FirebaseFirestore.DocumentReference} userRef 対象ユーザーへの参照
 * @param {string} taskId 対象タスク定義の ID
 * @return {FirebaseFirestore.DocumentReference} タスク定義への参照
 */
function taskDefinitionRef(
  userRef: FirebaseFirestore.DocumentReference,
  taskId: string,
): FirebaseFirestore.DocumentReference {
  return userRef.collection("taskDefinitions").doc(taskId);
}

/**
 * Firestore の Timestamp（タイムゾーンなしの瞬間）を
 * UTC 固定の Temporal.ZonedDateTime に変換する
 * @param {Timestamp} timestamp 変換対象の Timestamp
 * @return {Temporal.ZonedDateTime} UTC の ZonedDateTime
 */
function toZonedDateTime(timestamp: Timestamp): Temporal.ZonedDateTime {
  return Temporal.Instant.fromEpochMilliseconds(timestamp.toMillis())
    .toZonedDateTimeISO("UTC");
}
