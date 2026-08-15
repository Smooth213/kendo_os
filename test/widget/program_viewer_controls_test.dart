import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_controls.dart';

void main() {
  group('🛡️ ProgramViewerControls Widget Tests', () {
    testWidgets('Renders tool button and triggers onTap', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgramViewerToolButton(
              tool: 'pen',
              icon: Icons.edit,
              tooltip: 'ペンツール',
              isSelected: true,
              isDark: false,
              activeColor: Colors.blue,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.edit), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit));
      expect(tapped, isTrue);
    });

    testWidgets('Renders pen option button and triggers onTap', (
      WidgetTester tester,
    ) async {
      bool optionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                ProgramViewerPenOption(
                  color: Colors.red,
                  label: 'レッド',
                  isSelected: true,
                  onTap: () => optionTapped = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('レッド'), findsOneWidget);

      await tester.tap(find.text('レッド'));
      expect(optionTapped, isTrue);
    });
  });
}
