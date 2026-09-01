import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_individual_player_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_individual_player_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_individual_player_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testLiveMatch = MatchModel(
    id: 'm_indiv_live',
    tournamentId: 'tourney_1',
    matchType: '個人戦',
    status: 'in_progress',
    redName: '道上:皿田 脩人',
    whiteName: 'ライバル道場:相手 太郎',
    redScore: 1,
    whiteScore: 0,
    note: '【錬成】第1試合場 (2回戦・第4試合)',
    groupName: '',
    order: 2.0,
  );

  const testWaitingMatch = MatchModel(
    id: 'm_indiv_wait',
    tournamentId: 'tourney_1',
    matchType: '個人戦',
    status: 'pending',
    redName: '道上:皿田 脩人',
    whiteName: '強豪館:相手 次郎',
    redScore: 0,
    whiteScore: 0,
    note: '【錬成】第1試合場 (準決勝)',
    groupName: '',
    order: 3.0,
  );

  const testFinishedMatch = MatchModel(
    id: 'm_indiv_fin',
    tournamentId: 'tourney_1',
    matchType: '個人戦',
    status: 'finished',
    redName: '道上:皿田 脩人',
    whiteName: '初戦道場:相手 三郎',
    redScore: 2,
    whiteScore: 0,
    note: '【錬成】第1試合場 (1回戦・第1試合)',
    groupName: '',
    order: 1.0,
  );

  group('🥋 個人戦カード 5段構造レイアウト ＆ 統一バッジ 永続保持テスト要塞', () {
    testWidgets(
      '1. 管理画面（TimelineIndividualPlayerCard）で試合中（LIVE）の5段構造が正しく描画されること',
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
                  body: TimelineIndividualPlayerCard(
                    playerName: '皿田 脩人',
                    playerMatches: [
                      testFinishedMatch,
                      testLiveMatch,
                      testWaitingMatch,
                    ],
                    playerComments: [],
                    categoryName: '小学生の部',
                    teamName: '道上',
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
        );
        await tester.pumpAndSettle();

        // 1段目: 属性バッジ（【錬成】） + MatchStatusBadge（LIVE）
        expect(find.text('【錬成】'), findsWidgets);
        expect(find.byType(MatchStatusBadge), findsOneWidget);
        expect(find.text('試合中 (LIVE)'), findsOneWidget);

        // 2段目: マーク（CircleAvatar: '皿'） + 選手名（皿田 脩人）
        expect(find.text('皿'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains('皿田 脩人'),
          ),
          findsOneWidget,
        );

        // 3段目: コート情報（第1試合場）
        expect(find.textContaining('第1試合場'), findsWidgets);

        // 4段目: 進行中状態（🔴 試合中: vs 相手 太郎（ライバル道場））
        expect(find.textContaining('🔴 試合中: vs 相手 太郎（ライバル道場）'), findsOneWidget);
        expect(find.text('(1 - 0)'), findsOneWidget);
      },
    );

    testWidgets('2. 待機中（pendingのみ）の場合、4段目に「⏳ 次の出番」が表示されること', (tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          child: createTestApp(
            Theme(
              data: ThemeData.light().copyWith(extensions: [themeColors]),
              child: const Scaffold(
                body: TimelineIndividualPlayerHeader(
                  playerName: '皿田 脩人',
                  playerMatches: [testWaitingMatch],
                  isDark: false,
                  isReadOnlyUI: false,
                  titleColor: Colors.black,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1段目: 待機中バッジ
      expect(find.text('⏳ 待機中'), findsOneWidget);

      // 4段目: 次の出番
      expect(find.textContaining('⏳ 次の出番: vs 相手 次郎（強豪館）'), findsOneWidget);
    });

    testWidgets('3. 全試合終了時、1段目に「終了」バッジ、4段目に「🏁 全試合終了: 通算 1勝 0敗」が表示されること', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          child: createTestApp(
            Theme(
              data: ThemeData.light().copyWith(extensions: [themeColors]),
              child: const Scaffold(
                body: TimelineIndividualPlayerHeader(
                  playerName: '皿田 脩人',
                  playerMatches: [testFinishedMatch],
                  isDark: false,
                  isReadOnlyUI: false,
                  titleColor: Colors.black,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1段目: 終了バッジ
      expect(find.text('終了'), findsOneWidget);

      // 4段目: 全試合終了サマリー
      expect(find.textContaining('🏁 全試合終了: 通算 1勝 0敗 0分 (2本)'), findsOneWidget);
    });

    testWidgets(
      '4. 観客席画面（ViewerIndividualPlayerCard）でも同一の5段構造とMatchStatusBadgeが描画されること',
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
                  body: ViewerIndividualPlayerCard(
                    playerName: '皿田 脩人',
                    playerMatches: [testLiveMatch],
                    matchLabel: '個人戦',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1段目: MatchStatusBadge（LIVE）
        expect(find.text('試合中 (LIVE)'), findsOneWidget);

        // 2段目: 選手名
        expect(
          find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains('皿田 脩人'),
          ),
          findsOneWidget,
        );

        // 4段目: 試合中対戦相手
        expect(find.textContaining('🔴 試合中: vs 相手 太郎（ライバル道場）'), findsOneWidget);
      },
    );
  });
}
