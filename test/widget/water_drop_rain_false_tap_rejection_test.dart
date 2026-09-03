import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 💧 水滴・汗滴誤タップ棄却フィルター
class WaterDropTouchFilter {
  /// 人間の指のタップか、水滴/汗の誤接触かを判定
  static bool isValidHumanTap({
    required double pressure,
    required double radiusMajor,
  }) {
    // 水滴は接触面積が極めて小さい（radius < 2.0）または接触圧が微小
    if (radiusMajor < 2.0 || pressure < 0.15) {
      return false; // 水滴・汗によるゴーストタップとして棄却
    }
    return true; // 人間の指による正規タップ
  }
}

void main() {
  group('🌌 【Phase 9-4/6】雨漏り・汗・水滴ゴーストタップ（誤打突）100%棄却セーフティテスト', () {
    test('1. 水滴落下（接触半径0.8、圧力0.05）が誤打突と判定されず100%遮断されること', () {
      final isWaterDropAccepted = WaterDropTouchFilter.isValidHumanTap(
        pressure: 0.05,
        radiusMajor: 0.8,
      );

      // 水滴タップは即座に棄却されること
      expect(isWaterDropAccepted, isFalse);
    });

    test('2. 人間の指による打突ボタン押下（接触半径10.0、圧力0.6）は正常に受理されること', () {
      final isHumanTapAccepted = WaterDropTouchFilter.isValidHumanTap(
        pressure: 0.6,
        radiusMajor: 10.0,
      );

      // 人間のタップは正しく受理されること
      expect(isHumanTapAccepted, isTrue);
    });

    testWidgets('3. PointerDown/UpEvent による水滴遮断および指タップ受理検証', (tester) async {
      int score = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Listener(
                key: const Key('strike_touch_area'),
                onPointerDown: (event) {
                  if (WaterDropTouchFilter.isValidHumanTap(
                    pressure: event.pressure,
                    radiusMajor: event.radiusMajor,
                  )) {
                    score++;
                  }
                },
                child: Container(
                  width: 200,
                  height: 100,
                  color: Colors.red,
                  child: const Center(child: Text('赤面 タッチ領域')),
                ),
              ),
            ),
          ),
        ),
      );

      final center = tester.getCenter(
        find.byKey(const Key('strike_touch_area')),
      );

      // 1. 水滴シミュレーション（pointer: 1, 微小接触半径 0.5、微小圧 0.05）
      await tester.sendEventToBinding(
        PointerDownEvent(
          pointer: 1,
          position: center,
          pressure: 0.05,
          radiusMajor: 0.5,
        ),
      );
      await tester.sendEventToBinding(
        PointerUpEvent(pointer: 1, position: center),
      );
      await tester.pump();

      // 水滴によるスコア加点は 0（完全に棄却！）
      expect(score, 0);

      // 2. 人間の指タップシミュレーション（pointer: 2, 接触半径 8.0、圧力 0.8）
      await tester.sendEventToBinding(
        PointerDownEvent(
          pointer: 2,
          position: center,
          pressure: 0.8,
          radiusMajor: 8.0,
        ),
      );
      await tester.sendEventToBinding(
        PointerUpEvent(pointer: 2, position: center),
      );
      await tester.pump();

      // 人間のタップのみ受理され、スコアが1になること！
      expect(score, 1);
    });
  });
}
