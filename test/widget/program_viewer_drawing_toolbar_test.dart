import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_drawing_toolbar.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

void main() {
  testWidgets(
    'ProgramViewerDrawingToolbar renders tools and handles callbacks',
    (WidgetTester tester) async {
      String selectedTool = 'pen';
      Color penColor = AppKendoColors.pink;
      bool undoCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgramViewerDrawingToolbar(
              selectedTool: selectedTool,
              activePenColor: penColor,
              activeIsShared: true,
              canUseSharedPen: true,
              isDark: false,
              onSelectTool: (tool) => selectedTool = tool,
              onSelectPenColor: (color) => penColor = color,
              onUndo: () => undoCalled = true,
              onClearAll: () {},
            ),
          ),
        ),
      );

      // Verify pen button and undo button are rendered
      expect(find.byIcon(Icons.edit), findsWidgets);
      expect(find.byIcon(Icons.border_color), findsOneWidget);
      expect(find.byIcon(Icons.cleaning_services), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);

      // Tap undo
      await tester.tap(find.byIcon(Icons.undo));
      expect(undoCalled, isTrue);
    },
  );
}
