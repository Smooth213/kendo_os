import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_group_match_card.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_individual_player_card.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_match_list_tile_card.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_team_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../../../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const kataMatch = MatchModel(
    id: 'viewer_kata_1',
    tournamentId: 'tourney_v_1',
    matchType: '形・基本判定',
    status: 'finished',
    redName: '道上剣友会:皿田 脩人・塚本 大道',
    whiteName: '友道館:相手 太郎・相手 次郎',
    redScore: 3,
    whiteScore: 0,
    note: '第1試合場 (第1試合)',
    groupName: 'kata_team_group_1',
    order: 1.0,
    rule: MatchRule(isKataMatch: true, teamName: '道上剣友会'),
  );

  group('[Widget] 観客席（Viewer）剣道形 個人戦アコーディオン表示テスト', () {
    testWidgets(
      'ViewerTeamCardにおいて剣道形が団体戦グループではなく個人戦（ViewerIndividualPlayerCard）に分類され正しく描画されること',
      (tester) async {
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              matchListProvider.overrideWith((ref) => [kataMatch]),
            ],
            child: createTestApp(
              Theme(
                data: ThemeData.light().copyWith(extensions: [themeColors]),
                child: const Scaffold(
                  body: SingleChildScrollView(
                    child: ViewerTeamCard(
                      teamName: '道上剣友会',
                      teamMatchesList: [kataMatch],
                      ownTeams: ['道上剣友会'],
                      sanitizedQuery: '',
                      matchedMatchIds: {},
                      matchedGroupNames: {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. 団体戦カード（ViewerGroupMatchCard）は生成されず、ViewerIndividualPlayerCard が生成されること
        expect(find.byType(ViewerGroupMatchCard), findsNothing);
        expect(find.byType(ViewerIndividualPlayerCard), findsOneWidget);

        // 2. 形・武道アイコンおよび「形・基本判定」セクションヘッダーが表示されること
        expect(find.byIcon(Icons.sports_martial_arts), findsOneWidget);
        expect(find.text('形・基本判定'), findsOneWidget);

        // 3. ペア名「皿田 脩人・塚本 大道」が表示されること
        expect(
          find.textContaining('皿田 脩人・塚本 大道', findRichText: true),
          findsWidgets,
        );

        // 4. 通算戦績および全試合終了サマリー（本数表記なし）が表示されること
        expect(find.text('🏁 全試合終了: 通算 1勝 0敗 0分'), findsOneWidget);
        expect(find.textContaining('3本'), findsNothing);

        // 5. アコーディオンを展開して ViewerMatchListTileCard の描画を確認
        await tester.tap(find.byType(ExpansionTile));
        await tester.pumpAndSettle();

        expect(find.byType(ViewerMatchListTileCard), findsOneWidget);
        expect(find.text('道上剣友会'), findsWidgets);
        expect(find.text('友道館'), findsWidgets);
      },
    );
  });
}
