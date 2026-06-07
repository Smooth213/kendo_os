import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  void establishSession(UserRole role, String dojoId) {
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

    final session = UserSession(
      role: role,
      loginAt: now,
      expiresAt: now.add(duration),
    );

    state = session;
    SessionStorage.save(session);
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
  final currentUser = FirebaseAuth.instance.currentUser;

  // 匿名認証が未完了、または未ログインの場合は最安全な viewer 固定
  if (currentUser == null) {
    return Stream.value(UserRole.viewer);
  }

  // organizations/{dojoId}/members/{uid} をリアルタイム監視
  return FirebaseFirestore.instance
      .collection('organizations')
      .doc(dojoId)
      .collection('members')
      .doc(currentUser.uid)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          return UserRole.viewer; // ドキュメントがなければ一般観客
        }
        final data = snapshot.data()!;
        final roleStr = data['role'] as String? ?? 'viewer';
        return UserRole.values.firstWhere(
          (e) => e.name == roleStr,
          orElse: () => UserRole.viewer,
        );
      });
});
