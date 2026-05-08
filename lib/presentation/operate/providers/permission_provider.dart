import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'role_provider.dart';
import 'settings_provider.dart'; // ★ 追加: セキュリティレベルを監視するため

class AppPermissions {
  final bool canManageTournament;
  final bool canCreateMatch;
  final bool isReadOnly;
  final bool canChangeSettings; // ★ Phase 8: 設定変更のロック権限
  final bool canDeleteData;     // ★ Phase 8: データ削除（破壊的変更）のロック権限

  const AppPermissions({
    required this.canManageTournament,
    required this.canCreateMatch,
    required this.isReadOnly,
    required this.canChangeSettings,
    required this.canDeleteData,
  });
}

final permissionProvider = Provider<AppPermissions>((ref) {
  final role = ref.watch(activeRoleProvider);
  final securityLevel = ref.watch(settingsProvider.select((s) => s.securityLevel));

  // セキュリティレベルが「Lv.1(自由)」の時だけ、記録係でも柔軟な操作を許可する
  final bool isLenient = securityLevel == 1;

  switch (role) {
    case Role.admin:
      // 管理者は常に全権限を持つ（無敵）
      return const AppPermissions(
        canManageTournament: true, 
        canCreateMatch: true, 
        isReadOnly: false,
        canChangeSettings: true,
        canDeleteData: true,
      );
    case Role.scorer:
      // 記録係はセキュリティレベルに応じて「設定変更」や「削除」が制限される
      return AppPermissions(
        canManageTournament: false, 
        canCreateMatch: true,      
        isReadOnly: false,
        canChangeSettings: isLenient, // Lv.2(標準)以上なら設定変更不可
        canDeleteData: isLenient,     // Lv.2(標準)以上ならデータ削除不可
      );
    case Role.editor:
      return const AppPermissions(
        canManageTournament: false, canCreateMatch: false, isReadOnly: false,
        canChangeSettings: false, canDeleteData: false,
      );
    default:
      return const AppPermissions(
        canManageTournament: false, canCreateMatch: false, isReadOnly: true,
        canChangeSettings: false, canDeleteData: false,
      );
  }
});