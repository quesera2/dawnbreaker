import {Temporal} from "@js-temporal/polyfill";
import {setGlobalOptions} from "firebase-functions";
import {
  onDocumentDeleted,
  onDocumentWritten,
} from "firebase-functions/v2/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {defineInt} from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {FirebaseAuthError, getAuth} from "firebase-admin/auth";
import {FieldValue, getFirestore, Timestamp} from "firebase-admin/firestore";
import {getMessaging, Message} from "firebase-admin/messaging";
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
  shouldSendNotification,
} from "./notify";
import {isAnonymous, isInactive, thresholdFrom} from "./cleanup";

setGlobalOptions({maxInstances: 1});

initializeApp();

// 個別通知の Android チャンネル ID。
const androidChannelId = "individual_task_notification";

// 通知本文。サーバー側はロケールを持たないため日本語固定とする（多言語対応は別途）。
const notificationBody = "予定日になりました";

// sendEach() の1回の呼び出しで送信できるメッセージ数の上限
const sendEachChunkSize = 500;

// 放置アカウントの回収を走らせるスケジュール（日次 3:00）
const cleanupSchedule = "0 3 * * *";
const cleanupTimeZone = "Asia/Tokyo";

// 1回の実行で削除するユーザーの数。recursiveDelete と deleteUser は重く、
// maxInstances が 1 なのでタイムアウトすると実行全体が落ちる。超過分は次回に回る
const cleanupBatchLimit = 200;

// Auth に一度に存在を問い合わせる uid の数。getUsers() の受け取れる上限が 100 件
const getUsersChunkSize = 100;

// 一度に取得するユーザードキュメントの数。getAll() 側に上限はないので、
// 一度に抱える量が増えすぎない程度に区切っている
const getAllChunkSize = 300;

// Auth から一度に受け取るユーザーの数。listUsers() が1ページで返せる上限が 1000 件
const listUsersPageSize = 1000;

// Auth に無い uid の Firestore データを消すまでの猶予日数。
// 既定値は prod 想定の値にしておく。.env を置き忘れたプロジェクトへデプロイしたときに、
// 短い猶予のまま消しにいかないようにするため
const orphanedUserDataRetentionDays = defineInt(
  "ORPHANED_USER_DATA_RETENTION_DAYS", {default: 7},
);

// 匿名かつ使われていないアカウントを消すまでの猶予日数
const inactiveAnonymousAccountRetentionDays = defineInt(
  "INACTIVE_ANONYMOUS_ACCOUNT_RETENTION_DAYS", {default: 180},
);

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

    const taskDefSnap = await taskDefinitionRef(userId, taskId).get();
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
  const taskDefRef = taskDefinitionRef(userRef.id, taskId);
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
      taskDefinitionRef(userId, taskId).collection("executions"),
    );
    await userRef.collection("notifications").doc(taskId).delete();
  },
);

/**
 * サインイン中のユーザー自身のデータとアカウントを削除する。
 *
 * uid は引数で受けず request.auth から取る。引数で受けると他人の uid を渡して
 * 消せてしまうため。クライアントの user.delete() は requires-recent-login で
 * 失敗しうるので、Admin SDK 側で消す。
 *
 * Firestore → Auth の順で消す。逆順だとデータ削除に失敗したときユーザーが
 * サインインできなくなり、自力で再実行できないまま users/{uid} が誰にも
 * 辿れないゴミとして残る。この順なら Auth が生きているので、もう一度削除を
 * 実行すれば続きから消せる。
 */
export const deleteAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (uid == null) {
    throw new HttpsError("unauthenticated", "sign-in is required");
  }

  const db = getFirestore();
  // サブコレクション（taskDefinitions / executions / notifications）は
  // ドキュメントを消しても残るため、recursiveDelete でまとめて消す
  await db.recursiveDelete(db.collection("users").doc(uid));
  if (await deleteAuthUser(uid)) {
    logger.info("account deleted", {uid});
  } else {
    // 他端末で先に消された場合。消えていることが目的なので成功として返す
    logger.info("account was already deleted", {uid});
  }
});

