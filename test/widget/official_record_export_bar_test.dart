import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_export_bar.dart';

void main() {
  group('🛡️ OfficialRecordExportBar Widget Tests', () {
    testWidgets('Renders all 3 export buttons and handles callbacks', (
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

    testWidgets('Disables buttons when isExporting is true', (
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
  });
}
