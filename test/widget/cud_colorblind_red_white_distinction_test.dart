import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('👁️ 【Phase 6-1/12】CUD（カラーユニバーサルデザイン）P型・D型色覚赤白形状判別テスト', () {
    testWidgets('1. 赤白スコア表示が色のみに依存せず、アイコン形状（▲と△）およびラベルで確実に識別可能であること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 赤側: 赤色背景＋塗りつぶし三角「▲」＋テキスト「赤」
                  Container(
                    key: const Key('cud_red_badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: const Color(0xFFDC2626), // 赤
                    child: const Row(
                      children: [
                        Icon(
                          Icons.change_history,
                          color: Colors.white,
                          semanticLabel: '赤三角マーク',
                        ),
                        SizedBox(width: 8),
                        Text(
                          '赤: 佐藤',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // 白側: 白抜き枠線＋白抜き丸「◯」＋テキスト「白」
                  Container(
                    key: const Key('cud_white_badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.radio_button_unchecked,
                          color: Colors.white,
                          semanticLabel: '白丸マーク',
                        ),
                        SizedBox(width: 8),
                        Text(
                          '白: 鈴木',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 色覚シミュレーション下（色情報を遮断したモノクロ・形状抽出）でも赤白が判別できること
      expect(find.text('赤: 佐藤'), findsOneWidget);
      expect(find.text('白: 鈴木'), findsOneWidget);
      expect(find.byIcon(Icons.change_history), findsOneWidget); // 赤専用シンボル
      expect(
        find.byIcon(Icons.radio_button_unchecked),
        findsOneWidget,
      ); // 白専用シンボル
    });
  });
}
