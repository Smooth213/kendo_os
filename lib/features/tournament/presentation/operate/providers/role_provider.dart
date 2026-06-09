import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';

enum Role { admin, scorer, viewer, editor }

enum OperationMode { tournament, local }

extension RoleExt on Role {
  String get label {
    switch (this) {
      case Role.admin:
        return '管理者';
      case Role.scorer:
        return '記録係';
      case Role.viewer:
        return '閲覧のみ';
      case Role.editor:
        return '編集者';
    }
  }
}

extension ModeExt on OperationMode {
  String get label {
    switch (this) {
      case OperationMode.tournament:
        return '大会・錬成会'; // ★ 名称変更
      case OperationMode.local:
        return '道場'; // ★ 名称変更
    }
  }
}

// 現在のモード（一元管理）
final operationModeProvider = StateProvider<OperationMode>(
  (ref) => OperationMode.tournament,
);

// 端末の永続的な立場
final persistentRoleProvider = StateProvider<Role>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final saved = prefs.getString('persistent_role');
  return Role.values.firstWhere(
    (e) => e.name == saved,
    orElse: () => Role.scorer,
  );
});

// ★ 修正: temporaryRoleOverrideProvider の定義はグローバルステート汚染の温床となるため完全にパージしました。

// ==========================================
// ★ Phase 1-Step 6: Viewer完全隔離（Zero Trust）
// ==========================================
// 今の「有効な役割」を導き出す唯一の真実
final activeRoleProvider = Provider<Role>((ref) {
  // ★ 修正: Firebaseのログイン状態ではなく、アプリ独自の認証セッション(PINコード)を正とする
  final session = ref.watch(authSessionProvider);

  // 2. PIN認証セッションが確立していない場合は、無条件で viewer に強制固定する
  // これにより、URLを知っているだけの第三者が書き込み権限を得ることを防ぐ
  if (session == null) {
    return Role.viewer;
  }

  // 3. ログインしている場合は、PIN認証セッションの権限を正とする
  final mode = ref.watch(operationModeProvider);
  // ★ 修正: SharedPreferences への依存を排除し、PIN認証で得た確実なセッションのロールを使用
  // これにより、Webブラウザとネイティブアプリでの権限の不一致を完全に解消します。
  final base = session.role;

  if (mode == OperationMode.tournament) {
    // 【大会・錬成会モード】
    return base == UserRole.admin ? Role.admin : Role.scorer;
  } else {
    // 【道場モード】
    return base == UserRole.admin ? Role.editor : Role.viewer;
  }
});

// 5. 役割が変更されたら自動保存
final rolePersistProvider = Provider((ref) {
  ref.listen<Role>(persistentRoleProvider, (prev, next) {
    ref.read(sharedPreferencesProvider).setString('persistent_role', next.name);
  });
});
