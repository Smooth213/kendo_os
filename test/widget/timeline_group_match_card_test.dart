import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_group_match_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testMatches = [
    MatchModel(
      id: 'match_1',
      tournamentId: 't_1',
      matchType: '先鋒',
      redName: '道上:選手A',
      whiteName: '相手11:選手B',
      groupName: '相手11 vs 道上',
      note: '第1試合場, 3試合目',
      status: 'in_progress',
      order: 1,
    ),
    MatchModel(
      id: 'match_2',
      tournamentId: 't_1',
      matchType: '大将',
      redName: '道上:選手C',
      whiteName: '相手11:選手D',
      groupName: '相手11 vs 道上',
      note: '第1試合場, 3試合目',
      status: 'waiting',
      order: 2,
    ),
  ];

  group('🥋 TimelineMatchGroupCard 5-Tier Header Tests (親アコーディオン5段構造テスト)', () {
    testWidgets('団体戦親カードで1段目〜5段目の要素が正しく配置・描画されること', (
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
                  groupId: 'group_test_1',
                  groupList: testMatches,
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

      // 1段目: ステータスバッジ（赤色LIVE）
      expect(find.text('試合中 (LIVE)'), findsOneWidget);

      // 2段目: 対戦カード名
      expect(find.text('道上 vs 相手11'), findsOneWidget);

      // 3段目: コート・進行・メモ
      expect(find.text('第1試合場, 3試合目'), findsOneWidget);

      // 4段目: アクションボタン（スコアボタン、ルールボタン）
      expect(find.text('スコア'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      // 5段目: スコアサマリー（(0)）
      expect(find.text('(0)'), findsWidgets);
    });

    testWidgets('観客席ビュアー親カードでも1〜5段構造が正しく描画され、管理操作ボタンが非表示であること', (
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
                  groupKey: 'group_test_1',
                  groupList: testMatches,
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
      expect(find.text('第1試合場, 3試合目'), findsOneWidget);

      // 4段目: 観客用スコアボタン
      expect(find.text('スコア'), findsOneWidget);

      // 管理用ボタン（簡易入力、オーダー編集）が存在しないこと
      expect(find.text('簡易入力'), findsNothing);
      expect(find.byIcon(Icons.swap_vert), findsNothing);
    });
  });
}
