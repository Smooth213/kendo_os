import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/security/feature_gate.dart';
import 'package:kendo_os/security/role_permissions.dart';
import 'package:kendo_os/security/security_level.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';

void main() {
  group('[Governance] ロール権限一元統治およびハードコードロール比較排除規約', () {
    test('UIコンポーネント層においてUserRoleの直接等価比較が禁止され権限定義クラス経由で統治されていること', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) {
            final p = f.path;
            if (!p.contains('/presentation/')) return false;
            // 認証入力画面および内部Provider層のマッピング処理は正当な定義箇所として除外
            if (p.contains('lib/features/auth/presentation/screens/'))
              return false;
            if (p.contains('/providers/')) return false;
            return true;
          });

      final directComparisonRegex = RegExp(
        r'role\s*==\s*UserRole\.(admin|viewer|recorder|operator)',
      );

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final matches = directComparisonRegex.allMatches(content);
        expect(
          matches.isEmpty,
          isTrue,
          reason:
              'ファイル ${file.path} にて UserRole の直接比較が検出されました。RolePermissions または FeatureGate を使用してください。',
        );
      }
    });

    test('RolePermissionsにおいてAdminおよびOperatorのみ大会作成権限が許可されること', () {
      expect(RolePermissions.canCreateTournament(UserRole.admin), isTrue);
      expect(RolePermissions.canCreateTournament(UserRole.operator), isTrue);
      expect(RolePermissions.canCreateTournament(UserRole.recorder), isFalse);
      expect(RolePermissions.canCreateTournament(UserRole.viewer), isFalse);
    });

    test('RolePermissionsにおいて大会削除および編集権限がAdminのみに制限されていること', () {
      expect(RolePermissions.canDeleteTournament(UserRole.admin), isTrue);
      expect(RolePermissions.canDeleteTournament(UserRole.operator), isFalse);
      expect(RolePermissions.canDeleteTournament(UserRole.recorder), isFalse);
      expect(RolePermissions.canDeleteTournament(UserRole.viewer), isFalse);

      expect(RolePermissions.canEditTournament(UserRole.admin), isTrue);
      expect(RolePermissions.canEditTournament(UserRole.operator), isFalse);
      expect(RolePermissions.canEditTournament(UserRole.recorder), isFalse);
      expect(RolePermissions.canEditTournament(UserRole.viewer), isFalse);
    });

    test('RolePermissionsにおいて選手マスタの編集権限がAdminのみに制限されていること', () {
      expect(RolePermissions.canEditPlayerMaster(UserRole.admin), isTrue);
      expect(RolePermissions.canEditPlayerMaster(UserRole.operator), isFalse);
      expect(RolePermissions.canEditPlayerMaster(UserRole.recorder), isFalse);
      expect(RolePermissions.canEditPlayerMaster(UserRole.viewer), isFalse);
    });

    test('RolePermissionsにおいてViewerのみ閲覧専用判定が真となること', () {
      expect(RolePermissions.isViewer(UserRole.viewer), isTrue);
      expect(RolePermissions.isViewer(UserRole.admin), isFalse);
      expect(RolePermissions.isViewer(UserRole.operator), isFalse);
      expect(RolePermissions.isViewer(UserRole.recorder), isFalse);
    });

    test('FeatureGateにおいて特権機能の利用権限がAdminのみに制限されていること', () {
      for (final role in UserRole.values) {
        final isExpected = (role == UserRole.admin);
        expect(FeatureGate.canUseAI(role), equals(isExpected));
        expect(FeatureGate.canManageReplay(role), equals(isExpected));
        expect(FeatureGate.canAccessObservability(role), equals(isExpected));
        expect(FeatureGate.canAccessMetrics(role), equals(isExpected));
        expect(FeatureGate.canExecuteGovernance(role), equals(isExpected));
      }
    });

    test('FeatureGateにおいてセキュリティレベルlocked時に全操作権限が遮断されること', () {
      for (final role in UserRole.values) {
        expect(FeatureGate.canCreateMatch(role, SecurityLevel.locked), isFalse);
        expect(
          FeatureGate.canOperateMatch(role, SecurityLevel.locked),
          isFalse,
        );
        expect(
          FeatureGate.canManageMaster(role, SecurityLevel.locked),
          isFalse,
        );
      }
    });
  });
}
