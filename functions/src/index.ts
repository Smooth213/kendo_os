import { onObjectFinalized } from "firebase-functions/v2/storage";
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