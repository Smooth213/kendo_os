import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/court_status/team_status_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_group_match_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyGroupMatches = [
    const MatchModel(
      id: 'm1_senpo',
      groupName: 'group_test_main',
      matchType: '先鋒',
      redName: '道上: 皿田',
      whiteName: '相手11: 選手A',
      redScore: 1,
      whiteScore: 0,
      status: 'in_progress',
      order: 1.0,
      category: '小学生の部',
      note: '【錬成】第1試合場, 3試合目 (このあと休憩)',
    ),
    const MatchModel(
      id: 'm1_taisho',
      groupName: 'group_test_main',
      matchType: '大将',
      redName: '道上: 久安',
      whiteName: '相手11: 選手B',
      redScore: 0,
      whiteScore: 0,
      status: 'waiting',
      order: 2.0,
      category: '小学生の部',
      note: '【錬成】第1試合場, 3試合目',
    ),
  ];

  group('🏰 大会ホーム＆チーム試合状況 5段構造レイアウト永続保持テスト要塞', () {
    testWidgets('1. 大会ホーム（管理画面）で5段構造レイアウトが完全に維持されていること', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          child: createTestApp(
            Theme(
              data: ThemeData.light().copyWith(extensions: [themeColors]),
              child: Scaffold(
                body: TimelineMatchGroupCard(
                  groupId: 'group_test_main',
                  groupList: dummyGroupMatches,
                  label: '道上 vs 相手11',
                  groupComments: const [],
                  categoryName: '小学生の部',
                  teamName: '道上',
                  isReadOnlyUI: false,
                  canManageTournamentUI: true,
                  isDark: false,
                  tournamentId: 't_1',
                  ownTeams: const ['道上'],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1段目: 属性プレフィックスバッジ + ステータスバッジ（LIVE）
      expect(find.text('【錬成】'), findsWidgets);
      expect(find.byType(MatchStatusBadge), findsOneWidget);
      expect(find.text('試合中 (LIVE)'), findsOneWidget);

      // 2段目: 対戦カード見出し
      expect(find.text('道上 vs 相手11'), findsOneWidget);

      // 3段目: コート・進行・メモ
      expect(find.textContaining('第1試合場'), findsOneWidget);

      // 4段目: アクションボタン（スコア、ルール）
      expect(find.text('スコア'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      // 5段目: スコアサマリー（(0)）
      expect(find.text('(0)'), findsWidgets);
    });

    testWidgets('2. 大会ホーム（観客席ビュアー）で5段構造レイアウトが維持され、管理ボタンが非表示であること', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          child: createTestApp(
            Theme(
              data: ThemeData.light().copyWith(extensions: [themeColors]),
              child: Scaffold(
                body: ViewerGroupMatchCard(
                  groupKey: 'group_test_main',
                  groupList: dummyGroupMatches,
                  matchLabel: '道上 vs 相手11',
                  groupComments: const [],
                  ownTeams: const ['道上'],
                  sanitizedQuery: '',
                  matchedMatchIds: const {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1段目: ステータスバッジ
      expect(find.text('試合中 (LIVE)'), findsOneWidget);

      // 2段目: 対戦カード名
      expect(find.text('道上 vs 相手11'), findsOneWidget);

      // 3段目: コート情報
      expect(find.textContaining('第1試合場'), findsOneWidget);

      // 4段目: 観客用スコアボタン
      expect(find.text('スコア'), findsOneWidget);

      // 管理ボタン（簡易入力など）が絶対に表示されないこと
      expect(find.text('簡易入力'), findsNothing);
    });

    testWidgets('3. チーム試合状況カードで5段構造レイアウトおよび重複排除・通算集計が完全に維持されていること', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      final dummyStatus = TeamProgressStatus(
        teamName: '道上剣友会',
        categoryName: '小学生の部',
        tournamentId: 't1',
        hasLiveMatch: true,
        inProgressMatch: dummyGroupMatches.first,
        currentCourtName: '第1試合場, 3試合目 (このあと休憩)',
        matchupTitle: '【錬成】団体戦：道上剣友会 vs 相手11',
        matches: dummyGroupMatches,
        completedCount: 1, // 本日3対戦中1対戦終了
        totalCount: 3, // 本日全3対戦
        totalWins: 1, // 団体戦1勝
        totalLosses: 0,
        totalDraws: 0,
        totalPoints: 2,
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

      // 2段目: 【錬成】バッジ（画面内で1箇所のみ表示・重複排除保証）
      expect(find.text('【錬成】'), findsOneWidget);

      // 3段目: 対戦カード見出し（【錬成】が除去されたheadline表示）
      expect(find.text('団体戦：道上剣友会 vs 相手11'), findsOneWidget);

      // 4段目: コート情報（編集アイコン付き）
      expect(find.textContaining('第1試合場'), findsOneWidget);

      // 5段目: ポジション別スコア詳細
      expect(find.text('【先鋒】'), findsOneWidget);
      expect(find.text('皿田'), findsOneWidget);

      // 最下部: 通算戦績（団体戦1勝=1勝） & 進行バー（全対戦カウント 1/3 試合）
      expect(find.text('1勝 0敗 0分'), findsOneWidget);
      expect(find.text('(2本)'), findsOneWidget);
      expect(find.text('進行: 1/3 試合'), findsOneWidget);
    });
  });
}
