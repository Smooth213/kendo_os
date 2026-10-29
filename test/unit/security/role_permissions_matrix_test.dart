import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/security/role_permissions.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';

void main() {
  group('[Unit] ロール権限マトリクスおよび全ロール境界値判定テスト', () {
    test('大会作成権限において管理者および監督のみ真を返し他ロールを遮断すること', () {
      expect(RolePermissions.canCreateTournament(UserRole.admin), isTrue);
      expect(RolePermissions.canCreateTournament(UserRole.operator), isTrue);
      expect(RolePermissions.canCreateTournament(UserRole.recorder), isFalse);
      expect(RolePermissions.canCreateTournament(UserRole.viewer), isFalse);
    });

    test('大会完全削除権限において最高特権の管理者のみ真を返し完全制限すること', () {
      expect(RolePermissions.canDeleteTournament(UserRole.admin), isTrue);
      expect(RolePermissions.canDeleteTournament(UserRole.operator), isFalse);
      expect(RolePermissions.canDeleteTournament(UserRole.recorder), isFalse);
      expect(RolePermissions.canDeleteTournament(UserRole.viewer), isFalse);
    });

    test('大会構造編集権限において管理者のみ真を返し不正変更を防止すること', () {
      expect(RolePermissions.canEditTournament(UserRole.admin), isTrue);
      expect(RolePermissions.canEditTournament(UserRole.operator), isFalse);
      expect(RolePermissions.canEditTournament(UserRole.recorder), isFalse);
      expect(RolePermissions.canEditTournament(UserRole.viewer), isFalse);
    });

    test('選手マスタアクセス権限において閲覧専用以外の全ロールで真を返すこと', () {
      expect(RolePermissions.canAccessPlayerMaster(UserRole.admin), isTrue);
      expect(RolePermissions.canAccessPlayerMaster(UserRole.operator), isTrue);
      expect(RolePermissions.canAccessPlayerMaster(UserRole.recorder), isTrue);
      expect(RolePermissions.canAccessPlayerMaster(UserRole.viewer), isFalse);
    });

    test('選手マスタ編集権限において管理者のみ真を返し誤編集を完全排除すること', () {
      expect(RolePermissions.canEditPlayerMaster(UserRole.admin), isTrue);
      expect(RolePermissions.canEditPlayerMaster(UserRole.operator), isFalse);
      expect(RolePermissions.canEditPlayerMaster(UserRole.recorder), isFalse);
      expect(RolePermissions.canEditPlayerMaster(UserRole.viewer), isFalse);
    });

    test('試合データ個別編集および削除権限において管理者と監督のみ許可すること', () {
      expect(RolePermissions.canEditAndDeleteMatch(UserRole.admin), isTrue);
      expect(RolePermissions.canEditAndDeleteMatch(UserRole.operator), isTrue);
      expect(RolePermissions.canEditAndDeleteMatch(UserRole.recorder), isFalse);
      expect(RolePermissions.canEditAndDeleteMatch(UserRole.viewer), isFalse);
    });

    test('試合操作権限において閲覧専用以外のロールを許可し試合入力を成立させること', () {
      expect(RolePermissions.canOperateMatch(UserRole.admin), isTrue);
      expect(RolePermissions.canOperateMatch(UserRole.operator), isTrue);
      expect(RolePermissions.canOperateMatch(UserRole.recorder), isTrue);
      expect(RolePermissions.canOperateMatch(UserRole.viewer), isFalse);
    });

    test('打突取り消し機能において閲覧専用以外のロールに利用を許可すること', () {
      expect(RolePermissions.canUseUndo(UserRole.admin), isTrue);
      expect(RolePermissions.canUseUndo(UserRole.operator), isTrue);
      expect(RolePermissions.canUseUndo(UserRole.recorder), isTrue);
      expect(RolePermissions.canUseUndo(UserRole.viewer), isFalse);
    });

    test('アプリ設定画面アクセス権限において閲覧専用以外のロールに許可すること', () {
      expect(RolePermissions.canAccessSettings(UserRole.admin), isTrue);
      expect(RolePermissions.canAccessSettings(UserRole.operator), isTrue);
      expect(RolePermissions.canAccessSettings(UserRole.recorder), isTrue);
      expect(RolePermissions.canAccessSettings(UserRole.viewer), isFalse);
    });

    test('閲覧専用判定において閲覧者ロールのみ真を返し他ロールで偽を返すこと', () {
      expect(RolePermissions.isViewer(UserRole.viewer), isTrue);
      expect(RolePermissions.isViewer(UserRole.admin), isFalse);
      expect(RolePermissions.isViewer(UserRole.operator), isFalse);
      expect(RolePermissions.isViewer(UserRole.recorder), isFalse);
    });
  });
}
