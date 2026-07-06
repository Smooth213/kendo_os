const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const vision = require("@google-cloud/vision");

admin.initializeApp();
const visionClient = new vision.ImageAnnotatorClient();

// リージョンをStorageと同じ「東京」に固定
setGlobalOptions({ region: "asia-northeast1" });

exports.processProgramImageOCR = onObjectFinalized(async (event) => {
  const object = event.data;
  const filePath = object.name; // 例: programs/ID または programs/ID/file.jpg
  
  // ★ 修正：動いたらまずこのログを絶対に出す！
  console.log(`★★★ 関数が起動しました！ 対象ファイル: ${filePath}`);

  const contentType = object.contentType;
  if (!contentType || !contentType.startsWith("image/")) {
    console.log("画像ではないためスキップします。");
    return;
  }

  // パスの解析（organizations/{dojoId}/tournaments/{tournamentId}/programs/{programId}/...）
  const pathParts = filePath.split('/');
  if (pathParts.length < 7 || pathParts[0] !== 'organizations' || pathParts[2] !== 'tournaments' || pathParts[4] !== 'programs') {
    console.log("対象外のフォルダです。");
    return;
  }
  
  const dojoId = pathParts[1];
  const tournamentId = pathParts[3];
  const programId = pathParts[5];
  console.log(`OCR開始！ Dojo ID: ${dojoId}, Tournament ID: ${tournamentId}, Program ID: ${programId}`);

  const gcsUri = `gs://${object.bucket}/${filePath}`;

  try {
    const [result] = await visionClient.textDetection(gcsUri);
    const detections = result.textAnnotations;
    
    let fullText = "";
    let wordsData = [];

    if (detections && detections.length > 0) {
      fullText = detections[0].description;
      wordsData = detections.slice(1).map(word => ({
        text: word.description,
        vertices: word.boundingPoly.vertices
      }));
    }

    // Firestoreを更新（isOcrProcessed を確実に true にする）
    await admin.firestore()
      .collection('organizations').doc(dojoId)
      .collection('tournaments').doc(tournamentId)
      .collection('programs').doc(programId).update({
      isOcrProcessed: true,
      ocrText: fullText,
      ocrWords: wordsData,
    });

    console.log(`★★★ OCR成功！ Firestoreを更新しました。 ID: ${programId}`);

  } catch (error) {
    console.error("OCRエラー発生:", error);
  }
});

// 🔔 アナウンス作成トリガー: Firestoreに登録された緊急お知らせをNative FCMトピックおよびWeb FCMトークンにプッシュ配信する
exports.onAnnouncementCreated = onDocumentCreated(
  {
    document: "announcements/{announceId}",
    region: "asia-northeast1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const data = snapshot.data();
    if (!data) return;

    const tournamentId = data.tournamentId;
    const title = data.title || "大会本部からのお知らせ";
    const body = data.body || "";
    const target = data.target || "all";

    console.log(`🔔 onAnnouncementCreated 起動! ID: ${event.params.announceId}, Tournament: ${tournamentId}`);

    // 1. ネイティブ (iOS/Android) 向けトピック配信用のペイロードを作成
    const topic = target === "staff"
      ? `tournament_${tournamentId}_staff`
      : `tournament_${tournamentId}_all`;

    const topicPayload = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: "emergency",
        tournamentId: tournamentId,
        target: target,
      },
      topic: topic,
    };

    try {
      const response = await admin.messaging().send(topicPayload);
      console.log(`Successfully sent message to Native topic ${topic}:`, response);
    } catch (error) {
      console.error(`Error sending message to Native topic ${topic}:`, error);
    }

    // 2. Web (PWA) 向けに fcm_tokens からデバイスを取得しマルチキャスト配信を実行
    try {
      let query = admin.firestore()
        .collection("fcm_tokens")
        .where("tournamentId", "==", tournamentId);

      if (target === "staff") {
        query = query.where("isStaff", "==", true);
      }

      const tokenSnapshot = await query.get();
      if (!tokenSnapshot.empty) {
        const tokens = tokenSnapshot.docs.map(doc => doc.data().token).filter(t => !!t);
        if (tokens.length > 0) {
          const webPayload = {
            notification: {
              title: title,
              body: body,
            },
            data: {
              type: "emergency",
              tournamentId: tournamentId,
              target: target,
            },
            tokens: tokens,
          };

          const response = await admin.messaging().sendEachForMulticast(webPayload);
          console.log(`Successfully sent message to Web tokens count ${tokens.length}:`, response.successCount);
        }
      }
    } catch (error) {
      console.error(`Error sending Web push notifications:`, error);
    }
  }
);