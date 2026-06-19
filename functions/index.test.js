const fft = require("firebase-functions-test")();
const vision = require("@google-cloud/vision");

// 1. Firebase Admin と Firestore のチェーン呼び出しをモック化
jest.mock("firebase-admin", () => {
  const updateMock = jest.fn().mockResolvedValue(true); // update() のモック

  // .doc() が返すオブジェクトのモック
  const docMock = {
    update: updateMock,
    // .doc('...').collection('...') のようなチェーンを可能にする
    collection: jest.fn(() => collectionMock),
  };

  // .collection() が返すオブジェクトのモック
  const collectionMock = {
    doc: jest.fn(() => docMock),
  };

  return {
    initializeApp: jest.fn(),
    // admin.firestore() が collection メソッドを持つオブジェクトを返すようにする
    firestore: jest.fn(() => ({
      collection: jest.fn(() => collectionMock),
    })),
    _updateMock: updateMock, // テストの検証用にエクスポート
  };
});

// 2. Cloud Vision API のモック化
jest.mock("@google-cloud/vision", () => {
  const textDetectionMock = jest.fn();
  return {
    ImageAnnotatorClient: jest.fn(() => ({
      textDetection: textDetectionMock,
    })),
  };
});

// モック設定後にテスト対象の関数を読み込む
const myFunctions = require("./index.js");

describe("processProgramImageOCR", () => {
  let visionClient;

  beforeEach(() => {
    jest.clearAllMocks();
    visionClient = new vision.ImageAnnotatorClient();
  });

  afterAll(() => {
    fft.cleanup();
  });

  it("正しい画像がアップロードされた場合、Vision APIが呼ばれてFirestoreが更新されること", async () => {
    // Vision API が返すダミーの解析結果
    visionClient.textDetection.mockResolvedValue([
      {
        textAnnotations: [
          { description: "剣道大会 第1回" }, // [0] は全体テキスト
          { description: "剣道", boundingPoly: { vertices: [{ x: 10, y: 10 }, { x: 20, y: 10 }] } },
          { description: "大会", boundingPoly: { vertices: [{ x: 30, y: 10 }, { x: 40, y: 10 }] } },
        ],
      },
    ]);

    // Storage に画像が保存された時のイベントをシミュレート
    const mockEvent = {
      data: {
        name: "organizations/dojo1/tournaments/tour1/programs/prog1/image.jpg",
        bucket: "kendo-os-beta.firebasestorage.app",
        contentType: "image/jpeg",
      },
    };

    const wrapped = fft.wrap(myFunctions.processProgramImageOCR);
    await wrapped(mockEvent);

    // 検証①: Vision API が正しいGCSパスで呼ばれたか
    expect(visionClient.textDetection).toHaveBeenCalledWith(
      "gs://kendo-os-beta.firebasestorage.app/organizations/dojo1/tournaments/tour1/programs/prog1/image.jpg"
    );

    // 検証②: Firestore の update() が正しい抽出データで呼ばれたか
    const { _updateMock } = require("firebase-admin");
    expect(_updateMock).toHaveBeenCalledWith({
      isOcrProcessed: true,
      ocrText: "剣道大会 第1回",
      ocrWords: [
        { text: "剣道", vertices: [{ x: 10, y: 10 }, { x: 20, y: 10 }] },
        { text: "大会", vertices: [{ x: 30, y: 10 }, { x: 40, y: 10 }] },
      ],
    });
  });

  it("画像以外のファイル(PDFなど)の場合は処理をスキップすること", async () => {
    const mockEvent = { data: { name: "test.pdf", contentType: "application/pdf" } };
    await fft.wrap(myFunctions.processProgramImageOCR)(mockEvent);
    expect(visionClient.textDetection).not.toHaveBeenCalled();
  });

  it("対象外のStorageパスの場合は処理をスキップすること", async () => {
    const mockEvent = { data: { name: "users/icon.jpg", contentType: "image/jpeg" } };
    await fft.wrap(myFunctions.processProgramImageOCR)(mockEvent);
    expect(visionClient.textDetection).not.toHaveBeenCalled();
  });
});