import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// ★ 今の「有効な役割」を導き出す唯一の真実
final activeRoleProvider = Provider<Role>((ref) {
  final mode = ref.watch(operationModeProvider);
  final base = ref.watch(persistentRoleProvider);

  if (mode == OperationMode.tournament) {
    // 【大会・錬成会モード】
    return base == Role.admin ? Role.admin : Role.scorer;
  } else {
    // 【道場モード】
    // 管理者は「編集者」に、記録係は「閲覧のみ」に自動で切り替わる
    return base == Role.admin ? Role.editor : Role.viewer;
  }
});

// 5. 役割が変更されたら自動保存
final rolePersistProvider = Provider((ref) {
  ref.listen<Role>(persistentRoleProvider, (prev, next) {
    ref.read(sharedPreferencesProvider).setString('persistent_role', next.name);
  });
});