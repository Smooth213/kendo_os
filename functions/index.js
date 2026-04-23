const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const vision = require("@google-cloud/vision");

admin.initializeApp();
const visionClient = new vision.ImageAnnotatorClient();

// リージョンを「大阪」に固定
setGlobalOptions({ region: "asia-northeast2" });

exports.processimageocr = onObjectFinalized(async (event) => {
  const object = event.data;
  const filePath = object.name; // 例: programs/ID または programs/ID/file.jpg
  
  // ★ 修正：動いたらまずこのログを絶対に出す！
  console.log(`★★★ 関数が起動しました！ 対象ファイル: ${filePath}`);

  const contentType = object.contentType;
  if (!contentType || !contentType.startsWith("image/")) {
    console.log("画像ではないためスキップします。");
    return;
  }

  // ★ 修正：パスの解析を柔軟に（programs フォルダに入っていればOK）
  const pathParts = filePath.split('/');
  if (pathParts[0] !== 'programs' || pathParts.length < 2) {
    console.log("対象外のフォルダです。");
    return;
  }
  
  // 2番目の要素を ID として取得
  const programId = pathParts[1];
  console.log(`OCR開始！ Program ID: ${programId}`);

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
    await admin.firestore().collection('programs').doc(programId).update({
      isOcrProcessed: true,
      ocrText: fullText,
      ocrWords: wordsData,
    });

    console.log(`★★★ OCR成功！ Firestoreを更新しました。 ID: ${programId}`);

  } catch (error) {
    console.error("OCRエラー発生:", error);
  }
});