import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_stroke_eraser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ ProgramViewer Extracted Components Tests', () {
    test('1. ProgramViewerStrokeEraser detects near strokes correctly', () {
      final points = [const Offset(10.0, 10.0), const Offset(20.0, 20.0)];

      expect(
        ProgramViewerStrokeEraser.isNearStroke(
          const Offset(12.0, 12.0),
          points,
          5.0,
        ),
        isTrue,
      );
      expect(
        ProgramViewerStrokeEraser.isNearStroke(
          const Offset(50.0, 50.0),
          points,
          5.0,
        ),
        isFalse,
      );
    });

    test('2. ProgramViewerStrokeEraser detects local strokes correctly', () {
      final xs = [10.0, 20.0];
      final ys = [10.0, 20.0];

      expect(
        ProgramViewerStrokeEraser.isNearLocalStroke(
          const Offset(12.0, 12.0),
          xs,
          ys,
          5.0,
        ),
        isTrue,
      );
      expect(
        ProgramViewerStrokeEraser.isNearLocalStroke(
          const Offset(50.0, 50.0),
          xs,
          ys,
          5.0,
        ),
        isFalse,
      );
    });
  });
}
