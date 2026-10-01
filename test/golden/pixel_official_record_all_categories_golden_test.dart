import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_export_bar.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_expedition_summary_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 【Golden】公式記録 全カテゴリ一括出力トグル＆要約カード視覚整合性テスト', () {
    final sampleMatches = [
      MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: '個人戦',
        redName: 'チームA: 佐藤',
        whiteName: 'チームB: 鈴木',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
      ),
      MatchModel(
        id: 'm2',
        tournamentId: 't1',
        matchType: '個人戦',
        redName: 'チームA: 田中',
        whiteName: 'チームB: 高橋',
        redScore: 1,
        whiteScore: 1,
        status: 'finished',
      ),
    ];

    testWidgets('全カテゴリ一括出力トグル OFF 状態 (個別カテゴリ出力モード)こと', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
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
                    exportScope: OfficialRecordExportScope.current,
                    onScopeChanged: (_) {},
                    onPdfPressed: () {},
                    onImagePressed: () {},
                    onCsvPressed: () {},
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: OfficialRecordExpeditionSummaryCard(
                          matches: sampleMatches,
                          isDark: false,
                          registeredTeamNames: const {'チームA', 'チームB'},
                          registeredPlayerNames: const {'佐藤', '田中'},
                          initiallyExpanded: true,
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

      expect(find.text('全カテゴリを一括出力'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('画像'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('成績サマリー'), findsOneWidget);
      expect(find.text('詳細分析 ›'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('全カテゴリ一括出力トグル ON 状態 (全カテゴリ一括出力モード: PDF（全）/ 画像（全）/ CSV（全）)こと', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: Column(
                children: [
                  OfficialRecordExportBar(
                    isExporting: false,
                    exportingType: null,
                    isDark: true,
                    hasMultipleCategories: true,
                    exportScope: OfficialRecordExportScope.all,
                    onScopeChanged: (_) {},
                    onPdfPressed: () {},
                    onImagePressed: () {},
                    onCsvPressed: () {},
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: OfficialRecordExpeditionSummaryCard(
                          matches: sampleMatches,
                          isDark: true,
                          registeredTeamNames: const {'チームA', 'チームB'},
                          registeredPlayerNames: const {'佐藤', '田中'},
                          initiallyExpanded: true,
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

      expect(find.text('全カテゴリを一括出力'), findsOneWidget);
      expect(find.text('PDF（全）'), findsOneWidget);
      expect(find.text('画像（全）'), findsOneWidget);
      expect(find.text('CSV（全）'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