/**
 * Auth に存在しない uid の Firestore データを回収する。
 *
 * アカウント削除は Firestore → Auth の順で消すため、Auth だけが残った状態は
 * もう一度削除を実行すれば片付く。逆に Auth 側が先に消える経路（他端末からの削除、
 * コンソールからの手動削除）では users/{uid} が誰にも辿れないゴミとして残り、
 * 誰も消せない。それをここで拾う。
 *
 * lastActiveAt が無いドキュメントも対象に含めるため、where では絞れない
 * （フィールドの無いドキュメントはインデックスに載らずクエリに現れない）。
 * select() で転送量だけ落として全件を読む
 */
export const cleanupOrphanedUserData = onSchedule(
  {schedule: cleanupSchedule, timeZone: cleanupTimeZone},
  async () => {
    const db = getFirestore();
    const threshold = thresholdFrom(
      Temporal.Now.zonedDateTimeISO("UTC"),
      orphanedUserDataRetentionDays.value(),
    );

    const snapshot = await db.collection("users").select("lastActiveAt").get();
    const candidateIds = snapshot.docs
      .filter((doc) => isInactive(lastActiveAtOf(doc), threshold))
      .map((doc) => doc.id);
    const targetIds = await filterMissingInAuth(
      candidateIds, cleanupBatchLimit,
    );

    let deletedCount = 0;
    for (const userId of targetIds) {
      try {
        await db.recursiveDelete(db.collection("users").doc(userId));
        deletedCount += 1;
      } catch (error) {
        // 1 件の失敗で残りを巻き添えにしない。消し損ねた分は次回の実行で拾う
        logger.error("failed to delete orphaned user data", {userId, error});
      }
    }
    logger.info("orphaned user data cleaned up", {
      candidates: candidateIds.length,
      targets: targetIds.length,
      deleted: deletedCount,
    });
  },
);

/**
 * 渡した uid のうち Auth に存在しないものを、上限に達するまで返す。
 * 上限で打ち切るのは、その回で消さない分まで Auth に問い合わせないため
 * @param {string[]} userIds 照会する uid の一覧
 * @param {number} limit 集める件数の上限
 * @return {Promise<string[]>} Auth に存在しなかった uid の一覧
 */
async function filterMissingInAuth(
  userIds: string[],
  limit: number,
): Promise<string[]> {
  const missingIds: string[] = [];
  for (
    let i = 0;
    i < userIds.length && missingIds.length < limit;
    i += getUsersChunkSize
  ) {
    const chunk = userIds.slice(i, i + getUsersChunkSize);
    const result = await getAuth().getUsers(chunk.map((uid) => ({uid})));
    for (const identifier of result.notFound) {
      // uid でしか問い合わせていないので、返るのも uid の識別子だけ
      if ("uid" in identifier) missingIds.push(identifier.uid);
    }
  }
  return missingIds.slice(0, limit);
}

/**
 * 匿名のまま使われていないアカウントを Auth ごと回収する。
 *
 * Auth を全走査する。Firestore の users を起点にすると、ゲストを作った直後に
 * 使われなくなって users/{uid} すら無いアカウント（まさに回収したい形）を拾えない。
 *
 * 削除の順序は deleteAccount と同じく Firestore → Auth。逆順だとデータ削除に
 * 失敗したとき、誰にも辿れない users/{uid} が残る
 */
