import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/security/dojo_security_repository.dart';
import 'package:kendo_os/security/pin_hasher.dart';
import 'package:kendo_os/security/pin_vault_cipher.dart';
import 'package:kendo_os/security/viewer_share_models.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';

final dojoOwnerRecoveryRepositoryProvider =
    Provider<DojoOwnerRecoveryRepository?>((ref) {
      final firestore = ref.watch(dojoSecurityFirestoreProvider);
      if (firestore == null) return null;
      return DojoOwnerRecoveryRepository(firestore);
    });

/// 道場ごとの代表者Googleアカウント（最大5名）管理および
/// PIN忘れ時の本人確認・PIN初期化/再設定を担当するリポジトリ。
class DojoOwnerRecoveryRepository {
  final FirebaseFirestore _firestore;

  DojoOwnerRecoveryRepository(this._firestore);

  DocumentReference<Map<String, dynamic>> _orgDoc(String dojoId) =>
      _firestore.collection('organizations').doc(dojoId);

  DocumentReference<Map<String, dynamic>> _securityDoc(String dojoId) =>
      _orgDoc(dojoId).collection('private').doc('security');

  DocumentReference<Map<String, dynamic>> _adminVaultDoc(String dojoId) =>
      _orgDoc(dojoId).collection('private').doc('admin_vault');

  DocumentReference<Map<String, dynamic>> _ownersDoc(String dojoId) =>
      _orgDoc(dojoId).collection('private').doc('owners');

  DocumentReference<Map<String, dynamic>> _memberDoc(
    String dojoId,
    String uid,
  ) => _orgDoc(dojoId).collection('members').doc(uid);

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static bool isValidEmail(String raw) {
    final email = normalizeEmail(raw);
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  /// 登録済み代表者Googleアカウント一覧を取得する
  Future<List<DojoOwnerAccount>> fetchDojoOwners(String dojoId) async {
    try {
      final doc = await _ownersDoc(dojoId).get().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('fetch timeout'),
      );
      if (!doc.exists) return const [];
      return _parseOwnersData(doc.data());
    } catch (_) {
      return const [];
    }
  }

  List<DojoOwnerAccount> _parseOwnersData(Map<String, dynamic>? data) {
    if (data == null) return const [];
    final rawEmails = data['ownerEmails'];
    if (rawEmails is! List) return const [];
    final rawMeta = data['ownersMeta'];
    final metaMap = rawMeta is Map ? rawMeta : const <String, dynamic>{};
    return rawEmails
        .map((e) => normalizeEmail(e.toString()))
        .where((e) => e.isNotEmpty)
        .map((email) => DojoOwnerAccount.fromMeta(email, metaMap[email]))
        .toList();
  }

  /// 代表者Googleアカウント一覧（最大5名）を更新する
  Future<({bool success, String? errorMessage})> updateDojoOwners({
    required String dojoId,
    required List<DojoOwnerAccount> owners,
    String? currentAdminPin,
    required String uid,
  }) async {
    final deduped = <String, DojoOwnerAccount>{};
    for (final account in owners) {
      final normalized = normalizeEmail(account.email);
      if (normalized.isEmpty) continue;
      if (!isValidEmail(normalized)) {
        return (
          success: false,
          errorMessage: '有効なメールアドレスを入力してください: ${account.email}',
        );
      }
      deduped.putIfAbsent(
        normalized,
        () => DojoOwnerAccount(
          email: normalized,
          displayName: account.displayName,
          addedBy: account.addedBy ?? uid,
        ),
      );
    }

    if (deduped.length > maxDojoOwnerAccounts) {
      return (
        success: false,
        errorMessage: '代表者Googleアカウントは最大$maxDojoOwnerAccounts名まで登録できます',
      );
    }

    final payload = <String, dynamic>{
      'ownerEmails': deduped.keys.toList(),
      'ownersMeta': {
        for (final entry in deduped.entries) entry.key: entry.value.toMetaMap(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    };

    if (currentAdminPin != null && currentAdminPin.trim().isNotEmpty) {
      payload['submittedCurrentAdminPinHash'] = PinHasher.hashRolePin(
        dojoId,
        UserRole.admin,
        currentAdminPin,
      );
    }

    try {
      await _ownersDoc(dojoId)
          .set(payload)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw TimeoutException('サーバー接続タイムアウト'),
          );
      return (success: true, errorMessage: null);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return (
          success: false,
          errorMessage: '代表者アカウントの更新権限がありません（Admin PINまたは登録済み代表者ログインが必要です）',
        );
      }
      return (
        success: false,
        errorMessage: '代表者アカウントの更新に失敗しました: ${e.message ?? e.code}',
      );
    } on TimeoutException {
      return (success: false, errorMessage: '代表者の更新がタイムアウトしました。通信環境をご確認ください。');
    } catch (e) {
      return (success: false, errorMessage: '代表者アカウントの更新エラー: $e');
    }
  }

