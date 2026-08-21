import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_bracket_painter.dart';

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
  });
}
