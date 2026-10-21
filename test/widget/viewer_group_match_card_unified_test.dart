import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_group_match_card.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_group_match_score_summary.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('[Widget] ViewerGroupMatchCard 統合検証', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('ViewerGroupMatchCardにおいて グループタイトルおよび試合一覧が正しく描画されること', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final prefs = await SharedPreferences.getInstance();

      final match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: 'team',
        order: 1,
        redName: 'チームA: 先鋒',
        whiteName: 'チームB: 先鋒',
        groupName: 'Aグループ',
        status: 'in_progress',
        note: '1回戦',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: SingleChildScrollView(
                child: ViewerGroupMatchCard(
                  groupKey: 'Aグループ',
                  groupList: [match],
                  matchLabel: '団体戦',
                  ownTeams: const ['チームA'],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('チームA'), findsOneWidget);
      expect(find.text('チームB'), findsOneWidget);
      expect(find.text('試合中 (LIVE)'), findsOneWidget);
      expect(find.text('1回戦'), findsOneWidget);
    });

    testWidgets('ViewerGroupMatchScoreSummaryにおいて チーム名およびスコアが正しく描画されること', (
      tester,
    ) async {
      const match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: '先鋒',
        redName: '練馬道場 : 山田',
        whiteName: '杉並道場 : 田中',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ViewerGroupMatchScoreSummary(
              groupList: [match],
              rTeam: '練馬道場',
              wTeam: '杉並道場',
              ownTeams: ['練馬道場'],
              titleColor: Colors.black,
            ),
          ),
        ),
      );

      expect(find.text('練馬道場'), findsOneWidget);
      expect(find.text('杉並道場'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // 1勝
    });
  });
}
