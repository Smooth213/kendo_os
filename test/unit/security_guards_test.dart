import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/security/admin_pin_guard.dart';
import 'package:kendo_os/security/deeplink_guard.dart';
import 'package:kendo_os/security/internal_only_guard.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';

void main() {
  group('[Unit] セキュリティ防衛ガード単体テスト', () {
    test('AdminPinGuardにおいて正当な暗証番号のみ認証成功し不正な値は遮断されること', () {
      expect(AdminPinGuard.validate('1234'), isTrue);
      expect(AdminPinGuard.validate('0000'), isFalse);
      expect(AdminPinGuard.validate(''), isFalse);
      expect(AdminPinGuard.validate('admin'), isFalse);
      expect(AdminPinGuard.validate('12345'), isFalse);
    });

    test('DeepLinkGuardにおいて特権パスを含むURIが遮断され一般パスはアクセス許可されること', () {
      expect(
        DeepLinkGuard.canAccess('/internal/observability-dashboard'),
        isFalse,
      );
      expect(DeepLinkGuard.canAccess('/audit-log'), isFalse);
      expect(DeepLinkGuard.canAccess('/rule-config-panel'), isFalse);
      expect(DeepLinkGuard.canAccess('/master-management'), isFalse);

      expect(DeepLinkGuard.canAccess('/home'), isTrue);
      expect(DeepLinkGuard.canAccess('/match/match_123'), isTrue);
      expect(DeepLinkGuard.canAccess('/viewer/view_456'), isTrue);
      expect(DeepLinkGuard.canAccess('/settings'), isTrue);
    });

    test('InternalOnlyGuardにおいて管理者ロールのみ通過し一般ロールは遮断されること', () {
      expect(InternalOnlyGuard.check(UserRole.admin), isTrue);
      expect(InternalOnlyGuard.check(UserRole.operator), isFalse);
      expect(InternalOnlyGuard.check(UserRole.viewer), isFalse);
    });
  });
}
