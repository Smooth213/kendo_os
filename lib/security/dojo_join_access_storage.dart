import 'dart:convert';
import 'package:kendo_os/security/pwa_storage_bridge.dart';

/// 道場入室PINの検証済みハッシュ証明を道場IDごとに安全にローカル保持するストレージ。
///
/// 平文PINは一切保持せず、再ログイン・ロール切替時に Firestore Rules へ
/// 提出するダイジェスト（submittedJoinPinHash）のみを管理する。
class DojoJoinAccessStorage {
  const DojoJoinAccessStorage._();

  static const String _storageKey = 'kendo_os_dojo_join_proofs_v2';

  static Map<String, String> _loadAll() {
    try {
      final raw = PwaStorage.getItem(_storageKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return {};
    }
  }

  static void saveJoinPinHash(String dojoId, String joinPinHash) {
    if (dojoId.isEmpty || joinPinHash.isEmpty) return;
    try {
      final map = _loadAll();
      map[dojoId] = joinPinHash;
      PwaStorage.setItem(_storageKey, jsonEncode(map));
    } catch (_) {}
  }

  static String? getJoinPinHash(String dojoId) {
    if (dojoId.isEmpty) return null;
    return _loadAll()[dojoId];
  }

  static bool hasJoinProof(String dojoId) {
    final hash = getJoinPinHash(dojoId);
    return hash != null && hash.isNotEmpty;
  }

  static void removeJoinPinHash(String dojoId) {
    if (dojoId.isEmpty) return;
    try {
      final map = _loadAll();
      map.remove(dojoId);
      PwaStorage.setItem(_storageKey, jsonEncode(map));
    } catch (_) {}
  }

  static void clearAll() {
    try {
      PwaStorage.removeItem(_storageKey);
    } catch (_) {}
  }
}
