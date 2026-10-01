import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/routing/internal_router.dart';
import 'package:kendo_os/shared/routing/public_router.dart';

void main() {
  group('[Unit] 内部および公開ルーティング安全フォールバック単体テスト', () {
    testWidgets('InternalRouterにおいて定義済みルートが正しく返却され未知のルートは安全に遮断されること', (
      WidgetTester tester,
    ) async {
      final validWidget = InternalRouter.getRoute('observability-dashboard');
      await tester.pumpWidget(MaterialApp(home: validWidget));
      expect(find.text('Internal Observability Dashboard'), findsOneWidget);

      final invalidWidget = InternalRouter.getRoute('invalid-internal-target');
      await tester.pumpWidget(MaterialApp(home: invalidWidget));
      expect(find.textContaining('Access Denied'), findsOneWidget);
    });

    testWidgets('PublicRouterにおいて定義済みルートが正しく返却され未知のルートは安全に遮断されること', (
      WidgetTester tester,
    ) async {
      final validWidget = PublicRouter.getRoute('home', '');
      await tester.pumpWidget(MaterialApp(home: validWidget));
      expect(find.text('Public Home Screen'), findsOneWidget);

      final invalidWidget = PublicRouter.getRoute(
        'unsupported-public-path',
        '',
      );
      await tester.pumpWidget(MaterialApp(home: invalidWidget));
      expect(find.textContaining('Access Denied'), findsOneWidget);
    });
  });
}
