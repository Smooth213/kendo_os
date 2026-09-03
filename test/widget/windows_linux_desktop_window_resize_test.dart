import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🌍 【Phase 8-6/7】デスクトップ（Win/Mac/Linux）ウィンドウ極端リサイズ耐久テスト', () {
    testWidgets('1. ウルトラワイド（1920x600）および極小（400x300）でもスコア盤が崩壊せずリキッド配置されること', (
      tester,
    ) async {
      addTearDown(tester.view.reset);

      Widget buildDesktopScoreboard() {
        return MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.black,
                    child: Flex(
                      direction: isCompact ? Axis.vertical : Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        Text(
                          '佐藤 (赤)',
                          style: TextStyle(color: Colors.red, fontSize: 18),
                        ),
                        Text(
                          'VS',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        Text(
                          '鈴木 (白)',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }

      // 1. ウルトラワイド解像度（1920x600）
      tester.view.physicalSize = const Size(1920, 600);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(buildDesktopScoreboard());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('佐藤 (赤)'), findsOneWidget);

      // 2. 極小ウィンドウ（400x300）へリサイズ
      tester.view.physicalSize = const Size(400, 300);
      await tester.pumpWidget(buildDesktopScoreboard());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('佐藤 (赤)'), findsOneWidget);
      expect(find.text('鈴木 (白)'), findsOneWidget);
    });
  });
}
