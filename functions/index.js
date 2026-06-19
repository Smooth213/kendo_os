const { onObjectFinalized } = require("firebase-functions/v2/storage");
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