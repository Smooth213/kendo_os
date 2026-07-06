const fft = require("firebase-functions-test")();
const vision = require("@google-cloud/vision");

// 1. Firebase Admin と Firestore のチェーン呼び出しをモック化
jest.mock("firebase-admin", () => {
  const mockSend = jest.fn().mockResolvedValue("native-msg-id");
  const mockSendEachForMulticast = jest.fn().mockResolvedValue({ successCount: 1 });
  const mockGet = jest.fn().mockResolvedValue({
    empty: false,
    docs: [
      {
        data: () => ({
          token: "token-1",
          userId: "user-1",
        }),
      },
      {
        data: () => ({
          token: "token-2",
          userId: "sender-uid",
        }),
      },
    ],
  });

  const mockQuery = {
    get: mockGet,
    where: jest.fn(function() { return this; }),
  };

  const mockDoc = {
    update: jest.fn().mockResolvedValue(true),
    collection: jest.fn(() => mockCollection),
  };

  const mockCollection = {
    doc: jest.fn(() => mockDoc),
    where: jest.fn(() => mockQuery),
  };

  return {
    initializeApp: jest.fn(),
    firestore: jest.fn(() => ({
      collection: jest.fn(() => mockCollection),
    })),
    messaging: jest.fn(() => ({
      send: mockSend,
      sendEachForMulticast: mockSendEachForMulticast,
    })),
    _updateMock: mockDoc.update,
    _sendMock: mockSend,
    _sendEachForMulticastMock: mockSendEachForMulticast,
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

describe("onAnnouncementCreated", () => {
  afterAll(() => {
    fft.cleanup();
  });

  it("お知らせが作成されたとき、送信者以外のデバイストークンにのみWebプッシュ通知を配信すること", async () => {
    const admin = require("firebase-admin");

    const mockEvent = {
      data: {
        data: () => ({
          tournamentId: "tourney_123",
          title: "緊急連絡",
          body: "試合順序が変更になりました",
          target: "all",
          createdBy: "sender-uid",
        }),
      },
      params: {
        announceId: "announce_abc",
      },
    };

    await myFunctions.onAnnouncementCreated.run(mockEvent);

    // 検証①: トピック宛のネイティブ送信が実行されたか
    expect(admin._sendMock).toHaveBeenCalled();
    const sentTopicPayload = admin._sendMock.mock.calls[0][0];
    expect(sentTopicPayload.topic).toBe("tournament_tourney_123_all");

    // 検証②: Webマルチキャスト送信において送信者自身（sender-uid）のトークン（token-2）が除外され、もう一方（token-1）のみに送られたか
    expect(admin._sendEachForMulticastMock).toHaveBeenCalled();
    const sentWebPayload = admin._sendEachForMulticastMock.mock.calls[0][0];
    expect(sentWebPayload.tokens).toContain("token-1");
    expect(sentWebPayload.tokens).not.toContain("token-2"); // 送信者トークンは除外されていること
  });
});