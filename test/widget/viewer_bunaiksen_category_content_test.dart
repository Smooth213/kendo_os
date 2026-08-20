import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_category_content.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_official_record_screen.dart';
import 'package:kendo_os/features/viewer/services/viewer_bunaiksen_export_service.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ ViewerBunaiksenCategoryContent Widget Tests', () {
    testWidgets('Renders PDF and Share action buttons and match card', (
      tester,
    ) async {
      final matches = [
        MatchModel(
          id: 'test_m1',
          matchType: '先鋒',
          redName: '東京道場:山田 太郎',
          whiteName: '大阪道場:佐藤 次郎',
          status: 'finished',
          redScore: 2,
          whiteScore: 0,
          order: 1,
        ),
      ];

      final themeColors = AppThemeColors.ofMode(
        isDark: false,
        mode: 'bunaiksen_viewer',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ViewerBunaiksenCategoryContent(
                    category: '一般の部',
                    groupsMap: {'group1': matches},
                    cardColor: Colors.white,
                    themeColors: themeColors,
                    isDark: false,
                    isExporting: false,
                    isExportingController: ref.watch(
                      isExportingProvider.notifier,
                    ),
                    tDate: '2026年08月20日',
                    exportService: const ViewerBunaiksenExportService(),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('PDF印刷'), findsOneWidget);
      expect(find.text('画像シェア'), findsOneWidget);
      expect(find.text('東京道場 vs 大阪道場'), findsOneWidget);
    });
  });
}
