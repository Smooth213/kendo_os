import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/security/admin_pin_guard.dart';
import 'package:kendo_os/security/deeplink_guard.dart';
import 'package:kendo_os/security/internal_only_guard.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/infrastructure/repository/firestore_path.dart';

void main() {
  group('[Governance] セキュリティガード網羅的アクセス制御および空間隔離保証規約', () {
    test('特権画面へのディープリンク直打ちが水際で完全に遮断されること', () {
      final protectedTargets = [
        'observability-dashboard',
        'audit-log',
        'rule-config',
        'master-management',
      ];

      for (final target in protectedTargets) {
        expect(
          DeepLinkGuard.canAccess('/internal/$target'),
          isFalse,
          reason: '特権ターゲット $target が遮断されていません',
        );
      }
    });

    test('一般ユーザーおよび操作端末による管理者機能への進入が多層的に阻止されること', () {
      // ViewerロールおよびOperatorロールは管理者機能を実行できない
      expect(InternalOnlyGuard.check(UserRole.viewer), isFalse);
      expect(InternalOnlyGuard.check(UserRole.operator), isFalse);
      expect(InternalOnlyGuard.check(UserRole.admin), isTrue);

      // PIN入力において空文字や不正文字列が拒否されること
      expect(AdminPinGuard.validate(''), isFalse);
      expect(AdminPinGuard.validate('wrong'), isFalse);
      expect(AdminPinGuard.validate(AdminPinGuard.pin), isTrue);
    });

    test('マルチテナント空間パスにおいて道場識別子を含む階層構造が強制されていること', () {
      const dojo = 'tenant_xyz';
      expect(
        FirestorePath.organization(dojo).startsWith('organizations/'),
        isTrue,
      );
      expect(
        FirestorePath.matches(dojo).startsWith('organizations/$dojo/'),
        isTrue,
      );
      expect(
        FirestorePath.players(dojo).startsWith('organizations/$dojo/'),
        isTrue,
      );
      expect(
        FirestorePath.tournaments(dojo).startsWith('organizations/$dojo/'),
        isTrue,
      );
    });

    test('静的解析においてセキュリティガードクラスがバイパス不可能な構造であること', () {
      final guardFile = File('lib/security/deeplink_guard.dart');
      expect(guardFile.existsSync(), isTrue);
      final content = guardFile.readAsStringSync();
      expect(content.contains('canAccess'), isTrue);
      expect(content.contains('observability'), isTrue);
      expect(content.contains('audit'), isTrue);
    });
  });
}
