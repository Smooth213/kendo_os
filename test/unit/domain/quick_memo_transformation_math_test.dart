import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('[Unit] クイックメモ ズーム倍率クランプと幾何学座標変換精度テスト', () {
    const baseCanvasSize = Size(800, 1000);

    // キャンバス座標変換ヘルパー
    Offset calculateCanvasCoordinates({
      required Offset localPosition,
      required Size viewportSize,
      required double zoomScale,
      required Offset panOffset,
    }) {
      final fitScale = math.min(
        viewportSize.width / baseCanvasSize.width,
        viewportSize.height / baseCanvasSize.height,
      );
      final initialPaperWidth = baseCanvasSize.width * fitScale;
      final initialPaperHeight = baseCanvasSize.height * fitScale;
      final paperCenterOffset = Offset(
        (viewportSize.width - initialPaperWidth) / 2,
        (viewportSize.height - initialPaperHeight) / 2,
      );

      final effectiveScale = fitScale * zoomScale;
      if (effectiveScale <= 0) return localPosition;
      final paperTopLeft = paperCenterOffset + panOffset;
      return (localPosition - paperTopLeft) / effectiveScale;
    }

    // 画面座標復元ヘルパー（順変換）
    Offset calculateScreenCoordinates({
      required Offset canvasPosition,
      required Size viewportSize,
      required double zoomScale,
      required Offset panOffset,
    }) {
      final fitScale = math.min(
        viewportSize.width / baseCanvasSize.width,
        viewportSize.height / baseCanvasSize.height,
      );
      final initialPaperWidth = baseCanvasSize.width * fitScale;
      final initialPaperHeight = baseCanvasSize.height * fitScale;
      final paperCenterOffset = Offset(
        (viewportSize.width - initialPaperWidth) / 2,
        (viewportSize.height - initialPaperHeight) / 2,
      );

      final effectiveScale = fitScale * zoomScale;
      final paperTopLeft = paperCenterOffset + panOffset;
      return paperTopLeft + (canvasPosition * effectiveScale);
    }

    test('等倍および拡大時における座標の順変換と逆変換の可逆誤差が0.01ピクセル未満であること', () {
      const viewport = Size(400, 700);
      final zoomScales = [1.0, 1.5, 2.0, 3.0, 4.0];
      final testCanvasPoints = [
        Offset.zero,
        const Offset(400, 500),
        const Offset(800, 1000),
        const Offset(123.45, 678.91),
      ];

      for (final zoom in zoomScales) {
        final pan = Offset(zoom * 15.0, -zoom * 20.0);
        for (final canvasPt in testCanvasPoints) {
          final screenPt = calculateScreenCoordinates(
            canvasPosition: canvasPt,
            viewportSize: viewport,
            zoomScale: zoom,
            panOffset: pan,
          );

          final restoredCanvasPt = calculateCanvasCoordinates(
            localPosition: screenPt,
            viewportSize: viewport,
            zoomScale: zoom,
            panOffset: pan,
          );

          expect((restoredCanvasPt.dx - canvasPt.dx).abs(), lessThan(0.01));
          expect((restoredCanvasPt.dy - canvasPt.dy).abs(), lessThan(0.01));
        }
      }
    });

    test('ズーム倍率の許容範囲外入力が1.0から4.0に確実にクランプされること', () {
      double clampZoom(double scale) => scale.clamp(1.0, 4.0);

      expect(clampZoom(0.2), 1.0);
      expect(clampZoom(0.99), 1.0);
      expect(clampZoom(1.0), 1.0);
      expect(clampZoom(2.5), 2.5);
      expect(clampZoom(4.0), 4.0);
      expect(clampZoom(5.5), 4.0);
      expect(clampZoom(100.0), 4.0);
    });

    test('InteractiveViewer の Matrix4 変換と toScene による座標逆変換が整合すること', () {
      final transform = TransformationController();
      // 2倍拡大 & オフセット (50, 80)
      transform.value = Matrix4.diagonal3Values(2.0, 2.0, 1.0)
        ..setTranslationRaw(-50.0, -80.0, 0.0);

      const tapPoint = Offset(200, 300);
      final scenePoint = transform.toScene(tapPoint);

      // 逆行列の計算: scene = (tap - (-50, -80)) / 2.0 = (250 / 2, 380 / 2) = (125.0, 190.0)
      expect(scenePoint.dx, closeTo(125.0, 0.001));
      expect(scenePoint.dy, closeTo(190.0, 0.001));
    });
  });
}
