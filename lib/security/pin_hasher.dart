import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';

/// 道場入室PIN（合言葉）の入力バリデーション結果
class JoinPinValidationResult {
  final bool isValid;
  final String? errorMessage;
  final bool isRecommendedLength;

  const JoinPinValidationResult({
    required this.isValid,
    this.errorMessage,
    this.isRecommendedLength = false,
  });

  const JoinPinValidationResult.ok({required this.isRecommendedLength})
    : isValid = true,
      errorMessage = null;

  const JoinPinValidationResult.error(String message)
    : isValid = false,
      errorMessage = message,
      isRecommendedLength = false;
}

/// 道場入室PIN・ロール別PINのハッシュ化および入力規約検証を担当する純粋関数群。
///
/// 平文PINをFirestoreやローカルストレージへ保存せず、道場IDをソルトに含めた
/// SHA-256ダイジェストのみを取り扱う。
class PinHasher {
  const PinHasher._();

  static const int minJoinPinLength = 4;
  static const int recommendedJoinPinLength = 6;
  static const int maxJoinPinLength = 20;

  static final RegExp _joinPinRegex = RegExp(r'^[A-Za-z0-9_\-]{4,20}$');
  static final RegExp _rolePinRegex = RegExp(r'^\d{4}$');

  /// 既存の道場作成直後デフォルトロールPIN（後方互換維持）
  static const Map<UserRole, String> defaultRolePins = {
    UserRole.admin: '9999',
    UserRole.operator: '2468',
    UserRole.recorder: '1357',
  };

  /// 道場IDを正規化（トリム＋小文字化）
  static String normalizeDojoId(String dojoId) => dojoId.trim().toLowerCase();

  /// 道場入室PIN（合言葉）の入力形式を検証する（案B: 4〜20文字の半角英数字・-・_）
  static JoinPinValidationResult validateJoinPinFormat(String rawPin) {
    final pin = rawPin.trim();
    if (pin.isEmpty) {
      return const JoinPinValidationResult.error('道場入室PIN（合言葉）を入力してください');
    }
    if (pin.length < minJoinPinLength) {
      return const JoinPinValidationResult.error('4文字以上で入力してください（6文字以上を推奨）');
    }
    if (pin.length > maxJoinPinLength) {
      return const JoinPinValidationResult.error('20文字以内で入力してください');
    }
    if (!_joinPinRegex.hasMatch(pin)) {
      return const JoinPinValidationResult.error(
        '半角英数字・ハイフン(- )・アンダーバー(_)のみ使用できます',
      );
    }
    return JoinPinValidationResult.ok(
      isRecommendedLength: pin.length >= recommendedJoinPinLength,
    );
  }

  /// ロールPINが4桁数字であるかを検証する
  static bool isValidRolePinFormat(String rawPin) {
    return _rolePinRegex.hasMatch(rawPin.trim());
  }

  /// 道場入室PINのソルト付きSHA-256ハッシュを生成する
  static String hashJoinPin(String dojoId, String rawPin) {
    final normalizedDojo = normalizeDojoId(dojoId);
    final payload = 'kendo_os:v2:join:$normalizedDojo:${rawPin.trim()}';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  /// ロール別PINのソルト付きSHA-256ハッシュを生成する
  static String hashRolePin(String dojoId, UserRole role, String rawPin) {
    final normalizedDojo = normalizeDojoId(dojoId);
    final payload =
        'kendo_os:v2:role:$normalizedDojo:${role.name}:${rawPin.trim()}';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  /// 指定された道場のデフォルトロールPINハッシュマップを生成する
  static Map<String, String> defaultRolePinHashes(String dojoId) {
    return {
      for (final entry in defaultRolePins.entries)
        entry.key.name: hashRolePin(dojoId, entry.key, entry.value),
    };
  }

  /// 指定ロールのデフォルトPIN文字列を返す（Viewerは空文字）
  static String defaultRolePin(UserRole role) {
    return defaultRolePins[role] ?? '';
  }

  /// 共有リンク用の推測困難な32文字ランダムトークンを生成する
  static String generateShareToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
