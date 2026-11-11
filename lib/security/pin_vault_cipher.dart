import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:kendo_os/security/pin_hasher.dart';

/// Admin 本人確認後に復号して画面へ初期表示する道場PIN一式
class DojoPinVaultPayload {
  final String joinPin;
  final String adminPin;
  final String operatorPin;
  final String recorderPin;

  const DojoPinVaultPayload({
    required this.joinPin,
    required this.adminPin,
    required this.operatorPin,
    required this.recorderPin,
  });

  factory DojoPinVaultPayload.defaults({required String joinPin}) {
    return DojoPinVaultPayload(
      joinPin: joinPin,
      adminPin: '9999',
      operatorPin: '2468',
      recorderPin: '1357',
    );
  }

  Map<String, dynamic> toJson() => {
    'joinPin': joinPin,
    'adminPin': adminPin,
    'operatorPin': operatorPin,
    'recorderPin': recorderPin,
  };

  factory DojoPinVaultPayload.fromJson(Map<String, dynamic> json) {
    return DojoPinVaultPayload(
      joinPin: json['joinPin']?.toString() ?? '',
      adminPin: json['adminPin']?.toString() ?? '',
      operatorPin: json['operatorPin']?.toString() ?? '',
      recorderPin: json['recorderPin']?.toString() ?? '',
    );
  }
}

/// Admin PIN を鍵として道場入室PIN・全ロールPINを安全に暗号化／復号するユーティリティ。
///
/// SHA-256ベースの反復鍵導出＋HMAC-SHA256 CTRストリーム暗号＋Encrypt-then-MAC を用い、
/// Admin PINを知らない第三者や改ざんデータに対する復号を拒否する。
class PinVaultCipher {
  const PinVaultCipher._();

  static const String _versionPrefix = 'v1';
  static const int _saltBytes = 16;
  static const int _kdfRounds = 1000;

  static Uint8List _deriveKeyMaterial({
    required String dojoId,
    required String adminPin,
    required List<int> salt,
  }) {
    final normalizedDojo = PinHasher.normalizeDojoId(dojoId);
    final seed = utf8.encode(
      'kendo_os:vault:$_versionPrefix:$normalizedDojo:${adminPin.trim()}',
    );
    var block = Hmac(sha256, salt).convert(seed).bytes;
    for (int i = 1; i < _kdfRounds; i++) {
      block = sha256.convert([...block, ...salt]).bytes;
    }
    return Uint8List.fromList(block);
  }

  static List<int> _subKey(List<int> masterKey, int domainTag) {
    return Hmac(sha256, masterKey).convert([domainTag]).bytes;
  }

  static Uint8List _xorWithKeystream(List<int> input, List<int> encKey) {
    final output = Uint8List(input.length);
    int offset = 0;
    int counter = 0;
    while (offset < input.length) {
      final counterBytes = Uint8List(4)
        ..buffer.asByteData().setUint32(0, counter, Endian.big);
      final block = Hmac(sha256, encKey).convert(counterBytes).bytes;
      for (int i = 0; i < block.length && offset < input.length; i++) {
        output[offset] = input[offset] ^ block[i];
        offset++;
      }
      counter++;
    }
    return output;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Admin PIN を鍵として [payload] を暗号化し、自己完結型トークン文字列を返す
  static String encrypt({
    required String dojoId,
    required String adminPin,
    required DojoPinVaultPayload payload,
    Random? random,
  }) {
    final rng = random ?? Random.secure();
    final salt = List<int>.generate(_saltBytes, (_) => rng.nextInt(256));
    final masterKey = _deriveKeyMaterial(
      dojoId: dojoId,
      adminPin: adminPin,
      salt: salt,
    );
    final encKey = _subKey(masterKey, 0x01);
    final macKey = _subKey(masterKey, 0x02);

    final plainBytes = utf8.encode(jsonEncode(payload.toJson()));
    final cipherBytes = _xorWithKeystream(plainBytes, encKey);
    final mac = Hmac(sha256, macKey).convert([...salt, ...cipherBytes]).bytes;

    return [
      _versionPrefix,
      base64UrlEncode(salt),
      base64UrlEncode(cipherBytes),
      base64UrlEncode(mac),
    ].join(':');
  }

  /// 暗号化トークンを検証・復号する。PIN不一致・道場不一致・改ざん時は null を返す。
  static DojoPinVaultPayload? decrypt({
    required String dojoId,
    required String adminPin,
    required String encryptedToken,
  }) {
    final parts = encryptedToken.trim().split(':');
    if (parts.length != 4 || parts[0] != _versionPrefix) {
      return null;
    }

    try {
      final salt = base64Url.decode(parts[1]);
      final cipherBytes = base64Url.decode(parts[2]);
      final actualMac = base64Url.decode(parts[3]);
      if (salt.length != _saltBytes) return null;

      final masterKey = _deriveKeyMaterial(
        dojoId: dojoId,
        adminPin: adminPin,
        salt: salt,
      );
      final encKey = _subKey(masterKey, 0x01);
      final macKey = _subKey(masterKey, 0x02);
      final expectedMac = Hmac(
        sha256,
        macKey,
      ).convert([...salt, ...cipherBytes]).bytes;

      if (!_constantTimeEquals(actualMac, expectedMac)) {
        return null;
      }

      final plainBytes = _xorWithKeystream(cipherBytes, encKey);
      final decoded = jsonDecode(utf8.decode(plainBytes));
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return DojoPinVaultPayload.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}
