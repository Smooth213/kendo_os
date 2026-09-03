import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🌍 【Phase 8-1/7】ドイツ語超長単語（26文字超）レイアウトはみ出しゼロ FittedBox Widgetテスト', () {
    testWidgets(
      '1. 超長単語（Schiedsrichterentscheidung等）がボタン幅（160px）内で自動縮小されoverflowしないこと',
      (tester) async {
        const germanLongWord = 'Schiedsrichterentscheidung'; // 審判合議判定

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 160, // 固定幅の審判ボタン
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {},
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        germanLongWord,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // はみ出し例外（FlutterError）がゼロであること
        expect(tester.takeException(), isNull);
        expect(find.text(germanLongWord), findsOneWidget);

        // ボタンのサイズが 160x48 に厳格に収まっていること
        final buttonSize = tester.getSize(find.byType(ElevatedButton));
        expect(buttonSize.width, 160.0);
        expect(buttonSize.height, 48.0);
      },
    );
  });
}
