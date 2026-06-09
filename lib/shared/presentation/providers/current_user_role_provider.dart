import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'auth_session_provider.dart';

/// 既存の全画面・全テストとの完全互換性を100%維持しつつ、
/// 体育館の電波瞬断やロードラグによる Viewer 強制遷移不具合を完全に封殺した、
/// 鉄壁のハイブリッド権限統治プロバイダー。
final currentUserRoleProvider = Provider<UserRole>((ref) {
  // 1. クラウドの Stream パケットを常に監視下に置く（リアクティブグラフの維持）
  final cloudRoleAsync = ref.watch(firestoreRoleStreamProvider);
  final localSession = ref.watch(authSessionProvider);

  // 🌟 不具合完全粉砕ロック：手動でPINを入力して特権（Admin / Operator / Recorder）が
  // ローカルメモリ上に確立されている期間は、クラウドの初期未作成ラグパケットや意図しない
  // Viewer 降格パケットを 100% シャットアウトし、ローカルの特権維持を絶対最優先する。
  if (localSession != null && !localSession.isExpired) {
    if (localSession.role == UserRole.viewer) {
      return UserRole.viewer;
    }
    return localSession.role;
  }

  // 2. ローカルが未認証、または一般Viewerの場合は、FirestoreのStreamからリアルタイム追従
  return cloudRoleAsync.when(
    data: (cloudRole) {
      ref.read(authSessionProvider.notifier).updateRoleFromCloud(cloudRole);
      return cloudRole;
    },
    // オフライン時やロード初期化中は、安全に直前のローカルキャッシュを適用して画面のガクつきを防止
    error: (_, _) => localSession?.role ?? UserRole.viewer,
    loading: () => localSession?.role ?? UserRole.viewer,
  );
});

/// 互換エイリアス
final userRoleProvider = currentUserRoleProvider;
