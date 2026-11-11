import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/security/pin_hasher.dart';
import 'package:kendo_os/security/pin_vault_cipher.dart';
import 'package:kendo_os/security/viewer_share_models.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';

/// テスト時に FakeFirebaseFirestore へ差し替え可能なセキュリティリポジトリプロバイダー
final dojoSecurityFirestoreProvider = Provider<FirebaseFirestore?>((ref) {
  try {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance;
  } catch (_) {
    return null;
  }
});

final dojoSecurityRepositoryProvider = Provider<DojoSecurityRepository?>((ref) {
  final firestore = ref.watch(dojoSecurityFirestoreProvider);
  if (firestore == null) return null;
  return DojoSecurityRepository(firestore);
});

/// 道場ごとの入室PIN・ロール別PIN・1大会限定観戦共有トークンの
/// Firestore 永続化およびゼロトラスト検証を担当するリポジトリ。
class DojoSecurityRepository {
  final FirebaseFirestore _firestore;

  DojoSecurityRepository(this._firestore);

  DocumentReference<Map<String, dynamic>> _orgDoc(String dojoId) =>
      _firestore.collection('organizations').doc(dojoId);

  DocumentReference<Map<String, dynamic>> _securityDoc(String dojoId) =>
      _orgDoc(dojoId).collection('private').doc('security');

  DocumentReference<Map<String, dynamic>> _adminVaultDoc(String dojoId) =>
      _orgDoc(dojoId).collection('private').doc('admin_vault');

  DocumentReference<Map<String, dynamic>> _memberDoc(
    String dojoId,
    String uid,
  ) => _orgDoc(dojoId).collection('members').doc(uid);

  /// 指定された道場ルームの存在有無およびPIN保護状態を判定する
  Future<DojoJoinStatus> inspectRoomStatus(String dojoId) async {
    final doc = await _orgDoc(dojoId).get();
    if (!doc.exists) {
      return DojoJoinStatus.notFound;
    }
    final data = doc.data();
    if (data != null && data['hasJoinPin'] == true) {
      return DojoJoinStatus.requiresPin;
    }
    return DojoJoinStatus.legacyUnsetPin;
  }

