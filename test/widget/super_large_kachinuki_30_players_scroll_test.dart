import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('👁️ 【Phase 6-5/12】30人超巨大勝ち抜き戦 スムーズ仮想スクロール Widgetテスト', () {
    testWidgets(
      '1. 30人勝ち抜き戦リストが仮想化スクロール（ListView.builder）で軽快に最下部までスクロールできること',
      (tester) async {
        final controller = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                controller: controller,
                itemCount: 30,
                itemBuilder: (context, index) {
                  final matchNum = index + 1;
                  return ListTile(
                    key: Key('kachinuki_match_$matchNum'),
                    title: Text('第$matchNum戦: 勝者残留 vs 挑戦者$matchNum'),
                    trailing: Text(matchNum < 10 ? '終了 (勝)' : '待機中'),
                  );
                },
              ),
            ),
          ),
        );

        // 初期表示（第1戦が見える）
        expect(find.byKey(const Key('kachinuki_match_1')), findsOneWidget);
        expect(
          find.byKey(const Key('kachinuki_match_30')),
          findsNothing,
        ); // まだ描画されていない

        // 最下部（第30戦）へ高速スクロール
        await tester.fling(find.byType(ListView), const Offset(0, -3000), 5000);
        await tester.pumpAndSettle();

        // 第30戦が安全に描画され、クラッシュしないこと
        expect(find.byKey(const Key('kachinuki_match_30')), findsOneWidget);
      },
    );
  });
}
