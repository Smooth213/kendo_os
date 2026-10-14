import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/band/presentation/components/band_share_button.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_list_tile_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_individual_player_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const kataFinishedMatch = MatchModel(
    id: 'm_kata_fin_1',
    tournamentId: 'tourney_kata_1',
    matchType: '形・基本判定',
    status: 'finished',
    redName: '道上剣友会:皿田 脩人・塚本 大道',
    whiteName: '友道館:相手 太郎・相手 次郎',
    redScore: 3,
    whiteScore: 0,
    note: '第2試合場 (第2試合)',
    groupName: 'group_kata_1',
    order: 1.0,
    rule: MatchRule(isKataMatch: true, teamName: '道上剣友会'),
  );

  group('[Widget] 剣道形 個人戦アコーディオンUI 永続保証テスト', () {
    testWidgets('剣道形がペア単位のアコーディオンとして個人戦形式で描画され、本数表記なし・BAND/スコアボタンが正しく備わること', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionProvider.overrideWithValue(
              const PermissionState(
                canManageTournament: true,
                isReadOnly: false,
              ),
            ),
            matchListProvider.overrideWith((ref) => [kataFinishedMatch]),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: createTestApp(
            Theme(
              data: ThemeData.light().copyWith(extensions: [themeColors]),
              child: const Scaffold(
                body: SingleChildScrollView(
                  child: TimelineIndividualPlayerCard(
                    playerName: '皿田 脩人・塚本 大道',
                    playerMatches: [kataFinishedMatch],
                    playerComments: [],
                    categoryName: '小学生低学年の部',
                    teamName: '道上剣友会',
                    isReadOnlyUI: false,
                    isDark: false,
                    permissions: PermissionState(
                      canManageTournament: true,
                      isReadOnly: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. ヘッダーの丸アバター頭文字「皿」
      expect(find.text('皿'), findsOneWidget);

      // 2. ペア名「皿田 脩人・塚本 大道」が表示されること
      expect(
        find.textContaining('皿田 脩人・塚本 大道', findRichText: true),
        findsWidgets,
      );

      // 3. 通算戦績「（全1試合 • 1勝0敗）」が表示されること
      expect(
        find.textContaining('全1試合 • 1勝0敗', findRichText: true),
        findsOneWidget,
      );

      // 4. コート情報「第2試合場 (第2試合)」が表示されること
      expect(find.textContaining('第2試合場 (第2試合)'), findsOneWidget);

      // 5. 終了バッジが存在すること
      expect(find.byType(MatchStatusBadge), findsWidgets);

      // 6. 全試合終了サマリーで「本数 (〇本)」が付かず、「🏁 全試合終了: 通算 1勝 0敗 0分」となること
      expect(find.text('🏁 全試合終了: 通算 1勝 0敗 0分'), findsOneWidget);
      expect(find.textContaining('3本'), findsNothing);

      // 7. アコーディオンを展開
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // 8. 展開された MatchListTileCard が個人戦スタイルで描画されること
      expect(find.byType(MatchListTileCard), findsOneWidget);
      expect(find.text('道上剣友会'), findsWidgets);
      expect(find.text('友道館'), findsWidgets);

      // 9. BAND共有ボタン・スコアボタンが存在すること
      expect(find.byType(BandShareButton), findsOneWidget);
      expect(find.text('スコア'), findsOneWidget);
    });
  });
}
