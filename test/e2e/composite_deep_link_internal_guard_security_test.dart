import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/security/admin_pin_guard.dart';
import 'package:kendo_os/security/deeplink_guard.dart';
import 'package:kendo_os/security/internal_only_guard.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/routing/internal_router.dart';
import 'package:kendo_os/shared/routing/public_router.dart';

void main() {
  group('[E2E] ディープリンク多層防衛およびセキュリティガード複合テスト', () {
    testWidgets('不正なディープリンクアクセス時に多層防御ガードが連動し水際で安全遮断されること', (
      WidgetTester tester,
    ) async {
      // 1. レイヤ1: DeepLinkGuardによる特権URI水際遮断
      const maliciousUri = '/internal/observability-dashboard';
      final canAccessDeepLink = DeepLinkGuard.canAccess(maliciousUri);
      expect(canAccessDeepLink, isFalse);

      // 2. レイヤ2: 遮断を突破しようと試みた場合のInternalOnlyGuardによるロール遮断
      final isViewerAllowed = InternalOnlyGuard.check(UserRole.viewer);
      expect(isViewerAllowed, isFalse);

      final isOperatorAllowed = InternalOnlyGuard.check(UserRole.operator);
      expect(isOperatorAllowed, isFalse);

      // 3. レイヤ3: 管理者PIN認証ガード
      expect(AdminPinGuard.validate('wrong_pin'), isFalse);
      expect(AdminPinGuard.validate('1234'), isTrue);

      // 4. レイヤ4: ルーティングフォールバック画面の安全描画
      final fallbackInternal = InternalRouter.getRoute('unauthorized_action');
      await tester.pumpWidget(MaterialApp(home: fallbackInternal));
      expect(find.textContaining('Access Denied'), findsOneWidget);

      final fallbackPublic = PublicRouter.getRoute('unknown_screen', '');
      await tester.pumpWidget(MaterialApp(home: fallbackPublic));
      expect(find.textContaining('Access Denied'), findsOneWidget);
    });
  });
}
