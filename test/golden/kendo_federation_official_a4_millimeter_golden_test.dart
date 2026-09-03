import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('📸 【Phase 6-7/12】全剣連公式 A4ミリメートル準拠団体戦試合記録表 Goldenテスト', () {
    testWidgets('1. 全日本剣道連盟公式記録用紙（5人制団体戦）の罫線・配置が正確にレンダリングされること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(700, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const positions = ['先鋒', '次鋒', '中堅', '副将', '大将'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Container(
                width: 650,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '全日本剣道連盟 公式団体試合記録表',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Table(
                      border: TableBorder.all(color: Colors.black, width: 1),
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(4),
                              child: Text(
                                '赤 チーム',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(4),
                              child: Text(
                                'ポジション',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(4),
                              child: Text(
                                '白 チーム',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(4),
                              child: Text(
                                '勝敗',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        for (final pos in positions)
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  '$pos 選手A',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  pos,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  '$pos 選手B',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(4),
                                child: Text(
                                  '引き分け',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          '../goldens/kendo_federation_official_a4_millimeter_golden.png',
        ),
      );
    });
  });
}
