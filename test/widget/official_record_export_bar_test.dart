import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_export_bar.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';

void main() {
  group('[Widget] OfficialRecordExportBar ウィジェットテスト', () {
    testWidgets('all 3 export ボタン一覧 and handles callbacksが正しく描画されること', (
      WidgetTester tester,
    ) async {
      bool pdfTapped = false;
      bool imageTapped = false;
      bool csvTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfficialRecordExportBar(
              isExporting: false,
              onPdfPressed: () => pdfTapped = true,
              onImagePressed: () => imageTapped = true,
              onCsvPressed: () => csvTapped = true,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('画像'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);

      await tester.tap(find.text('PDF'));
      expect(pdfTapped, isTrue);

      await tester.tap(find.text('画像'));
      expect(imageTapped, isTrue);

      await tester.tap(find.text('CSV'));
      expect(csvTapped, isTrue);
    });

    testWidgets('Disables buttons when isExporting is trueであること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfficialRecordExportBar(isExporting: true, isDark: true),
          ),
        ),
      );

      final pdfButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'PDF'),
      );
      expect(pdfButton.enabled, isFalse);
    });

    testWidgets('Hides toggle when hasMultipleCategories is falseであること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfficialRecordExportBar(
              isExporting: false,
              isDark: false,
              hasMultipleCategories: false,
            ),
          ),
        ),
      );

      expect(find.text('全カテゴリを一括出力'), findsNothing);
      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('【AppSwitch】スイッチまたはラベルのタップ時にラベルが切り替わること', (
      WidgetTester tester,
    ) async {
      OfficialRecordExportScope? selectedScope;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: OfficialRecordExportBar(
                  isExporting: false,
                  isDark: false,
                  hasMultipleCategories: true,
                  exportScope:
                      selectedScope ?? OfficialRecordExportScope.current,
                  onScopeChanged: (scope) {
                    setState(() {
                      selectedScope = scope;
                    });
                  },
                ),
              ),
            );
          },
        ),
      );

      // 初期表示確認: スイッチOFF
      expect(find.text('全カテゴリを一括出力'), findsOneWidget);
      expect(find.byType(AppSwitch), findsOneWidget);
      final switchWidgetInitial = tester.widget<AppSwitch>(
        find.byType(AppSwitch),
      );
      expect(switchWidgetInitial.value, isFalse);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('画像'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);

      // ラベルまたはスイッチをタップ
      await tester.tap(find.text('全カテゴリを一括出力'));
      await tester.pumpAndSettle();

      expect(selectedScope, OfficialRecordExportScope.all);
      final switchWidgetActive = tester.widget<AppSwitch>(
        find.byType(AppSwitch),
      );
      expect(switchWidgetActive.value, isTrue);
      expect(find.text('PDF（全）'), findsOneWidget);
      expect(find.text('画像（全）'), findsOneWidget);
      expect(find.text('CSV（全）'), findsOneWidget);

      // スイッチ自体をタップして解除
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();

      expect(selectedScope, OfficialRecordExportScope.current);
      final switchWidgetInactive = tester.widget<AppSwitch>(
        find.byType(AppSwitch),
      );
      expect(switchWidgetInactive.value, isFalse);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('画像'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);
    });
  });
}
