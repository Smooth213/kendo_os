import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_match_generator.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_reorderable_slots_view.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_sticky_bottom_bar.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] OrderSetup Components テスト', () {
    test('オーダー設定マッチジェネレーターにより試合が正しく生成されること', () {
      const rule = MatchRule(
        teamName: '先鋒道場',
        category: '一般男子',
        positions: ['先鋒', '中堅', '大将'],
        baseOrder: ['山田', '佐藤', '鈴木'],
      );

      final matches = OrderSetupMatchGenerator.generateMatches(
        tournamentId: 't1',
        rule: rule,
        positions: const ['先鋒', '中堅', '大将'],
        selectedPlayers: {0: '山田', 1: '佐藤', 2: '鈴木'},
        opponentPlayers: {0: '田中', 1: '高橋', 2: '渡辺'},
        opponentTeamInput: '相手道場',
        isOwnTeamRed: true,
        leagueParticipants: const [],
        leagueTeamOrders: const {},
        matchType: 'team',
        isStartNow: false,
        baseOrder: 1000.0,
      );

      expect(matches.length, equals(3));
      expect(matches[0].redName, contains('先鋒道場'));
      expect(matches[0].whiteName, contains('相手道場'));
      expect(matches[0].matchType, equals('先鋒'));
    });

    testWidgets('オーダー設定ボトムバーが正しく描画されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: OrderSetupStickyBottomBar(
              themeColors: AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              isDark: false,
              enableLiquidGlass: false,
              onAddExtraPosition: () {},
              onConfirmAndProceed: () {},
            ),
          ),
        ),
      );

      expect(find.text('イレギュラー枠を追加する（錬成会用）'), findsOneWidget);
      expect(find.text('このオーダーで確定して進む'), findsOneWidget);
    });

    testWidgets('オーダー設定の並び替え可能スロットが正しく描画されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderSetupReorderableSlotsView(
              positions: const ['先鋒', '大将'],
              selectedPlayers: const {0: '山田', 1: '鈴木'},
              opponentPlayers: const {},
              teamName: '自チーム',
              isLeague: false,
              isDark: false,
              themeColors: AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              masterPlayers: const [],
              onReorder: (_, _) {},
              onSelectPlayerTap: (_) {},
              onOpponentChanged: (_, _) {},
              onVacantPressed: (_) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('先鋒'), findsWidgets);
      expect(find.textContaining('大将'), findsWidgets);
      expect(find.text('山田'), findsOneWidget);
      expect(find.text('鈴木'), findsOneWidget);
    });
  });
}
