import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_bracket_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_drawing_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ Kachinuki Bracket Painter Tests', () {
    test('1. PlayerSpan stores fields correctly', () {
      final span = PlayerSpan('A道場 : 佐藤', '佐藤', '佐', 0, 1);
      expect(span.rawName, 'A道場 : 佐藤');
      expect(span.lastName, '佐藤');
      expect(span.initial, '佐');
      expect(span.startIndex, 0);
      expect(span.endIndex, 1);
    });

    test('2. KachinukiBracketPainter shouldRepaint works', () {
      final p1 = KachinukiBracketPainter(matches: [], isDark: false);
      final p2 = KachinukiBracketPainter(matches: [], isDark: true);
      expect(p2.shouldRepaint(p1), isTrue);

      final p3 = KachinukiBracketPainter(matches: [], isDark: false);
      expect(p3.shouldRepaint(p1), isFalse);
    });

    test(
      '3. KachinukiDrawingHelper.drawTeamNameHorizontal executes without error',
      () {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        const rect = Rect.fromLTWH(0, 0, 70, 65);

        // 短いチーム名
        expect(
          () => KachinukiDrawingHelper.drawTeamNameHorizontal(
            canvas,
            'A道場',
            rect,
            const Color(0xFFE53935),
          ),
          returnsNormally,
        );

        // 長いチーム名（2行折り返し）
        expect(
          () => KachinukiDrawingHelper.drawTeamNameHorizontal(
            canvas,
            '昇龍館一福道場A',
            rect,
            const Color(0xFF3F51B5),
          ),
          returnsNormally,
        );

        // 超長チーム名
        expect(
          () => KachinukiDrawingHelper.drawTeamNameHorizontal(
            canvas,
            '全日本少年剣道錬成大会東京選抜チームA',
            rect,
            const Color(0xFF000000),
          ),
          returnsNormally,
        );
      },
    );
  });
}
