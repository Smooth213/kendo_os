import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/viewer/components/viewer_kachinuki_record_card.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('[Widget] ViewerTeamAndKachinukiCards 統合検証', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'ViewerKachinukiRecordCardにおいて チームタイトルとCustomPaintキャンバスが正しく描画されること',
      (WidgetTester tester) async {
        final match = MatchModel(
          id: 'k1',
          redName: '赤チーム: 山田',
          whiteName: '白チーム: 佐藤',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          matchType: '勝ち抜き戦',
          isKachinuki: true,
        );

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'bunaiksen_viewer',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData(extensions: [themeColors]),
              home: Scaffold(
                body: ViewerKachinukiRecordCard(
                  matches: [match],
                  isDark: false,
                ),
              ),
            ),
          ),
        );

        expect(find.text('勝ち抜き戦：赤チーム vs 白チーム'), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      },
    );

    testWidgets('ViewerMatchListTileCardにおいて チーム名と選手名が正しく描画されること', (
      WidgetTester tester,
    ) async {
      const sampleMatch = MatchModel(
        id: 'test_viewer_match_1',
        tournamentId: 'tour_1',
        matchType: '個人戦',
        redName: 'チームA: 山田',
        whiteName: 'チームB: 佐藤',
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
        order: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchListProvider.overrideWith((ref) => [sampleMatch]),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: const Scaffold(
              body: ViewerMatchListTileCard(initialMatch: sampleMatch),
            ),
          ),
        ),
      );

      expect(find.text('チームA'), findsOneWidget);
      expect(find.text('チームB'), findsOneWidget);
      expect(find.text('山田'), findsOneWidget);
      expect(find.text('佐藤'), findsOneWidget);
      expect(find.text('終了'), findsOneWidget);
    });

    testWidgets('ViewerTeamCardにおいて チームヘッダーおよび子カードが正しく描画されること', (tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final prefs = await SharedPreferences.getInstance();

      final match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: 'team',
        order: 1,
        redName: 'チーム東京: 先鋒',
        whiteName: 'チーム大阪: 先鋒',
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
                child: ViewerTeamCard(
                  teamName: 'チーム東京',
                  teamMatchesList: [match],
                  ownTeams: const ['チーム東京'],
                  sanitizedQuery: '',
                  matchedMatchIds: const {},
                  matchedGroupNames: const {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('チーム東京'), findsWidgets);
      expect(find.text('試合中 (LIVE)'), findsOneWidget);
    });
  });
}
