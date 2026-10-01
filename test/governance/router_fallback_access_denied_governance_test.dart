import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/routing/internal_router.dart';
import 'package:kendo_os/shared/routing/public_router.dart';

void main() {
  group('[Governance] 未定義ルート遮断および安全フォールバック画面保証規約', () {
    testWidgets('未知の内部ルートおよび公開ルート要求時に安全にAccessDenied画面へフォールバックされること', (
      tester,
    ) async {
      final internalFallback = InternalRouter.getRoute('unknown_danger_route');
      await tester.pumpWidget(MaterialApp(home: internalFallback));
      expect(find.textContaining('Access Denied'), findsOneWidget);

      final publicFallback = PublicRouter.getRoute(
        'unknown_public_target',
        'id',
      );
      await tester.pumpWidget(MaterialApp(home: publicFallback));
      expect(find.textContaining('Access Denied'), findsOneWidget);
    });

    test('静的解析においてルーターにデフォルト安全遮断節が存在すること', () {
      final internalFile = File('lib/shared/routing/internal_router.dart');
      final publicFile = File('lib/shared/routing/public_router.dart');

      expect(internalFile.existsSync(), isTrue);
      expect(publicFile.existsSync(), isTrue);

      expect(internalFile.readAsStringSync().contains('Access Denied'), isTrue);
      expect(publicFile.readAsStringSync().contains('Access Denied'), isTrue);
    });
  });
}
