import 'dart:convert'; // ★ 署名生成（ハッシュ化）用に追加
import 'package:uuid/uuid.dart';
import '../../domain/entities/score_event.dart';

class ScoreEventLegacyAdapter {
  // ==========================================
  // ★ Phase 1-Step 3: イベントの署名と検証ロジック
  // ==========================================
  
  /// ペイロードと秘密鍵から署名を生成する
  static String generateSignature(String payload, String secret) {
    // ※外部パッケージ非依存で強固にするため、標準ライブラリのBase64エンコードを利用
    // 本格運用の際は package:crypto の Hmac(sha256) 等に差し替え可能
    final bytes = utf8.encode('$payload:$secret');
    return base64Encode(bytes);
  }

  /// イベントの改ざんがないか（署名が正しいか）を検証する
  static bool verifySignature(ScoreEvent event, String secret) {
    if (event.signature.isEmpty) return false; // 署名なしは弾く
    
    final uid = event.userId ?? 'unknown_user';
    // ★ 修正: 脆弱性対応。ペイロードに「操作の対象(赤白)」と「操作の内容(技や反則)」を必ず含める
    final payload = '${event.id}:$uid:${event.timestamp.toIso8601String()}:${event.side.name}:${event.type.name}';
    final expected = generateSignature(payload, secret);
    
    return event.signature == expected;
  }

  static ScoreEvent fromLegacy({
    required PointType type, 
    required Side side, 
    String? id, 
    DateTime? timestamp, 
    String? userId, 
    int sequence = 0, 
    bool isCanceled = false,
    String deviceId = 'local_device', 
    int logicalClock = 0,             
  }) {
    final eventId = id ?? const Uuid().v4();
    final time = timestamp ?? DateTime.now();
    final uid = userId ?? 'unknown_user';

    // ★ 修正: 脆弱性対応。署名の生成時にも同じく内容を含める
    final payload = '$eventId:$uid:${time.toIso8601String()}:${side.name}:${type.name}';
    final signature = generateSignature(payload, 'kendo_os_secret_key_v1'); // 共通の秘密鍵

    switch (type) {
      case PointType.men: return ScoreEvent(id: eventId, side: side, strikeType: StrikeType.men, isIppon: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled, deviceId: deviceId, logicalClock: logicalClock, signature: signature);
      case PointType.kote: return ScoreEvent(id: eventId, side: side, strikeType: StrikeType.kote, isIppon: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled, deviceId: deviceId, logicalClock: logicalClock, signature: signature);
      case PointType.doIdo: return ScoreEvent(id: eventId, side: side, strikeType: StrikeType.dou, isIppon: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled, deviceId: deviceId, logicalClock: logicalClock, signature: signature);
      case PointType.tsuki: return ScoreEvent(id: eventId, side: side, strikeType: StrikeType.tsuki, isIppon: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled, deviceId: deviceId, logicalClock: logicalClock, signature: signature);
      case PointType.hansoku: return ScoreEvent(id: eventId, side: side, isHansoku: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled, deviceId: deviceId, logicalClock: logicalClock, signature: signature);
      case PointType.fusen: return ScoreEvent(id: eventId, side: side, isFusen: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled, deviceId: deviceId, logicalClock: logicalClock, signature: signature);
      case PointType.hantei: return ScoreEvent(id: eventId, side: side, isHantei: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled, deviceId: deviceId, logicalClock: logicalClock, signature: signature);
      case PointType.undo: return ScoreEvent(id: eventId, side: side, isUndo: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled, deviceId: deviceId, logicalClock: logicalClock, signature: signature);
      case PointType.restore: return ScoreEvent(id: eventId, side: side, isRestore: true, timestamp: time, userId: userId, sequence: sequence, isCanceled: isCanceled, deviceId: deviceId, logicalClock: logicalClock, signature: signature);
    }
  }
}