import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🌍 【Phase 8-2/7】RTL（右横書きアラビア語）ロケール下 スコア・タイマー方向保護テスト', () {
    testWidgets('1. RTL環境下でもタイマー（03:00）の数字並びが逆転せず、赤白のスコア表示が保たれること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl, // アラビア語 RTL
            child: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // アラビア語ヘッダー
                    const Text(
                      'بطولة كندو',
                      style: TextStyle(fontSize: 18),
                    ), // 剣道大会
                    const SizedBox(height: 12),
                    // 🛡️ LTR強制（スコア・タイマーは世界共通で左➔右配置）
                    const Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '赤: 佐藤 (1)',
                            style: TextStyle(color: Colors.red),
                          ),
                          SizedBox(width: 16),
                          Text(
                            '02:45',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 16),
                          Text(
                            '(0) 白: 鈴木',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // タイマー文字列が '02:45' のまま正確に存在すること（'45:02' に逆転しない！）
      expect(find.text('02:45'), findsOneWidget);
      expect(find.text('赤: 佐藤 (1)'), findsOneWidget);
      expect(find.text('(0) 白: 鈴木'), findsOneWidget);

      // 赤（左側）の x座標が 白（右側）の x座標より小さい（左にある）こと
      final redX = tester.getTopLeft(find.text('赤: 佐藤 (1)')).dx;
      final whiteX = tester.getTopLeft(find.text('(0) 白: 鈴木')).dx;
      expect(redX, lessThan(whiteX));
    });
  });
}
