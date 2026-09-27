import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_summary_toolbar.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🥋 【Widget】ExpeditionSummaryToolbar 表示・インタラクションテスト', () {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

    final summaryData = ExpeditionSummaryData(
      teamsList: const ['チームA'],
      renseikaiWin: 2,
      renseikaiLoss: 1,
      renseikaiDraw: 0,
      honsenWin: 1,
      honsenLoss: 0,
      honsenDraw: 1,
      moushiawaseWin: 0,
      moushiawaseLoss: 0,
      moushiawaseDraw: 0,
      teamMen: 4,
      teamKote: 2,
      teamDou: 1,
      teamTsuki: 0,
      teamHansoku: 1,
      teamOther: 0,
      teamTotalScored: 8,
      teamTotalConceded: 4,
      playerStatsMap: const {},
      cardResults: const [],
    );

    testWidgets('1. 詳細分析ボタンが表示され、teamsListが1個以下のときはチームドロップダウンが非表示であること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: ExpeditionSummaryToolbar(
              isDark: false,
              themeColors: themeColors,
              selectedSummaryTeam: 'チームA',
              teamsList: const ['チームA'],
              summaryData: summaryData,
              onTeamChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('詳細分析 ›'), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
      // ドロップダウンは表示されない
      expect(find.byType(DropdownButton<String>), findsNothing);
    });

    testWidgets('2. teamsListが2個以上のときドロップダウンが表示され、選択変更時にonTeamChangedが発火すること', (
      tester,
    ) async {
      String? changedTeam;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: ExpeditionSummaryToolbar(
              isDark: false,
              themeColors: themeColors,
              selectedSummaryTeam: '全体',
              teamsList: const ['チームA', 'チームB'],
              summaryData: summaryData,
              onTeamChanged: (val) {
                changedTeam = val;
              },
            ),
          ),
        ),
      );

      expect(find.byType(DropdownButton<String>), findsOneWidget);

      // ドロップダウンをタップして開く
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // 'チームA' をタップ
      final itemFinder = find.text('チームA').last;
      await tester.tap(itemFinder);
      await tester.pumpAndSettle();

      expect(changedTeam, 'チームA');
    });
  });
}
