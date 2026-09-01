import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_league_team_match_header.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_league_matchup_tile.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testBoutLive = MatchModel(
    id: 'bout_1',
    tournamentId: 'tourney_1',
    matchType: 'リーグ団体戦',
    status: 'in_progress',
    redName: '他チームA:先鋒',
    whiteName: '他チームB:先鋒',
    redScore: 1,
    whiteScore: 0,
    note: '【錬成】第1試合場',
    groupName: 'Aリーグ',
    order: 1.0,
  );

  group('🥋 リーグ戦ヘッダー 統一バッジ ＆ 26pxボタン 永続保持テスト要塞', () {
    testWidgets(
      '1. 管理画面（TimelineLeagueTeamMatchHeader）でMatchStatusBadgeと26pxボタンが描画されること',
      (tester) async {
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: createTestApp(
              Theme(
                data: ThemeData.light().copyWith(extensions: [themeColors]),
                child: Scaffold(
                  body: TimelineLeagueTeamMatchHeader(
                    bouts: const [testBoutLive],
                    isReadOnlyUI: false,
                    boutsAllFinished: false,
                    boutsInProgress: true,
                    t1: '他チームA',
                    t2: '他チームB',
                    ownTeams: const ['自道場'],
                    mTitleColor: Colors.black,
                    isDark: false,
                    onShowSummaryInputDialog: (ctx, ref, b) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 属性バッジ + MatchStatusBadge
        expect(find.text('【錬成】'), findsOneWidget);
        expect(find.byType(MatchStatusBadge), findsOneWidget);
        expect(find.text('試合中 (LIVE)'), findsOneWidget);

        // ボタン（スコア、簡易入力）
        expect(find.text('スコア'), findsOneWidget);
        expect(find.text('簡易入力'), findsOneWidget);
      },
    );

    testWidgets(
      '2. 観客席画面（ViewerLeagueMatchupTile）でMatchStatusBadgeとスコアボタンが描画されること',
      (tester) async {
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: createTestApp(
              Theme(
                data: ThemeData.light().copyWith(extensions: [themeColors]),
                child: const Scaffold(
                  body: ViewerLeagueMatchupTile(
                    matchupName: '他チームA vs 他チームB',
                    bouts: [testBoutLive],
                    ownTeams: ['自道場'],
                    isDark: false,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // MatchStatusBadge
        expect(find.byType(MatchStatusBadge), findsOneWidget);
        expect(find.text('試合中 (LIVE)'), findsOneWidget);

        // スコアボタン
        expect(find.text('スコア'), findsOneWidget);
      },
    );
  });
}