export const cleanupInactiveAnonymousAccounts = onSchedule(
  {schedule: cleanupSchedule, timeZone: cleanupTimeZone},
  async () => {
    const db = getFirestore();
    const threshold = thresholdFrom(
      Temporal.Now.zonedDateTimeISO("UTC"),
      inactiveAnonymousAccountRetentionDays.value(),
    );

    const anonymousIds = await listAnonymousUserIds();
    const targetIds = await filterInactiveUserIds(
      anonymousIds, threshold, cleanupBatchLimit,
    );

    let deletedCount = 0;
    for (const userId of targetIds) {
      try {
        await db.recursiveDelete(db.collection("users").doc(userId));
        await deleteAuthUser(userId);
        deletedCount += 1;
      } catch (error) {
        // 1 件の失敗で残りを巻き添えにしない。Firestore だけ消えた中途半端な状態も
        // 次回は「匿名かつ users ドキュメントが無い」として同じ対象に戻る
        logger.error("failed to delete inactive anonymous account", {
          userId, error,
        });
      }
    }
    logger.info("inactive anonymous accounts cleaned up", {
      anonymous: anonymousIds.length,
      targets: targetIds.length,
      deleted: deletedCount,
    });
  },
);

/**
 * Auth の全ユーザーから匿名ユーザーの uid を集める
 * @return {Promise<string[]>} 匿名ユーザーの uid の一覧
 */
async function listAnonymousUserIds(): Promise<string[]> {
  const userIds: string[] = [];
  let pageToken: string | undefined;
  do {
    const result = await getAuth().listUsers(listUsersPageSize, pageToken);
    for (const user of result.users) {
      if (isAnonymous(user)) userIds.push(user.uid);
    }
    pageToken = result.pageToken;
  } while (pageToken != null);
  return userIds;
}

/**
 * 渡した uid のうち、最終アクティブ日時がしきい値より古いものを上限まで返す。
 * users/{uid} は初期化していないため存在しないことがあり、その場合も対象に含める。
 * 上限で打ち切るのは、その回で消さない分まで Firestore を読まないため
 * @param {string[]} userIds 判定する uid の一覧
 * @param {Temporal.ZonedDateTime} threshold 放置とみなすしきい値
 * @param {number} limit 集める件数の上限
 * @return {Promise<string[]>} 放置とみなせる uid の一覧
 */
async function filterInactiveUserIds(
  userIds: string[],
  threshold: Temporal.ZonedDateTime,
  limit: number,
): Promise<string[]> {
  const db = getFirestore();
  const inactiveIds: string[] = [];
  for (
    let i = 0;
    i < userIds.length && inactiveIds.length < limit;
    i += getAllChunkSize
  ) {
    const refs = userIds
      .slice(i, i + getAllChunkSize)
      .map((userId) => db.collection("users").doc(userId));
    const snapshots = await db.getAll(...refs, {fieldMask: ["lastActiveAt"]});
    for (const snapshot of snapshots) {
      if (isInactive(lastActiveAtOf(snapshot), threshold)) {
        inactiveIds.push(snapshot.id);
      }
    }
  }
  return inactiveIds.slice(0, limit);
}

/**
 * Auth のユーザーを削除する。既に存在しない場合は消えていることが目的なので握る
 * @param {string} userId 削除するユーザーの uid
 * @return {Promise<boolean>} 実際に削除したなら true、既に無かったなら false
 */
async function deleteAuthUser(userId: string): Promise<boolean> {
  try {
    await getAuth().deleteUser(userId);
    return true;
  } catch (error) {
    if (
      error instanceof FirebaseAuthError &&
      error.code === "auth/user-not-found"
    ) {
      return false;
    }
    throw error;
  }
}

/**
 * users ドキュメントの最終アクティブ日時を読む。
 * users/{uid} は初期化していないため、フィールドが無いことがある
 * @param {FirebaseFirestore.DocumentSnapshot} snapshot 対象のドキュメント
 * @return {Temporal.ZonedDateTime | null} 最終アクティブ日時、無ければ null
 */
