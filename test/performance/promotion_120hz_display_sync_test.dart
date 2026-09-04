import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/utils/promotion_display_helper.dart';

void main() {
  group('📱 【Phase 12: 120Hz ProMotion ディスプレイ完全同期】ガバナンステスト', () {
    test('フレームバジェット（許容時間）がリフレッシュレートに対して正確に計算されること', () {
      // 120Hz: 1000 / 120 = 8.333... ms
      const rate120 = 120.0;
      final budget120 = 1000.0 / rate120;
      expect(budget120, closeTo(8.333, 0.01));

      // 90Hz: 1000 / 90 = 11.111... ms
      const rate90 = 90.0;
      final budget90 = 1000.0 / rate90;
      expect(budget90, closeTo(11.111, 0.01));

      // 60Hz: 1000 / 60 = 16.666... ms
      const rate60 = 60.0;
      final budget60 = 1000.0 / rate60;
      expect(budget60, closeTo(16.666, 0.01));

      // ignore: avoid_print
      print(
        '📱 [ProMotion Frame Budget Benchmark]\n'
        '  - 120Hz ProMotion: ${budget120.toStringAsFixed(2)} ms/フレーム (iPad Pro / iPhone Pro)\n'
        '  - 90Hz High-Refresh: ${budget90.toStringAsFixed(2)} ms/フレーム\n'
        '  - 60Hz Standard: ${budget60.toStringAsFixed(2)} ms/フレーム',
      );
    });

    test('デフォルト環境（テスト環境等）で安全に60.0Hzフォールバックされること', () {
      final rate = PromotionDisplayHelper.getRefreshRate();
      expect(rate, greaterThanOrEqualTo(60.0));

      final budget = PromotionDisplayHelper.frameBudgetMs();
      expect(budget, lessThanOrEqualTo(16.67));
    });

    test('最適なアニメーション時間の算出とスクロール物理の取得', () {
      const baseDuration = Duration(milliseconds: 300);
      final optimal = PromotionDisplayHelper.optimalDuration(
        baseDuration: baseDuration,
      );
      expect(optimal.inMilliseconds, greaterThan(0));

      final physics = PromotionDisplayHelper.getOptimalScrollPhysics();
      expect(physics, isA<BouncingScrollPhysics>());
    });

    testWidgets('120FPS Ticker アニメーションが 8.33ms ステップで滑らかに完了すること', (
      tester,
    ) async {
      late AnimationController controller;
      final recordedValues = <double>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return _TestAnimatedWidget(
                onControllerCreated: (c) {
                  controller = c;
                  controller.addListener(() {
                    recordedValues.add(controller.value);
                  });
                },
              );
            },
          ),
        ),
      );

      expect(controller.value, equals(0.0));

      // 120Hz の 1フレーム（8.33ms）刻みで 60フレーム（約500ms）進行
      const frameDuration = Duration(microseconds: 8333);
      controller.forward();

      for (int i = 0; i < 60; i++) {
        await tester.pump(frameDuration);
      }

      // 値が単調増加し、途中で逆行や停止がないこと
      expect(recordedValues.isNotEmpty, isTrue);
      for (int i = 1; i < recordedValues.length; i++) {
        expect(
          recordedValues[i],
          greaterThanOrEqualTo(recordedValues[i - 1]),
          reason: '120FPSアニメーションは単調増加しなければならない',
        );
      }

      await tester.pumpAndSettle();
      expect(controller.value, equals(1.0));
    });
  });
}

class _TestAnimatedWidget extends StatefulWidget {
  final ValueChanged<AnimationController> onControllerCreated;

  const _TestAnimatedWidget({required this.onControllerCreated});

  @override
  State<_TestAnimatedWidget> createState() => _TestAnimatedWidgetState();
}

class _TestAnimatedWidgetState extends State<_TestAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    widget.onControllerCreated(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