  /// 新規道場ルームを「道場入室PIN」と初期ロールPIN付きで創設し、自身を道場メンバー登録する
  Future<String> createDojoWithPin({
    required String dojoId,
    required String joinPin,
    required String uid,
  }) async {
    final joinPinHash = PinHasher.hashJoinPin(dojoId, joinPin);
    final rolePinHashes = PinHasher.defaultRolePinHashes(dojoId);

    final batch = _firestore.batch();
    batch.set(_orgDoc(dojoId), {
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
      'hasJoinPin': true,
      'rolePinPromptCompleted': false,
      'securityVersion': 2,
    });
    batch.set(_securityDoc(dojoId), {
      'joinPinHash': joinPinHash,
      'rolePinHashes': rolePinHashes,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    });
    batch.set(_adminVaultDoc(dojoId), {
      'ciphertext': PinVaultCipher.encrypt(
        dojoId: dojoId,
        adminPin: PinHasher.defaultRolePin(UserRole.admin),
        payload: DojoPinVaultPayload.defaults(joinPin: joinPin.trim()),
      ),
      'version': 1,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    });
    batch.set(_memberDoc(dojoId, uid), {
      'role': UserRole.viewer.name,
      'accessScope': 'dojo',
      'submittedJoinPinHash': joinPinHash,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
    return joinPinHash;
  }

  /// PIN未設定の既存テスト道場に対して初回入室PINを設定し、自身を道場メンバー登録する
  Future<String> initializeLegacyDojoPin({
    required String dojoId,
    required String joinPin,
    required String uid,
  }) async {
    final joinPinHash = PinHasher.hashJoinPin(dojoId, joinPin);
    final rolePinHashes = PinHasher.defaultRolePinHashes(dojoId);

    final batch = _firestore.batch();
    batch.set(_orgDoc(dojoId), {
      'hasJoinPin': true,
      'rolePinPromptCompleted': false,
      'securityVersion': 2,
      'pinInitializedBy': uid,
      'pinInitializedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(_securityDoc(dojoId), {
      'joinPinHash': joinPinHash,
      'rolePinHashes': rolePinHashes,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    });
    batch.set(_adminVaultDoc(dojoId), {
      'ciphertext': PinVaultCipher.encrypt(
        dojoId: dojoId,
        adminPin: PinHasher.defaultRolePin(UserRole.admin),
        payload: DojoPinVaultPayload.defaults(joinPin: joinPin.trim()),
      ),
      'version': 1,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    });
    batch.set(_memberDoc(dojoId, uid), {
      'role': UserRole.viewer.name,
      'accessScope': 'dojo',
      'submittedJoinPinHash': joinPinHash,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
    return joinPinHash;
  }

  /// 既存の道場ルームへ入室PINを用いて参加する。認証成功時は joinPinHash、失敗時は null を返す。
  Future<String?> joinExistingDojoWithPin({
    required String dojoId,
    required String joinPin,
    required String uid,
  }) async {
    final joinPinHash = PinHasher.hashJoinPin(dojoId, joinPin);

    // テスト環境（FakeFirestore）用のローカル照合。本番Rulesでは直接readが拒否されるため無視する。
    try {
      final secDoc = await _securityDoc(dojoId).get();
      if (secDoc.exists) {
        final storedHash = secDoc.data()?['joinPinHash']?.toString();
        if (storedHash != null && storedHash != joinPinHash) {
          return null;
        }
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }

    try {
      await _memberDoc(dojoId, uid).set({
        'role': UserRole.viewer.name,
        'accessScope': 'dojo',
        'submittedJoinPinHash': joinPinHash,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return joinPinHash;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return null;
      }
      rethrow;
    }
  }

  /// 道場ごとのロール別PINを検証し、権限付きメンバー状態を Firestore に反映する
  Future<bool> authenticateRoleWithPin({
    required String dojoId,
    required UserRole role,
    required String rolePin,
    required String? joinPinHash,
    required String uid,
  }) async {
    if (role == UserRole.viewer) return true;
    final rolePinHash = PinHasher.hashRolePin(dojoId, role, rolePin);

    // FakeFirestore等（直接read可能環境）での照合
    try {
      final secDoc = await _securityDoc(dojoId).get();
      if (secDoc.exists) {
        final roleMap = secDoc.data()?['rolePinHashes'];
        if (roleMap is Map) {
          final expected = roleMap[role.name]?.toString();
          if (expected != null && expected != rolePinHash) {
            return false;
          }
        }
      } else {
        // private/security 未作成時は従来の初期値と照合
        if (PinHasher.defaultRolePin(role) != rolePin.trim()) {
          return false;
        }
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }

    try {
      final payload = <String, dynamic>{
        'role': role.name,
        'accessScope': 'dojo',
        'submittedRolePinHash': rolePinHash,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (joinPinHash != null && joinPinHash.isNotEmpty) {
        payload['submittedJoinPinHash'] = joinPinHash;
      }
      await _memberDoc(dojoId, uid).set(payload, SetOptions(merge: true));
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return false;
      }
      rethrow;
    }
  }

  /// 初回Adminログイン時にロールPIN変更案内ダイアログを表示すべきか判定する
  Future<bool> needsInitialAdminRolePinPrompt(String dojoId) async {
    try {
      final doc = await _orgDoc(dojoId).get();
      if (!doc.exists) return false;
      final data = doc.data();
      return data != null &&
          data['hasJoinPin'] == true &&
          data['rolePinPromptCompleted'] != true;
    } catch (e) {
      debugPrint('[DojoSecurity] 初回PINプロンプト判定エラー: $e');
      return false;
    }
  }

  /// 初回AdminロールPIN変更案内を完了済み（スキップまたは変更完了）として記録する
  Future<void> markRolePinPromptCompleted(String dojoId) async {
    await _orgDoc(
      dojoId,
    ).set({'rolePinPromptCompleted': true}, SetOptions(merge: true));
  }

  /// 現在の Admin PIN を照合し、暗号化ボールトから設定済み現在PIN一式を復号して返す
  Future<AdminVaultUnlockResult> verifyAdminAndUnlockVault({
    required String dojoId,
    required String currentAdminPin,
    required String? joinPinHash,
    required String uid,
  }) async {
    final ok = await authenticateRoleWithPin(
      dojoId: dojoId,
      role: UserRole.admin,
      rolePin: currentAdminPin,
      joinPinHash: joinPinHash,
      uid: uid,
    );
    if (!ok) {
      return const AdminVaultUnlockResult(
        status: AdminVaultUnlockStatus.invalidAdminPin,
        errorMessage: '現在の管理者(Admin) PINが一致しません',
      );
    }

    try {
      final vaultDoc = await _adminVaultDoc(dojoId).get();
      final token = vaultDoc.data()?['ciphertext']?.toString() ?? '';
      if (vaultDoc.exists && token.isNotEmpty) {
        final decrypted = PinVaultCipher.decrypt(
          dojoId: dojoId,
          adminPin: currentAdminPin,
          encryptedToken: token,
        );
        if (decrypted != null) {
          return AdminVaultUnlockResult(
            status: AdminVaultUnlockStatus.unlocked,
            payload: decrypted,
          );
        }
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }

    final trimmedAdmin = currentAdminPin.trim();
    if (trimmedAdmin == PinHasher.defaultRolePin(UserRole.admin)) {
      return const AdminVaultUnlockResult(
        status: AdminVaultUnlockStatus.legacyUnmigrated,
        payload: DojoPinVaultPayload(
          joinPin: '',
          adminPin: '9999',
          operatorPin: '2468',
          recorderPin: '1357',
        ),
      );
    }

    return AdminVaultUnlockResult(
      status: AdminVaultUnlockStatus.legacyUnmigrated,
      payload: DojoPinVaultPayload(
        joinPin: '',
        adminPin: trimmedAdmin,
        operatorPin: '',
        recorderPin: '',
      ),
    );
  }

  /// Admin権限で道場入室PINおよび各ロールPINを更新する。
  /// 成功時は更新後の joinPinHash（未変更時は null）を返す。現在のAdmin PINが不正なら結果を返す。
  Future<({bool success, String? newJoinPinHash, String? errorMessage})>
  updateDojoSecurityPins({
    required String dojoId,
    required String currentAdminPin,
    String? newJoinPin,
    Map<UserRole, String>? newRolePins,
    DojoPinVaultPayload? currentVault,
    required String uid,
  }) async {
    final currentAdminHash = PinHasher.hashRolePin(
      dojoId,
      UserRole.admin,
      currentAdminPin,
    );

    // テスト環境用ローカル照合
    try {
      final secDoc = await _securityDoc(dojoId).get();
      if (secDoc.exists) {
        final roleMap = secDoc.data()?['rolePinHashes'];
        final expectedAdminHash = (roleMap is Map)
            ? roleMap[UserRole.admin.name]?.toString()
            : null;
        if (expectedAdminHash != null &&
            expectedAdminHash != currentAdminHash) {
          return (
            success: false,
            newJoinPinHash: null,
            errorMessage: '現在の管理者(Admin) PINが一致しません',
          );
        }
      } else if (PinHasher.defaultRolePin(UserRole.admin) !=
          currentAdminPin.trim()) {
        return (
          success: false,
          newJoinPinHash: null,
          errorMessage: '現在の管理者(Admin) PINが一致しません',
        );
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }

    var resolvedVault = currentVault;
    if (resolvedVault == null) {
      try {
        final vaultDoc = await _adminVaultDoc(dojoId).get();
        final token = vaultDoc.data()?['ciphertext']?.toString() ?? '';
        if (vaultDoc.exists && token.isNotEmpty) {
          resolvedVault = PinVaultCipher.decrypt(
            dojoId: dojoId,
            adminPin: currentAdminPin,
            encryptedToken: token,
          );
        }
      } catch (_) {}
    }

    String? updatedJoinPinHash;
    final securityUpdate = <String, dynamic>{
      'submittedCurrentAdminPinHash': currentAdminHash,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    };

    if (newJoinPin != null && newJoinPin.trim().isNotEmpty) {
      updatedJoinPinHash = PinHasher.hashJoinPin(dojoId, newJoinPin);
      securityUpdate['joinPinHash'] = updatedJoinPinHash;
    }

    if (newRolePins != null && newRolePins.isNotEmpty) {
      for (final entry in newRolePins.entries) {
        if (entry.key == UserRole.viewer) continue;
        final trimmed = entry.value.trim();
        if (trimmed.isEmpty) continue;
        securityUpdate['rolePinHashes.${entry.key.name}'] =
            PinHasher.hashRolePin(dojoId, entry.key, trimmed);
      }
    }

    final nextAdminPin =
        (newRolePins?[UserRole.admin]?.trim().isNotEmpty ?? false)
        ? newRolePins![UserRole.admin]!.trim()
        : currentAdminPin.trim();
    final nextJoinPin = (newJoinPin != null && newJoinPin.trim().isNotEmpty)
        ? newJoinPin.trim()
        : (resolvedVault?.joinPin ?? '');
    final nextOperatorPin =
        (newRolePins?[UserRole.operator]?.trim().isNotEmpty ?? false)
        ? newRolePins![UserRole.operator]!.trim()
        : (resolvedVault?.operatorPin ?? '');
    final nextRecorderPin =
        (newRolePins?[UserRole.recorder]?.trim().isNotEmpty ?? false)
        ? newRolePins![UserRole.recorder]!.trim()
        : (resolvedVault?.recorderPin ?? '');

    final nextVaultCiphertext = PinVaultCipher.encrypt(
      dojoId: dojoId,
      adminPin: nextAdminPin,
      payload: DojoPinVaultPayload(
        joinPin: nextJoinPin,
        adminPin: nextAdminPin,
        operatorPin: nextOperatorPin,
        recorderPin: nextRecorderPin,
      ),
    );

    try {
      final batch = _firestore.batch();
      batch.update(_securityDoc(dojoId), securityUpdate);
      batch.set(_adminVaultDoc(dojoId), {
        'ciphertext': nextVaultCiphertext,
        'version': 1,
        'submittedCurrentAdminPinHash': currentAdminHash,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      }, SetOptions(merge: true));
      batch.set(_orgDoc(dojoId), {
        'rolePinPromptCompleted': true,
      }, SetOptions(merge: true));
      await batch.commit();

      return (
        success: true,
        newJoinPinHash: updatedJoinPinHash,
        errorMessage: null,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return (
          success: false,
          newJoinPinHash: null,
          errorMessage: '現在の管理者(Admin) PINが一致しないか、変更権限がありません',
        );
      }
      rethrow;
    }
  }
}
