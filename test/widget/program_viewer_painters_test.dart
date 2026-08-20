import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/score/stroke_model.dart';
import 'package:kendo_os/features/tournament/presentation/painters/program_viewer_painters.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/local_stroke_model.dart';

void main() {
  group('🛡️ ProgramViewer Painters Tests', () {
    testWidgets('StrokePainter paints shared and private strokes', (
      tester,
    ) async {
      final sharedStroke = StrokeModel(
        id: 's1',
        programId: 'p1',
        points: const [Offset(10, 10), Offset(50, 50)],
        color: Colors.red,
        strokeWidth: 4.0,
      );

      final privateStroke = LocalStrokeModel()
        ..colorValue = Colors.blue.toARGB32()
        ..strokeWidth = 4.0
        ..pointsX = [20.0, 60.0]
        ..pointsY = [20.0, 60.0];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: StrokePainter(
                sharedStrokes: [sharedStroke],
                privateStrokes: [privateStroke],
                currentPoints: const [Offset(30, 30), Offset(70, 70)],
                currentLineColor: Colors.green,
                activePenWidth: 6.0,
              ),
              size: const Size(200, 200),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('OcrHighlightPainter paints matched bounding box', (
      tester,
    ) async {
      final ocrWords = [
        {
          'text': '先鋒',
          'vertices': [
            {'x': 10, 'y': 10},
            {'x': 50, 'y': 10},
            {'x': 50, 'y': 30},
            {'x': 10, 'y': 30},
          ],
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: OcrHighlightPainter(
                ocrWords: ocrWords,
                searchText: '先鋒',
                originalImageSize: const Size(100, 100),
              ),
              size: const Size(200, 200),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
