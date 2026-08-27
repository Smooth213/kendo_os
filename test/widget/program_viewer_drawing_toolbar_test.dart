import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_controls.dart';
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

  testWidgets(
    'ProgramViewerDrawingToolbar hides shared pen options when canUseSharedPen is false (Viewer Mode)',
    (WidgetTester tester) async {
      Color selectedColor = AppKendoColors.blue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgramViewerDrawingToolbar(
              selectedTool: 'pen',
              activePenColor: AppKendoColors.blue,
              activeIsShared: false,
              canUseSharedPen: false,
              isDark: false,
              onSelectTool: (_) {},
              onSelectPenColor: (color) => selectedColor = color,
              onUndo: () {},
              onClearAll: () {},
            ),
          ),
        ),
      );

      // ペン選択ドロップダウンをタップ
      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();

      // 共有ペンセクションおよび共有ペンオプションが非表示であること
      expect(find.textContaining('共有ペン'), findsNothing);
      expect(
        find.widgetWithText(ProgramViewerPenOption, 'ピンク (共有)'),
        findsNothing,
      );
      expect(
        find.widgetWithText(ProgramViewerPenOption, 'イエロー (共有)'),
        findsNothing,
      );

      // 個人ペンセクションおよび個人ペンオプションが表示されること
      expect(find.textContaining('個人ペン'), findsOneWidget);
      expect(
        find.widgetWithText(ProgramViewerPenOption, 'ブルー (個人)'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ProgramViewerPenOption, 'ブラック (個人)'),
        findsOneWidget,
      );

      // 個人ペン（ブラック）を選択可能であること
      await tester.tap(
        find.widgetWithText(ProgramViewerPenOption, 'ブラック (個人)'),
      );
      await tester.pumpAndSettle();
      expect(selectedColor, equals(AppKendoColors.pureBlack));
    },
  );

  testWidgets(
    'ProgramViewerDrawingToolbar shows shared pen options when canUseSharedPen is true (Operator Mode)',
    (WidgetTester tester) async {
      Color selectedColor = AppKendoColors.pink;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgramViewerDrawingToolbar(
              selectedTool: 'pen',
              activePenColor: AppKendoColors.pink,
              activeIsShared: true,
              canUseSharedPen: true,
              isDark: false,
              onSelectTool: (_) {},
              onSelectPenColor: (color) => selectedColor = color,
              onUndo: () {},
              onClearAll: () {},
            ),
          ),
        ),
      );

      // ペン選択ドロップダウンをタップ
      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();

      // 共有ペンと個人ペンの両方が表示されること
      expect(find.textContaining('共有ペン'), findsOneWidget);
      expect(
        find.widgetWithText(ProgramViewerPenOption, 'ピンク (共有)'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ProgramViewerPenOption, 'イエロー (共有)'),
        findsOneWidget,
      );
      expect(find.textContaining('個人ペン'), findsOneWidget);
      expect(
        find.widgetWithText(ProgramViewerPenOption, 'ブルー (個人)'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ProgramViewerPenOption, 'ブラック (個人)'),
        findsOneWidget,
      );

      // 共有ペン（イエロー）を選択可能であること
      await tester.tap(
        find.widgetWithText(ProgramViewerPenOption, 'イエロー (共有)'),
      );
      await tester.pumpAndSettle();
      expect(selectedColor, equals(const Color(0xFFCA8A04)));
    },
  );
}
