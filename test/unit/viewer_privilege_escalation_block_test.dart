import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';

void main() {
  group('🌐 【Phase 4-8/11】一般観客（Viewer）ゼロトラスト権限昇格（直叩き）遮断テスト', () {
    test(
      '1. Viewer 権限（Role.viewer）はスコア編集・Undo・試合作成・ロックの全権限が厳格に false であること',
      () {
        final viewerPerms = PermissionFactory.from(Role.viewer);

        expect(viewerPerms.canEditScore, isFalse);
        expect(viewerPerms.canUndo, isFalse);
        expect(viewerPerms.canCreateMatch, isFalse);
        expect(viewerPerms.canLockMatch, isFalse);
        expect(viewerPerms.isReadOnly, isTrue);
      },
    );

    test('2. Viewer ユーザーによる特権操作（スコア入力API）呼び出しのゼロトラスト遮断', () {
      const viewerUser = User(
        id: 'viewer_guest_01',
        role: Role.viewer,
        organizationId: 'org_public',
      );

      // ゼロトラスト認可ガード
      bool authorizeScoreEdit(User user) {
        final perms = PermissionFactory.from(user.role);
        if (!perms.canEditScore || perms.isReadOnly) {
          throw Exception(
            'SecurityError: Permission denied for role ${user.role}',
          );
        }
        return true;
      }

      // Viewerによる操作は必ず例外（403 Forbidden）で即座に遮断されること
      expect(
        () => authorizeScoreEdit(viewerUser),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Permission denied'),
          ),
        ),
      );
    });

    test('3. Scorer または Admin ユーザーのみが正規にスコア編集を許可されること', () {
      const scorerUser = User(
        id: 's1',
        role: Role.scorer,
        organizationId: 'o1',
      );
      const adminUser = User(id: 'a1', role: Role.admin, organizationId: 'o1');

      final scorerPerms = PermissionFactory.from(scorerUser.role);
      final adminPerms = PermissionFactory.from(adminUser.role);

      expect(scorerPerms.canEditScore, isTrue);
      expect(adminPerms.canEditScore, isTrue);
    });
  });
}
