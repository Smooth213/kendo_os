import { onObjectFinalized } from "firebase-functions/v2/storage";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { ImageAnnotatorClient } from "@google-cloud/vision";

admin.initializeApp();

// Cloud Vision API クライアントの初期化
const visionClient = new ImageAnnotatorClient();

export const processProgramImageOCR = onObjectFinalized(
  {
    region: "asia-northeast1",
    memory: "512MiB",
    timeoutSeconds: 60,
  },
  async (event) => {
    const fileBucket = event.data.bucket;
    const filePath = event.data.name;
    const contentType = event.data.contentType;

    // 画像ファイル以外（PDFなど）は OCR 解析をスキップ
    if (!contentType || !contentType.startsWith("image/")) {
      return;
    }

    // パスの検証とテナント・大会・プログラムIDの抽出
    // 期待するパス: organizations/{dojoId}/tournaments/{tournamentId}/programs/{programId}/{fileName}
    const pathParts = filePath.split("/");
    if (
      pathParts.length !== 7 ||
      pathParts[0] !== "organizations" ||
      pathParts[2] !== "tournaments" ||
      pathParts[4] !== "programs"
    ) {
      console.log("対象外のStorageパスのためスキップします:", filePath);
      return;
    }

    const dojoId = pathParts[1];
    const tournamentId = pathParts[3];
    const programId = pathParts[5];

    const gcsUri = `gs://${fileBucket}/${filePath}`;
    const docRef = admin
      .firestore()
      .doc(`organizations/${dojoId}/tournaments/${tournamentId}/programs/${programId}`);

    try {
      // Vision API を呼び出してドキュメントテキスト解析を実行
      const [result] = await visionClient.documentTextDetection(gcsUri);
      const annotations = result.textAnnotations;

      let words: any[] = [];

      // 解析結果が存在する場合、アプリ側の OcrHighlightPainter が期待する構造にパースする
      if (annotations && annotations.length > 0) {
        // annotations[0] は画像全体のテキストなので除外し、個別の単語(1以降)を抽出
        words = annotations.slice(1).map((annotation) => {
          const vertices = annotation.boundingPoly?.vertices || [];
          return {
            text: annotation.description || "",
            vertices: vertices.map((v) => ({
              x: v.x || 0,
              y: v.y || 0,
            })),
          };
        });
      }

      // Firestoreのドキュメントを更新して、アプリ側に「OCR完了」を通知
      await docRef.update({
        isOcrProcessed: true,
        ocrWords: words,
      });

      console.log(`OCR処理完了: ${programId} (抽出単語数: ${words.length})`);
    } catch (error) {
      console.error("OCR処理中にエラーが発生しました:", error);
      // エラー時も無限待ちを防ぐため完了フラグだけは立てる（空配列ならアプリ側で「検出されませんでした」と表示される）
      await docRef.update({ isOcrProcessed: true, ocrWords: [] }).catch(console.error);
    }
  }
);

// 🔔 アナウンス作成トリガー: Firestoreに登録された緊急お知らせをNative FCMトピックおよびWeb FCMトークンにプッシュ配信する
export const onAnnouncementCreated = onDocumentCreated(
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
      let query: admin.firestore.Query = admin.firestore()
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