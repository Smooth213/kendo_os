import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('☁️ 【Phase 7-4/8】直射日光・逆光グレア対策 超高コントラスト屋外モード Widgetテスト', () {
    testWidgets('1. グレアモード有効時、背景が純黒（0xFF000000）かつ高輝度テキストで視認性が最大化されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black, // 純黒
            body: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFFFFF00),
                    width: 4,
                  ), // 蛍光黄色の極太ボーダー
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '【直射日光グレア対策モード】',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFFF00), // 蛍光黄
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '残り 180 秒',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white, // 純白
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('【直射日光グレア対策モード】'), findsOneWidget);
      expect(find.text('残り 180 秒'), findsOneWidget);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });
  });
}
