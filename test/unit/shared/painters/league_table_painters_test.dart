import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kendo_os/presentation/viewer/painters/league_table_painters.dart';

void main() {
  group('🎨 League Table Painters Tests (描画レイヤー保護テスト)', () {
    
    testWidgets('1. DiagonalLinePainter - 斜め線が例外なく描画されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomPaint(
                key: const Key('painter_target'),
                size: const Size(100, 100),
                painter: DiagonalLinePainter(color: Colors.black),
              ),
            ),
          ),
        ),
      );

      // Widgetツリーに正常にマウントされ、エラーがスローされていないことを確認
      expect(find.byKey(const Key('painter_target')), findsOneWidget);

      // パフォーマンス要件：shouldRepaint は常に false であるべき
      final painter = DiagonalLinePainter(color: Colors.black);
      expect(painter.shouldRepaint(painter), isFalse, reason: '静的な図形のため、再描画要求は常にfalseでなければならない');
    });

    testWidgets('2. ResultShapePainter [Win] - 勝ち(◯)が例外なく描画されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              key: const Key('painter_target'),
              size: const Size(50, 50),
              painter: ResultShapePainter(result: 'win', color: Colors.red),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('painter_target')), findsOneWidget);
    });

    testWidgets('3. ResultShapePainter [Loss] - 負け(△)が例外なく描画されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              key: const Key('painter_target'),
              size: const Size(50, 50),
              painter: ResultShapePainter(result: 'loss', color: Colors.blue),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('painter_target')), findsOneWidget);
    });

    testWidgets('4. ResultShapePainter [Draw] - 引き分け(□)が例外なく描画されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              key: const Key('painter_target'),
              size: const Size(50, 50),
              // 想定外の文字列が来てもクラッシュせず、引き分け(□)として描画される安全性をテスト
              painter: ResultShapePainter(result: 'unknown_draw', color: Colors.green), 
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('painter_target')), findsOneWidget);
      
      final painter = ResultShapePainter(result: 'draw', color: Colors.green);
      expect(painter.shouldRepaint(painter), isFalse);
    });

    testWidgets('5. buildIndivSingle - 1本目の丸囲みUIが正常に生成されること', (WidgetTester tester) async {
      // isFirst = true, 技 = 'メ' の場合
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildIndivSingle('メ', true, Colors.red),
          ),
        ),
      );
      
      // テキストが描画されていることを確認
      expect(find.text('メ'), findsOneWidget);
      
      // 判定('判定')が省略形('判')に変換されるロジックの検証
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildIndivSingle('判定', true, Colors.blue),
          ),
        ),
      );
      expect(find.text('判'), findsOneWidget);
    });

  });
}