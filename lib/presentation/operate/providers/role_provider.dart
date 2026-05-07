import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ★ 追加: ログイン状態の確認用
import 'settings_provider.dart';

enum Role { admin, scorer, viewer, editor }
enum OperationMode { tournament, local }

extension RoleExt on Role {
  String get label {
    switch (this) {
      case Role.admin: return '管理者';
      case Role.scorer: return '記録係';
      case Role.viewer: return '閲覧のみ';
      case Role.editor: return '編集者';
    }
  }
}

extension ModeExt on OperationMode {
  String get label {
    switch (this) {
      case OperationMode.tournament: return '大会・錬成会'; // ★ 名称変更
      case OperationMode.local: return '道場';              // ★ 名称変更
    }
  }
}

// 現在のモード（一元管理）
final operationModeProvider = StateProvider<OperationMode>((ref) => OperationMode.tournament);

// 端末の永続的な立場
final persistentRoleProvider = StateProvider<Role>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final saved = prefs.getString('persistent_role');
  return Role.values.firstWhere((e) => e.name == saved, orElse: () => Role.scorer);
});

// 3. URL等による「一時的な上書き（QRからの閲覧者など）」を管理（他画面の参照エラー防止のため維持）
final temporaryRoleOverrideProvider = StateProvider<Role?>((ref) => null);

// ==========================================
// ★ Phase 1-Step 6: Viewer完全隔離（Zero Trust）
// ==========================================
// 今の「有効な役割」を導き出す唯一の真実
final activeRoleProvider = Provider<Role>((ref) {
  // 1. まず「システムとしてのログイン状態」を確認
  final currentUser = FirebaseAuth.instance.currentUser;
  
  // 2. ログインしていない（ゲストユーザー）場合は、無条件で viewer に強制固定する
  // これにより、URLを知っているだけの第三者が書き込み権限を得ることを物理的に防ぐ
  if (currentUser == null) {
    return Role.viewer;
  }

  // 3. ログインしている場合は、これまでの設定やモードに従う
  final mode = ref.watch(operationModeProvider);
  final base = ref.watch(persistentRoleProvider);

  if (mode == OperationMode.tournament) {
    // 【大会・錬成会モード】
    return base == Role.admin ? Role.admin : Role.scorer;
  } else {
    // 【道場モード】
    return base == Role.admin ? Role.editor : Role.viewer;
  }
});

// 5. 役割が変更されたら自動保存
final rolePersistProvider = Provider((ref) {
  ref.listen<Role>(persistentRoleProvider, (prev, next) {
    ref.read(sharedPreferencesProvider).setString('persistent_role', next.name);
  });
});