function lastActiveAtOf(
  snapshot: FirebaseFirestore.DocumentSnapshot,
): Temporal.ZonedDateTime | null {
  const lastActiveAt = snapshot.get("lastActiveAt");
  return lastActiveAt instanceof Timestamp ?
    toZonedDateTime(lastActiveAt) :
    null;
}

/**
 * 5分間隔で notifications の帳簿を検索し、送信対象になった通知を FCM で送る。
 * タスクごとに送信 API を呼ぶと対象件数分だけ HTTP 呼び出しが発生してしまうため、
 * その回の対象を Message[] にまとめて sendEach() でバッチ送信する。
 */
export const sendScheduledNotifications = onSchedule(
  "every 5 minutes",
  async () => {
    const db = getFirestore();
    const snapshot = await db
      .collectionGroup("notifications")
      .where("notifyAt", "<=", Timestamp.now())
      .get();
    if (snapshot.empty) return;

    const targets: NotificationTarget[] = [];
    const bulkWriter = db.bulkWriter();
    try {
      for (const doc of snapshot.docs) {
        const data = doc.data();
        const scheduledAtTimestamp = data.scheduledAt as Timestamp;
        const scheduledAt = toZonedDateTime(scheduledAtTimestamp);
        const lastNotifiedFor = data.lastNotifiedFor == null ?
          null :
          toZonedDateTime(data.lastNotifiedFor as Timestamp);
        if (!shouldSendNotification(scheduledAt, lastNotifiedFor)) {
          // 他トリガーによる notifyAt の再計算で復活した、送信済み分の帳簿。
          // notifyAt だけ削除する（詳細は schema.md）
          bulkWriter.update(doc.ref, {notifyAt: FieldValue.delete()});
          continue;
        }
        const userRef = doc.ref.parent.parent;
        if (userRef == null) continue; // notifications はユーザーの子なので実際には起きない
        targets.push({
          userId: userRef.id,
          taskId: doc.id,
          ref: doc.ref,
          scheduledAt: scheduledAtTimestamp,
        });
      }

      const {invalidTokensByUser, sentTargetPaths, unreachableTargetPaths} =
        await sendNotifications(targets);
      for (const target of targets) {
        if (sentTargetPaths.has(target.ref.path)) {
          bulkWriter.update(target.ref, {
            lastNotifiedFor: target.scheduledAt,
            notifyAt: FieldValue.delete(),
          });
        } else if (unreachableTargetPaths.has(target.ref.path)) {
          // 配信先がなく試行すらしていないため、lastNotifiedFor は更新しない。
          // スケジュール再計算で notifyAt が復活すれば改めて送信対象になる。
          bulkWriter.update(target.ref, {notifyAt: FieldValue.delete()});
        }
        // どちらでもなければ一時的な送信失敗のため、notifyAt を残し次回に委ねる
      }
      for (const [userId, tokens] of invalidTokensByUser) {
        bulkWriter.update(db.collection("users").doc(userId), {
          fcmTokens: FieldValue.arrayRemove(...tokens),
        });
      }
    } finally {
      await bulkWriter.close();
    }
  },
);

/**
 * 送信対象となった notifications 帳簿 1 件分
 */
type NotificationTarget = {
  userId: string;
  taskId: string;
  ref: FirebaseFirestore.DocumentReference;
  scheduledAt: Timestamp;
};

/**
 * 送信対象の 1 端末分。送信する Message とその宛先情報を 1 つにまとめたもの。
 * 別々の配列に分けると、チャンク分割時のインデックス対応が壊れやすいため。
 */
type MessageEntry = {
  message: Message;
  userId: string;
  token: string;
  targetPath: string;
};

/**
 * sendNotifications() の結果
 */
type SendNotificationsResult = {
  // 無効だったトークンのユーザーごとの集合
  invalidTokensByUser: Map<string, Set<string>>;
  // デバイストークンが１通でも送信に成功した target の ref.path の集合
  sentTargetPaths: Set<string>;
  // タスクが読めない、または送信先の端末がない場合（再送不要として扱う）
  unreachableTargetPaths: Set<string>;
};

