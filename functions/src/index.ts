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
  ScheduleUnit,
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

    const taskType = taskDefData.taskType as TaskType;
    const config = taskDefData.scheduleConfig as
      | {scheduleValue: number; scheduleUnit: string}
      | null;

    // irregular は nextScheduledAt を持たず lastExecutedAt しか使わないため、
    // 平均間隔計算用の直近 scheduleHistoryLimit 件をまとめて読む必要がない
    const historyLimit = taskType === "irregular" ? 1 : scheduleHistoryLimit;
    const executionsSnap = await taskDefRef
      .collection("executions")
      .orderBy("executedAt")
      .limitToLast(historyLimit)
      .get();
    const ascendingHistory: Date[] = executionsSnap.docs.map(
      (doc) => (doc.data().executedAt as Timestamp).toDate()
    );

    const lastExecutedAt = ascendingHistory.at(-1) ?? null;
    const scheduledAt = lastExecutedAt == null ? null : computeScheduledAt({
      taskType,
      ascendingHistory,
      lastExecutedAt,
      scheduleValue: config?.scheduleValue ?? null,
      scheduleUnit: config ? (config.scheduleUnit as ScheduleUnit) : null,
    });

    await taskDefRef.update({
      lastExecutedAt: lastExecutedAt ?
        Timestamp.fromDate(lastExecutedAt) :
        null,
      nextScheduledAt: scheduledAt ?
        Timestamp.fromDate(scheduledAt) :
        null,
    });
  }
);

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
  }
);
