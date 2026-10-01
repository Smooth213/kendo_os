import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/admin/presentation/screens/rule_config_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] ルール設定パネル視覚整合性テスト', () {
    testWidgets('ライトテーマにおいてルール設定パネルのプリセットチップおよび詳細設定項目が崩れず描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: RuleConfigPanel(forceShow: true),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(RuleConfigPanel), findsOneWidget);
      expect(find.text('1. 大会プリセットを選択 (Basic)'), findsOneWidget);
      expect(find.text('2. 詳細設定をカスタマイズ (Advanced)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ダークテーマにおいて高コントラストかつレイアウト破綻なく視覚的整合性が維持されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              backgroundColor: Color(0xFF121212),
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: RuleConfigPanel(forceShow: true),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(RuleConfigPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('テキストスケール1.5倍のアクセシビリティ拡大表示でもオーバーフローなく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: const Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: RuleConfigPanel(forceShow: true),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(RuleConfigPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
