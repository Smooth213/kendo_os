import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/court_status/team_status_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🥋 TeamStatusCard 5-Tier Layout Tests (チーム試合状況カード5段構造テスト)', () {
    testWidgets('1段目〜5段目の要素およびMatchStatusBadgeが正しく描画されること', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      final dummyLiveMatch = MatchModel(
        id: 'm_live_1',
        tournamentId: 't1',
        matchType: '先鋒',
        redName: '道上:皿田',
        whiteName: '相手11:選手',
        redScore: 1,
        whiteScore: 0,
        status: 'in_progress',
        order: 1,
        matchScene: 'renseikai',
        note: 'このあと休憩',
      );

      final dummyStatus = TeamProgressStatus(
        teamName: '道上剣友会',
        categoryName: '小学生の部',
        tournamentId: 't1',
        hasLiveMatch: true,
        inProgressMatch: dummyLiveMatch,
        currentCourtName: '第1試合場, 3試合目 (このあと休憩)',
        matchupTitle: '【錬成】団体戦：道上剣友会 vs 相手11',
        matches: [dummyLiveMatch],
        completedCount: 0,
        totalCount: 3,
        totalWins: 2,
        totalLosses: 1,
        totalDraws: 0,
      );

      await tester.pumpWidget(
        createTestApp(
          Theme(
            data: ThemeData.light().copyWith(extensions: [themeColors]),
            child: Scaffold(
              body: TeamStatusCard(status: dummyStatus, isDark: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1段目: チーム名・カテゴリ名・ステータスバッジ
      expect(find.text('道上剣友会'), findsWidgets);
      expect(find.text('小学生の部'), findsOneWidget);
      expect(find.byType(MatchStatusBadge), findsOneWidget);
      expect(find.text('試合中 (LIVE)'), findsOneWidget);

      // 2段目: 【錬成】バッジ（画面内で1箇所のみ表示）
      expect(find.text('【錬成】'), findsOneWidget);

      // 3段目: 団体戦：道上剣友会 vs 相手11（【錬成】が除去されていること）
      expect(find.text('団体戦：道上剣友会 vs 相手11'), findsOneWidget);

      // 4段目: コート情報
      expect(find.textContaining('第1試合場'), findsOneWidget);

      // 5段目: スコア・対戦選手情報
      expect(find.text('【先鋒】'), findsOneWidget);
      expect(find.text('皿田'), findsOneWidget);
      expect(find.text('選手'), findsOneWidget);
    });

    testWidgets('全試合終了時は「🏁 全試合終了」バッジが描画されること', (WidgetTester tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      final dummyFinishedMatch = MatchModel(
        id: 'm_fin_1',
        tournamentId: 't1',
        matchType: '大将',
        redName: '道上:久安',
        whiteName: '相手11:大将',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
        order: 3,
      );

      final dummyStatus = TeamProgressStatus(
        teamName: '道上剣友会',
        categoryName: '小学生の部',
        tournamentId: 't1',
        hasLiveMatch: false,
        lastFinishedMatch: dummyFinishedMatch,
        matchupTitle: '道上剣友会 vs 相手11',
        matches: [dummyFinishedMatch],
        completedCount: 3,
        totalCount: 3,
      );

      await tester.pumpWidget(
        createTestApp(
          Theme(
            data: ThemeData.light().copyWith(extensions: [themeColors]),
            child: Scaffold(
              body: TeamStatusCard(status: dummyStatus, isDark: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🏁 全試合終了'), findsOneWidget);
      expect(find.text('試合中 (LIVE)'), findsNothing);
    });

    testWidgets('途中のカード終了（まだ全試合未完）の場合は「終了」バッジが描画されること', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      final dummyFinishedMatch = MatchModel(
        id: 'm_fin_1',
        tournamentId: 't1',
        matchType: '先鋒',
        redName: '道上:皿田',
        whiteName: '相手11:先鋒',
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
        order: 1,
      );

      final dummyStatus = TeamProgressStatus(
        teamName: '道上剣友会',
        categoryName: '小学生の部',
        tournamentId: 't1',
        hasLiveMatch: false,
        lastFinishedMatch: dummyFinishedMatch,
        matchupTitle: '道上剣友会 vs 相手11',
        matches: [dummyFinishedMatch],
        completedCount: 1,
        totalCount: 3,
      );

      await tester.pumpWidget(
        createTestApp(
          Theme(
            data: ThemeData.light().copyWith(extensions: [themeColors]),
            child: Scaffold(
              body: TeamStatusCard(status: dummyStatus, isDark: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('終了'), findsOneWidget);
      expect(find.text('🏁 全試合終了'), findsNothing);
    });
  });
}