  /// サインイン済みGoogleアカウントが道場の登録済み代表者であるか検証する
  Future<({bool isOwner, List<DojoOwnerAccount> owners})>
  verifyOwnerGoogleAccess({
    required String dojoId,
    required String email,
  }) async {
    final normalized = normalizeEmail(email);
    if (normalized.isEmpty) {
      return (isOwner: false, owners: const <DojoOwnerAccount>[]);
    }

    try {
      final doc = await _ownersDoc(dojoId).get();
      if (!doc.exists) {
        return (isOwner: false, owners: const <DojoOwnerAccount>[]);
      }
      final owners = _parseOwnersData(doc.data());
      final matched = owners.any((o) => o.normalizedEmail == normalized);
      return (isOwner: matched, owners: owners);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return (isOwner: false, owners: const <DojoOwnerAccount>[]);
      }
      rethrow;
    }
  }

  /// 登録済み代表者Googleアカウントによる本人確認後、PINを初期化または再設定する
  Future<
    ({
      bool success,
      String? newJoinPinHash,
      String? effectiveAdminPin,
      String? errorMessage,
    })
  >
  resetPinsByVerifiedOwner({
    required String dojoId,
    required String uid,
    String? existingJoinPinHash,
    String? newJoinPin,
    bool resetRolePinsToDefault = false,
    String? newAdminPin,
    String? newOperatorPin,
    String? newRecorderPin,
    bool elevateToAdmin = false,
  }) async {
    final trimmedJoin = newJoinPin?.trim() ?? '';
    final trimmedAdmin = newAdminPin?.trim() ?? '';
    final trimmedOperator = newOperatorPin?.trim() ?? '';
    final trimmedRecorder = newRecorderPin?.trim() ?? '';

    if (trimmedJoin.isNotEmpty) {
      final check = PinHasher.validateJoinPinFormat(trimmedJoin);
      if (!check.isValid) {
        return (
          success: false,
          newJoinPinHash: null,
          effectiveAdminPin: null,
          errorMessage: check.errorMessage,
        );
      }
    }

    for (final entry in {
      'Admin': trimmedAdmin,
      'Operator': trimmedOperator,
      'Recorder': trimmedRecorder,
    }.entries) {
      if (entry.value.isNotEmpty &&
          !PinHasher.isValidRolePinFormat(entry.value)) {
        return (
          success: false,
          newJoinPinHash: null,
          effectiveAdminPin: null,
          errorMessage: '${entry.key} PINは4桁の数字で入力してください',
        );
      }
    }

    if (trimmedJoin.isEmpty &&
        !resetRolePinsToDefault &&
        trimmedAdmin.isEmpty &&
        trimmedOperator.isEmpty &&
        trimmedRecorder.isEmpty) {
      return (
        success: false,
        newJoinPinHash: null,
        effectiveAdminPin: null,
        errorMessage: '再設定または初期化するPINを指定してください',
      );
    }

    final securityUpdate = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    };

    String? updatedJoinPinHash;
    if (trimmedJoin.isNotEmpty) {
      updatedJoinPinHash = PinHasher.hashJoinPin(dojoId, trimmedJoin);
      securityUpdate['joinPinHash'] = updatedJoinPinHash;
    }

    String? effectiveAdminPin;
    String? effectiveOperatorPin;
    String? effectiveRecorderPin;

    if (resetRolePinsToDefault) {
      effectiveAdminPin = trimmedAdmin.isNotEmpty
          ? trimmedAdmin
          : PinHasher.defaultRolePin(UserRole.admin);
      effectiveOperatorPin = trimmedOperator.isNotEmpty
          ? trimmedOperator
          : PinHasher.defaultRolePin(UserRole.operator);
      effectiveRecorderPin = trimmedRecorder.isNotEmpty
          ? trimmedRecorder
          : PinHasher.defaultRolePin(UserRole.recorder);
      securityUpdate['rolePinHashes'] = {
        UserRole.admin.name: PinHasher.hashRolePin(
          dojoId,
          UserRole.admin,
          effectiveAdminPin,
        ),
        UserRole.operator.name: PinHasher.hashRolePin(
          dojoId,
          UserRole.operator,
          effectiveOperatorPin,
        ),
        UserRole.recorder.name: PinHasher.hashRolePin(
          dojoId,
          UserRole.recorder,
          effectiveRecorderPin,
        ),
      };
    } else {
      if (trimmedAdmin.isNotEmpty) {
        effectiveAdminPin = trimmedAdmin;
        securityUpdate['rolePinHashes.${UserRole.admin.name}'] =
            PinHasher.hashRolePin(dojoId, UserRole.admin, trimmedAdmin);
      }
      if (trimmedOperator.isNotEmpty) {
        effectiveOperatorPin = trimmedOperator;
        securityUpdate['rolePinHashes.${UserRole.operator.name}'] =
            PinHasher.hashRolePin(dojoId, UserRole.operator, trimmedOperator);
      }
      if (trimmedRecorder.isNotEmpty) {
        effectiveRecorderPin = trimmedRecorder;
        securityUpdate['rolePinHashes.${UserRole.recorder.name}'] =
            PinHasher.hashRolePin(dojoId, UserRole.recorder, trimmedRecorder);
      }
    }

    final resolvedJoinPinHash = updatedJoinPinHash ?? existingJoinPinHash;
    if (elevateToAdmin && effectiveAdminPin == null) {
      return (
        success: false,
        newJoinPinHash: null,
        effectiveAdminPin: null,
        errorMessage: 'Admin復帰には新しいAdmin PINまたは初期化指定が必要です',
      );
    }

    final vaultCiphertext =
        (resetRolePinsToDefault && effectiveAdminPin != null)
        ? PinVaultCipher.encrypt(
            dojoId: dojoId,
            adminPin: effectiveAdminPin,
            payload: DojoPinVaultPayload(
              joinPin: trimmedJoin,
              adminPin: effectiveAdminPin,
              operatorPin: effectiveOperatorPin ?? '',
              recorderPin: effectiveRecorderPin ?? '',
            ),
          )
        : '';

    final batch = _firestore.batch();
    batch.update(_securityDoc(dojoId), securityUpdate);
    batch.set(_adminVaultDoc(dojoId), {
      'ciphertext': vaultCiphertext,
      'version': 1,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    }, SetOptions(merge: true));
    batch.set(_orgDoc(dojoId), {
      'rolePinPromptCompleted': true,
    }, SetOptions(merge: true));

    if (resolvedJoinPinHash != null && resolvedJoinPinHash.isNotEmpty) {
      final memberPayload = <String, dynamic>{
        'role': elevateToAdmin ? UserRole.admin.name : UserRole.viewer.name,
        'accessScope': 'dojo',
        'submittedJoinPinHash': resolvedJoinPinHash,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (elevateToAdmin && effectiveAdminPin != null) {
        memberPayload['submittedRolePinHash'] = PinHasher.hashRolePin(
          dojoId,
          UserRole.admin,
          effectiveAdminPin,
        );
      }
      batch.set(
        _memberDoc(dojoId, uid),
        memberPayload,
        SetOptions(merge: true),
      );
    }

    try {
      await batch.commit();
      return (
        success: true,
        newJoinPinHash: updatedJoinPinHash,
        effectiveAdminPin: effectiveAdminPin,
        errorMessage: null,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return (
          success: false,
          newJoinPinHash: null,
          effectiveAdminPin: null,
          errorMessage: '代表者Googleアカウントの確認が取れなかったためリセットできませんでした',
        );
      }
      rethrow;
    }
  }
}
