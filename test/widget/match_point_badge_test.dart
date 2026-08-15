import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_point_badge.dart';

void main() {
  group('🛡️ MatchPointBadge Widget Tests', () {
    testWidgets('Renders simple strike mark correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchPointBadge(mark: 'メ', isFirst: false, color: Colors.red),
          ),
        ),
      );

      expect(find.text('メ'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('メ'));
      expect(textWidget.style?.color, equals(Colors.red));

      // 先取丸枠線がないこと
      final circleDecorations = tester
          .widgetList<Container>(find.byType(Container))
          .where((container) {
            final decoration = container.decoration;
            return decoration is BoxDecoration &&
                decoration.shape == BoxShape.circle;
          });
      expect(circleDecorations.isEmpty, isTrue);
    });

    testWidgets('Renders first match point with circle border correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchPointBadge(
              mark: 'コ',
              isFirst: true,
              color: Colors.white,
            ),
          ),
        ),
      );

      expect(find.text('コ'), findsOneWidget);

      // 先取丸枠線が存在すること
      final circleDecorations = tester
          .widgetList<Container>(find.byType(Container))
          .where((container) {
            final decoration = container.decoration;
            return decoration is BoxDecoration &&
                decoration.shape == BoxShape.circle;
          });
      expect(circleDecorations.isNotEmpty, isTrue);
    });

    testWidgets('Normalizes fullwidth cross ✕ to halfwidth cross × correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchPointBadge(
              mark: '✕',
              isFirst: false,
              color: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('×'), findsOneWidget);
    });
  });
}
