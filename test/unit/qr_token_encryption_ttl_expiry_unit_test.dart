import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// 大会・審判QRコード一時認証トークン暗号署名＆TTL検証エンジン
class QrTokenSecurityEngine {
  static const String _secretKey = 'kendo_os_secure_qr_secret_salt_2026';

  /// トークン生成（ペイロード + HMAC-SHA256署名）
  static String generateToken({
    required String tournamentId,
    required String role,
    required DateTime expiresAt,
  }) {
    final payloadJson = jsonEncode({
      'tournamentId': tournamentId,
      'role': role,
      'exp': expiresAt.millisecondsSinceEpoch,
    });
    final payloadBase64 = base64Url.encode(utf8.encode(payloadJson));

    final hmac = Hmac(sha256, utf8.encode(_secretKey));
    final signature = hmac.convert(utf8.encode(payloadBase64)).toString();

    return '$payloadBase64.$signature';
  }

  /// トークン検証
  static ({bool isValid, String? tournamentId, String? role, String? error})
  verifyToken({required String token, required DateTime now}) {
    final parts = token.split('.');
    if (parts.length != 2) {
      return (
        isValid: false,
        tournamentId: null,
        role: null,
        error: 'Invalid token format',
      );
    }

    final payloadBase64 = parts[0];
    final signature = parts[1];

    // 1. HMAC 署名検証（改ざんチェック）
    final hmac = Hmac(sha256, utf8.encode(_secretKey));
    final expectedSignature = hmac
        .convert(utf8.encode(payloadBase64))
        .toString();
    if (signature != expectedSignature) {
      return (
        isValid: false,
        tournamentId: null,
        role: null,
        error: 'Signature verification failed (Tampered)',
      );
    }

    // 2. ペイロードのデコード
    try {
      final payloadJson = utf8.decode(base64Url.decode(payloadBase64));
      final data = jsonDecode(payloadJson) as Map<String, dynamic>;

      final expMs = data['exp'] as int?;
      if (expMs == null) {
        return (
          isValid: false,
          tournamentId: null,
          role: null,
          error: 'Missing expiry',
        );
      }

      // 3. 有効期限（TTL）検証
      if (now.millisecondsSinceEpoch > expMs) {
        return (
          isValid: false,
          tournamentId: null,
          role: null,
          error: 'Token expired',
        );
      }

      return (
        isValid: true,
        tournamentId: data['tournamentId'] as String?,
        role: data['role'] as String?,
        error: null,
      );
    } catch (e) {
      return (
        isValid: false,
        tournamentId: null,
        role: null,
        error: 'Malformed payload',
      );
    }
  }
}

void main() {
  group('🥋 【Phase 1-8/10】大会・審判QRコード一時トークン暗号署名＆TTL有効期限失効テスト', () {
    final baseTime = DateTime(2026, 9, 3, 10, 0, 0);

    test('1. 有効期限内の正規トークンが正しく検証・認証されること', () {
      final token = QrTokenSecurityEngine.generateToken(
        tournamentId: 'tourney_101',
        role: 'operator',
        expiresAt: baseTime.add(const Duration(hours: 24)),
      );

      // 1時間後にスキャン
      final result = QrTokenSecurityEngine.verifyToken(
        token: token,
        now: baseTime.add(const Duration(hours: 1)),
      );

      expect(result.isValid, isTrue);
      expect(result.tournamentId, 'tourney_101');
      expect(result.role, 'operator');
      expect(result.error, isNull);
    });

    test('2. 有効期限切れ（TTL Expiry: 24時間経過後）のトークンが確実に失効・遮断されること', () {
      final token = QrTokenSecurityEngine.generateToken(
        tournamentId: 'tourney_101',
        role: 'viewer',
        expiresAt: baseTime.add(const Duration(hours: 24)),
      );

      // 25時間後にスキャン ➔ 期限切れ
      final result = QrTokenSecurityEngine.verifyToken(
        token: token,
        now: baseTime.add(const Duration(hours: 25)),
      );

      expect(result.isValid, isFalse);
      expect(result.error, 'Token expired');
    });

    test('3. ペイロード改ざん（ViewerからAdminへの権限昇格工作）がHMAC検証で遮断されること', () {
      final originalToken = QrTokenSecurityEngine.generateToken(
        tournamentId: 'tourney_101',
        role: 'viewer',
        expiresAt: baseTime.add(const Duration(hours: 24)),
      );

      final parts = originalToken.split('.');
      // ペイロードを勝手に 'admin' に改ざん
      final fakePayload = base64Url.encode(
        utf8.encode(
          jsonEncode({
            'tournamentId': 'tourney_101',
            'role': 'admin',
            'exp': baseTime
                .add(const Duration(hours: 24))
                .millisecondsSinceEpoch,
          }),
        ),
      );
      final tamperedToken = '$fakePayload.${parts[1]}';

      final result = QrTokenSecurityEngine.verifyToken(
        token: tamperedToken,
        now: baseTime,
      );

      expect(result.isValid, isFalse);
      expect(result.error, contains('Tampered'));
    });
  });
}
