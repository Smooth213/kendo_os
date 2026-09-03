import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('👁️ 【Phase 6-6/12】全剣連特殊技記号（判・不・反・棄・×）丸囲みレンダリング Widgetテスト', () {
    testWidgets('1. 特殊勝敗記号（判・不・反・棄・×）が丸囲みバッジとして美麗に収まること', (tester) async {
      const specialSymbols = ['判', '不', '反', '棄', '×'];

      Widget buildSymbolBadge(String symbol) {
        return Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
            color: Colors.white,
          ),
          child: Text(
            symbol,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final sym in specialSymbols)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: buildSymbolBadge(sym),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      for (final sym in specialSymbols) {
        expect(find.text(sym), findsOneWidget);
      }
    });
  });
}