/**
 * 対象の通知をタスク名・fcmTokens で解決して FCM に送信する。
 * 同じユーザーの users ドキュメントはタスクが複数あっても 1 回だけ読む。
 * @param {NotificationTarget[]} targets 送信対象の一覧
 * @return {Promise<SendNotificationsResult>} 送信結果
 */
async function sendNotifications(
  targets: NotificationTarget[],
): Promise<SendNotificationsResult> {
  const invalidTokensByUser = new Map<string, Set<string>>();
  const sentTargetPaths = new Set<string>();
  const unreachableTargetPaths = new Set<string>();
  if (targets.length === 0) {
    return {invalidTokensByUser, sentTargetPaths, unreachableTargetPaths};
  }

  const getTaskName = (
    userId: string,
    taskId: string,
  ): Promise<string | null> => taskDefinitionRef(userId, taskId).get()
    .then((snapshot) => (snapshot.data()?.name ?? null) as string | null);

  // ユーザーごとに１回だけ FCM トークンを取得する
  const fcmTokensByUser = new Map<string, Promise<string[]>>();
  const getCachedFcmTokens = (userId: string): Promise<string[]> => {
    const cached = fcmTokensByUser.get(userId);
    if (cached != null) return cached;
    const promise = getFirestore().collection("users").doc(userId).get()
      .then((snapshot) => (snapshot.data()?.fcmTokens ?? []) as string[]);
    fcmTokensByUser.set(userId, promise);
    return promise;
  };

  const entries: MessageEntry[] = [];
  await Promise.all(targets.map(async (target) => {
    const [taskName, fcmTokens] = await Promise.all([
      getTaskName(target.userId, target.taskId),
      getCachedFcmTokens(target.userId),
    ]);
    if (taskName == null || fcmTokens.length === 0) {
      unreachableTargetPaths.add(target.ref.path);
      return;
    }

    for (const token of fcmTokens) {
      entries.push({
        message: {
          token,
          notification: {title: taskName, body: notificationBody},
          android: {notification: {channelId: androidChannelId}},
        },
        userId: target.userId,
        token,
        targetPath: target.ref.path,
      });
    }
  }));

  const messaging = getMessaging();
  for (let i = 0; i < entries.length; i += sendEachChunkSize) {
    const chunk = entries.slice(i, i + sendEachChunkSize);
    try {
      const response = await messaging.sendEach(
        chunk.map((entry) => entry.message),
      );
      response.responses.forEach((result, index) => {
        const entry = chunk[index];
        if (result.success) {
          sentTargetPaths.add(entry.targetPath);
          return;
        }
        if (result.error?.code !==
          "messaging/registration-token-not-registered") {
          logger.error("failed to send notification", {
            error: result.error,
            userId: entry.userId,
          });
          return;
        }
        const tokens = invalidTokensByUser.get(entry.userId) ??
          new Set<string>();
        tokens.add(entry.token);
        invalidTokensByUser.set(entry.userId, tokens);
      });
    } catch (error) {
      // このチャンクの target は送信済みリストに入らないため、
      // 呼び出し元は notifyAt を消さず次回（5分後）に再度通知する
      logger.error("failed to send notification chunk", {error});
    }
  }

  return {invalidTokensByUser, sentTargetPaths, unreachableTargetPaths};
}

/**
 * ユーザー配下のタスク定義への参照を組み立てる
 * @param {string} userId 対象ユーザーの ID
 * @param {string} taskId 対象タスク定義の ID
 * @return {FirebaseFirestore.DocumentReference} タスク定義への参照
 */
function taskDefinitionRef(
  userId: string,
  taskId: string,
): FirebaseFirestore.DocumentReference {
  return getFirestore()
    .collection("users").doc(userId)
    .collection("taskDefinitions").doc(taskId);
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
