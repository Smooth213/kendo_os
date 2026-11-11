import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/auth_provider.dart';
import 'package:kendo_os/security/dojo_join_access_storage.dart';
import 'package:kendo_os/security/pin_hasher.dart';
import 'package:kendo_os/shared/domain/entities/user_session.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/security/session_storage.dart';
import 'current_sync_context_provider.dart';

/// ログイン状態や、Firestoreから降ってくるリアルタイムの権限変更を
/// PWAのライフサイクルと完全直結して管理する心臓部Notifier。
class AuthSessionNotifier extends StateNotifier<UserSession?> {
  AuthSessionNotifier() : super(null) {
    // PWA起動時：ローカルストレージから直前の有効セッションを自動復元（リロード耐性）
    final savedSession = SessionStorage.load();
    if (savedSession != null && !savedSession.isExpired) {
      state = savedSession;
    }
  }

  /// 認証通過時、または道場ルーム参加時にクラウドと同期したセッションを確立する
  Future<void> establishSession(
    UserRole role,
    String dojoId, {
    String? joinPinHash,
    String? rolePinHash,
  }) async {
    final now = DateTime.now();
    late Duration duration;

    // 各ロール別の安全タイムアウトポリシーを厳格適用
    switch (role) {
      case UserRole.admin:
        duration = const Duration(minutes: 30); // 共用端末放置対策で短め
        break;
      case UserRole.operator:
      case UserRole.recorder:
        duration = const Duration(hours: 12); // 終日大会・錬成会運営用
        break;
      case UserRole.viewer:
        duration = const Duration(minutes: 30); // 一般観客用
        break;
    }

    final resolvedJoinPinHash = (joinPinHash != null && joinPinHash.isNotEmpty)
        ? joinPinHash
        : DojoJoinAccessStorage.getJoinPinHash(dojoId);

    if (resolvedJoinPinHash != null && resolvedJoinPinHash.isNotEmpty) {
      DojoJoinAccessStorage.saveJoinPinHash(dojoId, resolvedJoinPinHash);
    }

    final session = UserSession(
      role: role,
      loginAt: now,
      expiresAt: now.add(duration),
      dojoId: dojoId,
      verifiedJoinPinHash: resolvedJoinPinHash,
    );

    state = session;
    SessionStorage.save(session);

    // ★ セッション確立直後に、自身のUIDとRole（およびPINハッシュ証明）をFirestoreのmembersに自動登録
    try {
      if (Firebase.apps.isEmpty) return;
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint(
          '[Auth] Current user is null. Performing fallback anonymous sign-in...',
        );
        final creds = await FirebaseAuth.instance.signInAnonymously();
        user = creds.user;
      }
      if (user != null && dojoId.isNotEmpty) {
        final effectiveRolePinHash =
            rolePinHash ??
            (role == UserRole.viewer
                ? null
                : PinHasher.hashRolePin(
                    dojoId,
                    role,
                    PinHasher.defaultRolePin(role),
                  ));
        final payload = <String, dynamic>{
          'role': role.name,
          'accessScope': 'dojo',
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (resolvedJoinPinHash != null && resolvedJoinPinHash.isNotEmpty) {
          payload['submittedJoinPinHash'] = resolvedJoinPinHash;
        }
        if (effectiveRolePinHash != null && effectiveRolePinHash.isNotEmpty) {
          payload['submittedRolePinHash'] = effectiveRolePinHash;
        }
        await FirebaseFirestore.instance
            .collection('organizations')
            .doc(dojoId)
            .collection('members')
            .doc(user.uid)
            .set(payload, SetOptions(merge: true));
        debugPrint(
          '[Auth] Firestore members に UID(${user.uid}) の role(${role.name}) を自動登録しました',
        );
      }
    } catch (e) {
      debugPrint('[WARN] [Auth] members へのロール自動登録に失敗: $e');
    }
  }

  /// QR/URL共有リンク経由の「1大会限定 Viewer」セッションを確立する
  void establishShareSession({
    required String dojoId,
    required String tournamentId,
    required String shareToken,
  }) {
    final now = DateTime.now();
    final session = UserSession(
      role: UserRole.viewer,
      loginAt: now,
      expiresAt: now.add(const Duration(hours: 12)),
      dojoId: dojoId,
      shareToken: shareToken,
      sharedTournamentId: tournamentId,
    );
    state = session;
    SessionStorage.save(session);
  }

  /// Admin設定変更時に、新しい道場入室PINハッシュを現在のセッションへ反映する
  void updateJoinPinHash(String dojoId, String newJoinPinHash) {
    DojoJoinAccessStorage.saveJoinPinHash(dojoId, newJoinPinHash);
    if (state == null || state!.dojoId != dojoId) return;
    final updated = UserSession(
      role: state!.role,
      loginAt: state!.loginAt,
      expiresAt: state!.expiresAt,
      sessionVersion: state!.sessionVersion,
      dojoId: state!.dojoId,
      verifiedJoinPinHash: newJoinPinHash,
      shareToken: state!.shareToken,
      sharedTournamentId: state!.sharedTournamentId,
    );
    state = updated;
    SessionStorage.save(updated);
  }

  /// クラウド（Firestore）側からリアルタイムに権限剥奪や昇格が降ってきた場合の同期処理
  void updateRoleFromCloud(UserRole newRole) {
    if (state == null) return;
    if (state!.role == newRole) return; // 変更がなければスキップ

    final updatedSession = UserSession(
      role: newRole,
      loginAt: state!.loginAt,
      expiresAt: state!.expiresAt,
      sessionVersion: state!.sessionVersion,
      dojoId: state!.dojoId,
      verifiedJoinPinHash: state!.verifiedJoinPinHash,
      shareToken: state!.shareToken,
      sharedTournamentId: state!.sharedTournamentId,
    );
    state = updatedSession;
    SessionStorage.save(updatedSession);
  }

  /// セッションの完全消去（ログアウト・タイムアウト時）
  void logout() {
    state = null;
    SessionStorage.clear();
  }
}

/// セッションのインメモリ状態を管理するグローバルプロバイダー
final authSessionProvider =
    StateNotifierProvider<AuthSessionNotifier, UserSession?>((ref) {
      return AuthSessionNotifier();
    });

/// 🌟 STEP 3-2核心：Firestoreの組織内メンバー情報をStreamで常時リッスンし、
/// 本部で権限が切り替えられた瞬間に0秒で端末に反映させるプロバイダー。
final firestoreRoleStreamProvider = StreamProvider<UserRole>((ref) {
  final dojoId = ref.watch(currentDojoIdProvider);
  // 🔑 Firebase認証状態の変化（未ログイン→ログイン完了）もリアクティブに監視
  final authUser =
      ref.watch(authStateProvider).valueOrNull ??
      FirebaseAuth.instance.currentUser;

  // 匿名認証が未完了、未ログイン、または道場IDが未設定の場合は最安全な viewer 固定
  if (authUser == null || dojoId.isEmpty) {
    return Stream.value(UserRole.viewer);
  }

  // organizations/{dojoId}/members/{uid} をリアルタイム監視
  return FirebaseFirestore.instance
      .collection('organizations')
      .doc(dojoId)
      .collection('members')
      .doc(authUser.uid)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          return UserRole.viewer; // ドキュメントがなければ一般観客
        }
        final data = snapshot.data()!;
        final roleStr = data['role']?.toString() ?? 'viewer';
        return UserRole.values.firstWhere(
          (e) => e.name == roleStr,
          orElse: () => UserRole.viewer,
        );
      });
});
