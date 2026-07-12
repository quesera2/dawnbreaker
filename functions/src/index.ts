import {Temporal} from "@js-temporal/polyfill";
import {setGlobalOptions} from "firebase-functions";
import {
  onDocumentDeleted,
  onDocumentWritten,
} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {
  computeScheduledAt,
  isSameScheduleConfig,
  ScheduleConfig,
  TaskType,
  scheduleHistoryLimit,
} from "./schedule";

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
    const db = getFirestore();
    const taskDefRef = db
      .collection("users")
      .doc(userId)
      .collection("taskDefinitions")
      .doc(taskId);

    const taskDefSnap = await taskDefRef.get();
    const taskDefData = taskDefSnap.data();
    if (taskDefData == null) {
      // タスク削除時、onTaskDefinitionDeleted が executions を掃除する過程で
      // 本トリガーが発火した場合に毎回通る正常系のため info に留める
      logger.info("taskDefinition not found", {userId, taskId});
      return;
    }

    await recalcScheduleCache(
      taskDefRef,
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
    const taskDefRef = getFirestore()
      .collection("users")
      .doc(userId)
      .collection("taskDefinitions")
      .doc(taskId);
    await recalcScheduleCache(taskDefRef, afterTask, afterConfig);
  },
);

/**
 * taskDefinitions の lastExecutedAt / nextScheduledAt を実行履歴から再計算し書き戻す
 * @param {FirebaseFirestore.DocumentReference} taskDefRef 対象タスク定義への参照
 * @param {TaskType} taskType 対象タスクの種別
 * @param {ScheduleConfig | null} config scheduleConfig（scheduled のみ）
 * @return {Promise<void>} 完了を示す Promise
 */
async function recalcScheduleCache(
  taskDefRef: FirebaseFirestore.DocumentReference,
  taskType: TaskType,
  config: ScheduleConfig | null,
): Promise<void> {
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
}

/**
 * タスク定義 (taskDefinitions) の削除をトリガーに、
 * Firestore がカスケード削除しない実行履歴 (executions) サブコレクションをお掃除する。
 * taskDefinitions が消えた後に executions を削除するため、それぞれの削除で
 * onExecutionWritten が発火すること自体は止められないのでそのままとしている。
 */
export const onTaskDefinitionDeleted = onDocumentDeleted(
  "users/{userId}/taskDefinitions/{taskId}",
  async (event) => {
    const {userId, taskId} = event.params;
    const db = getFirestore();
    const executionsRef = db
      .collection("users")
      .doc(userId)
      .collection("taskDefinitions")
      .doc(taskId)
      .collection("executions");

    await db.recursiveDelete(executionsRef);
  },
);

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
