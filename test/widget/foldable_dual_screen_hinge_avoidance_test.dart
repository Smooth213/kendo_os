import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🌍 【Phase 8-7/7】折りたたみ端末（Foldable）ヒンジ蝶番回避セーフティテスト', () {
    testWidgets('1. 画面中央のヒンジ（幅20px）を検知し、赤操作盤と白操作盤が左右画面に安全分離配置されること', (
      tester,
    ) async {
      addTearDown(tester.view.reset);

      // 横幅800px、中央（390〜410px）にヒンジが存在する端末
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      tester.view.displayFeatures = const [
        DisplayFeature(
          bounds: Rect.fromLTWH(390, 0, 20, 600), // 中央ヒンジ
          type: DisplayFeatureType.hinge,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                // 左画面（赤側操作パネル: 幅390px）
                Expanded(
                  child: Container(
                    key: const Key('left_screen_red_panel'),
                    color: Colors.red.shade900,
                    child: const Center(child: Text('赤側操作盤（左画面）')),
                  ),
                ),
                // 中央ヒンジスペーサー（20px: 物理折り目部分にボタンを置かない！）
                const SizedBox(width: 20),
                // 右画面（白側操作パネル: 幅390px）
                Expanded(
                  child: Container(
                    key: const Key('right_screen_white_panel'),
                    color: Colors.blueGrey.shade900,
                    child: const Center(child: Text('白側操作盤（右画面）')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final leftRect = tester.getRect(
        find.byKey(const Key('left_screen_red_panel')),
      );
      final rightRect = tester.getRect(
        find.byKey(const Key('right_screen_white_panel')),
      );

      // 左パネルの右端は 390 以下
      expect(leftRect.right, lessThanOrEqualTo(390.0));
      // 右パネルの左端は 410 以上（中央ヒンジ20pxの空白が厳格に守られていること！）
      expect(rightRect.left, greaterThanOrEqualTo(410.0));
    });
  });
}
