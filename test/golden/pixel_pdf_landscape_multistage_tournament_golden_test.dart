import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_export_bar.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] A4横向き（Landscape）多段トーナメント公式記録プレビュー 視覚完全性テスト', () {
    testWidgets('A4横向き比率（1123x794）において公式記録プレビューのコントロールバーとレイアウトが検証されること', (
      WidgetTester tester,
    ) async {
      // A4 Landscape at ~96 DPI: 1123 x 794
      tester.view.physicalSize = const Size(1123, 794);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: Column(
                children: [
                  OfficialRecordExportBar(
                    isExporting: false,
                    exportingType: null,
                    isDark: false,
                    hasMultipleCategories: true,
                    exportScope: OfficialRecordExportScope.all,
                    onScopeChanged: (_) {},
                    onPdfPressed: () {},
                    onCsvPressed: () {},
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'A4横向き公式記録多段トーナメント記録表プレビュー',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(OfficialRecordExportBar), findsOneWidget);
      expect(find.text('A4横向き公式記録多段トーナメント記録表プレビュー'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
