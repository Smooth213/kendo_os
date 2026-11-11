import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/security/pin_hasher.dart';
import 'package:kendo_os/security/viewer_share_models.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';

/// テスト時に FakeFirebaseFirestore へ差し替え可能な観戦共有リポジトリプロバイダー
final viewerShareFirestoreProvider = Provider<FirebaseFirestore?>((ref) {
  try {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance;
  } catch (_) {
    return null;
  }
});

final viewerShareRepositoryProvider = Provider<ViewerShareRepository?>((ref) {
  final firestore = ref.watch(viewerShareFirestoreProvider);
  if (firestore == null) return null;
  return ViewerShareRepository(firestore);
});

/// 1大会限定 観戦共有リンク（24時間 / 7日間 / 無期限 / 停止）の
/// 発行・期限更新・検証を担当するリポジトリ。
class ViewerShareRepository {
  final FirebaseFirestore _firestore;

  ViewerShareRepository(this._firestore);

  DocumentReference<Map<String, dynamic>> _orgDoc(String dojoId) =>
      _firestore.collection('organizations').doc(dojoId);

  DocumentReference<Map<String, dynamic>> _memberDoc(
    String dojoId,
    String uid,
  ) => _orgDoc(dojoId).collection('members').doc(uid);

  DocumentReference<Map<String, dynamic>> _shareLinkDoc(
    String dojoId,
    String token,
  ) => _orgDoc(dojoId).collection('share_links').doc(token);

  DocumentReference<Map<String, dynamic>> _shareMetaDoc(
    String dojoId,
    String tournamentId,
  ) => _orgDoc(dojoId).collection('share_meta').doc(tournamentId);

  /// 対象大会の現在の共有リンクメタ情報を取得する
  Future<ViewerShareLinkInfo?> getTournamentShareMeta({
    required String dojoId,
    required String tournamentId,
  }) async {
    try {
      final metaSnap = await _shareMetaDoc(dojoId, tournamentId).get();
      if (!metaSnap.exists || metaSnap.data() == null) return null;
      final data = metaSnap.data()!;
      final token = data['activeToken']?.toString() ?? '';
      if (token.isEmpty) return null;

      return _parseShareInfo(
        token: token,
        dojoId: dojoId,
        tournamentId: tournamentId,
        data: data,
      );
    } catch (e) {
      debugPrint('[ViewerShare] 共有メタ取得エラー: $e');
      return null;
    }
  }

  /// 1大会限定 観戦共有リンクを発行または有効期限プリセット更新する
  Future<ViewerShareLinkInfo> saveTournamentShareLink({
    required String dojoId,
    required String tournamentId,
    required ViewerShareExpiryPreset preset,
    String? existingToken,
    required String uid,
    DateTime? now,
  }) async {
    final baseNow = now ?? DateTime.now();
    final token = (existingToken != null && existingToken.isNotEmpty)
        ? existingToken
        : PinHasher.generateShareToken();
    final expiresAt = preset.computeExpiresAt(now: baseNow);
    final isRevoked = preset == ViewerShareExpiryPreset.revoked;

    final linkPayload = <String, dynamic>{
      'token': token,
      'tournamentId': tournamentId,
      'preset': preset.key,
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt),
      'isRevoked': isRevoked,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    };

    final metaPayload = <String, dynamic>{
      'activeToken': token,
      'tournamentId': tournamentId,
      'preset': preset.key,
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt),
      'isRevoked': isRevoked,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    };

    final batch = _firestore.batch();
    batch.set(_shareLinkDoc(dojoId, token), linkPayload);
    batch.set(_shareMetaDoc(dojoId, tournamentId), metaPayload);
    await batch.commit();

    return ViewerShareLinkInfo(
      token: token,
      dojoId: dojoId,
      tournamentId: tournamentId,
      preset: preset,
      expiresAt: expiresAt,
      isRevoked: isRevoked,
    );
  }

  /// 既存の共有トークンを返し、未発行なら初期値（7日間）で新規発行する
  Future<ViewerShareLinkInfo> getOrCreateDefaultShareLink({
    required String dojoId,
    required String tournamentId,
    required String uid,
  }) async {
    final existing = await getTournamentShareMeta(
      dojoId: dojoId,
      tournamentId: tournamentId,
    );
    if (existing != null) return existing;
    return saveTournamentShareLink(
      dojoId: dojoId,
      tournamentId: tournamentId,
      preset: ViewerShareExpiryPreset.days7,
      uid: uid,
    );
  }

  /// QR/URLから渡された共有トークンを検証し、有効であれば対象1大会限定のViewerメンバー登録を行う
  Future<ViewerShareVerificationResult> verifyAndActivateShareLink({
    required String dojoId,
    required String tournamentId,
    required String token,
    required String uid,
    DateTime? now,
  }) async {
    if (dojoId.isEmpty || tournamentId.isEmpty || token.isEmpty) {
      return const ViewerShareVerificationResult(
        status: ViewerShareAccessStatus.invalid,
      );
    }

    try {
      final snap = await _shareLinkDoc(dojoId, token).get();
      if (!snap.exists || snap.data() == null) {
        return const ViewerShareVerificationResult(
          status: ViewerShareAccessStatus.invalid,
        );
      }

      final data = snap.data()!;
      final info = _parseShareInfo(
        token: token,
        dojoId: dojoId,
        tournamentId: data['tournamentId']?.toString() ?? '',
        data: data,
      );

      if (info.tournamentId != tournamentId) {
        return const ViewerShareVerificationResult(
          status: ViewerShareAccessStatus.invalid,
        );
      }
      if (info.isRevoked || info.preset == ViewerShareExpiryPreset.revoked) {
        return ViewerShareVerificationResult(
          status: ViewerShareAccessStatus.revoked,
          linkInfo: info,
        );
      }

      final checkTime = now ?? DateTime.now();
      if (!info.isActiveAt(checkTime)) {
        return ViewerShareVerificationResult(
          status: ViewerShareAccessStatus.expired,
          linkInfo: info,
        );
      }

      await _memberDoc(dojoId, uid).set({
        'role': UserRole.viewer.name,
        'accessScope': 'share_link',
        'shareToken': token,
        'sharedTournamentId': tournamentId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return ViewerShareVerificationResult(
        status: ViewerShareAccessStatus.valid,
        linkInfo: info,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const ViewerShareVerificationResult(
          status: ViewerShareAccessStatus.expired,
        );
      }
      return const ViewerShareVerificationResult(
        status: ViewerShareAccessStatus.offlineOrUnavailable,
      );
    } catch (_) {
      return const ViewerShareVerificationResult(
        status: ViewerShareAccessStatus.offlineOrUnavailable,
      );
    }
  }

  ViewerShareLinkInfo _parseShareInfo({
    required String token,
    required String dojoId,
    required String tournamentId,
    required Map<String, dynamic> data,
  }) {
    final rawExpires = data['expiresAt'];
    DateTime? expiresAt;
    if (rawExpires is Timestamp) {
      expiresAt = rawExpires.toDate();
    } else if (rawExpires is DateTime) {
      expiresAt = rawExpires;
    } else if (rawExpires is String) {
      expiresAt = DateTime.tryParse(rawExpires);
    }

    return ViewerShareLinkInfo(
      token: token,
      dojoId: dojoId,
      tournamentId: tournamentId,
      preset: ViewerShareExpiryPreset.fromKey(data['preset']?.toString()),
      expiresAt: expiresAt,
      isRevoked: data['isRevoked'] == true,
    );
  }
}
