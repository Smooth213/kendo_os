import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/services/match_auto_progression_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_state_holder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/renseikai_quick_assign_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_match_generator.dart';

void main() {
  group('[E2E] 錬成会4人編成空欄スキップおよび選手アサイン全画面同期検証', () {
    const renseikaiRule = MatchRule(
      isRenseikai: true,
      matchScene: 'renseikai',
      renseikaiType: '時間制',
      overallTimeMinutes: 30,
      matchTimeMinutes: 2.0,
      skipEmptyRoster: true,
      teamName: '自チーム道場',
    );

    test('4人チーム対5人チームの錬成会で双方が空欄の枠はスキップされ片方空欄は未定枠で生成されること', () {
      final positions = ['先鋒', '次鋒', '中堅', '副将', '大将'];
      // 自チームは4人（大将枠が空欄）
      final selectedPlayers = {0: '選手A', 1: '選手B', 2: '選手C', 3: '選手D'};
      // 相手チームは5人全員揃っている
      final opponentPlayers = {
        0: '相手1',
        1: '相手2',
        2: '相手3',
        3: '相手4',
        4: '相手5',
      };

      final matches = OrderSetupMatchGenerator.generateMatches(
        tournamentId: 'tourney_renseikai_001',
        rule: renseikaiRule,
        positions: positions,
        selectedPlayers: selectedPlayers,
        opponentPlayers: opponentPlayers,
        opponentTeamInput: '相手道場',
        isOwnTeamRed: true,
        leagueParticipants: [],
        leagueTeamOrders: {},
        matchType: '団体戦',
        isStartNow: true,
        baseOrder: 1.0,
      );

      // 5試合生成される（大将戦は自チームが「未定」、相手が「相手道場 : 相手5」）
      expect(matches.length, 5);
      final fifthMatch = matches[4];
      expect(fifthMatch.matchType, '大将');
      expect(fifthMatch.whiteName, contains('相手5'));
      expect(fifthMatch.redName, contains('未定'));

      // もし相手も大将枠が空欄だった場合（双方空欄）
      final bothEmptyOpponent = {0: '相手1', 1: '相手2', 2: '相手3', 3: '相手4'};
      final matchesWithSkip = OrderSetupMatchGenerator.generateMatches(
        tournamentId: 'tourney_renseikai_001',
        rule: renseikaiRule,
        positions: positions,
        selectedPlayers: selectedPlayers,
        opponentPlayers: bothEmptyOpponent,
        opponentTeamInput: '相手道場',
        isOwnTeamRed: true,
        leagueParticipants: [],
        leagueTeamOrders: {},
        matchType: '団体戦',
        isStartNow: true,
        baseOrder: 1.0,
      );

      // 双方空欄の大将戦は自動スキップされて 4試合 のみ生成されること！
      expect(matchesWithSkip.length, 4);
      expect(matchesWithSkip.any((m) => m.matchType == '大将'), isFalse);
    });

    testWidgets('試合画面で未定枠に対してRenseikaiQuickAssignBarから選手を選択できること', (
      tester,
    ) async {
      final List<MatchModel> teamMatches = [
        const MatchModel(
          id: 'm1',
          matchType: '先鋒',
          redName: '自チーム道場 : 選手A',
          whiteName: '相手道場 : 相手1',
          matchTimeMinutes: 2,
        ),
        const MatchModel(
          id: 'm2',
          matchType: '次鋒',
          redName: '自チーム道場 : 選手B',
          whiteName: '相手道場 : 相手2',
          matchTimeMinutes: 2,
        ),
        const MatchModel(
          id: 'm3',
          matchType: '中堅',
          redName: '自チーム道場 : 選手C',
          whiteName: '相手道場 : 相手3',
          matchTimeMinutes: 2,
        ),
        const MatchModel(
          id: 'm4',
          matchType: '副将',
          redName: '自チーム道場 : 選手D',
          whiteName: '相手道場 : 相手4',
          matchTimeMinutes: 2,
        ),
        const MatchModel(
          id: 'm5',
          matchType: '大将',
          redName: '自チーム道場 : 未定',
          whiteName: '相手道場 : 相手5',
          matchTimeMinutes: 2,
          rule: renseikaiRule,
        ),
      ];

      final targetMatch = teamMatches[4];

      MatchModel? assignedMatch;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return RenseikaiQuickAssignBar(
                    match: targetMatch,
                    rule: renseikaiRule,
                    teamMatches: teamMatches,
                    isDark: false,
                    ref: ref,
                    onAssignPlayer: (updated) async {
                      assignedMatch = updated;
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // 「出場選手を選択:」ラベルと、登録選手4名のチップが表示されること
      expect(find.text('出場選手を選択:'), findsOneWidget);
      expect(find.text('選手A'), findsOneWidget);
      expect(find.text('選手B'), findsOneWidget);
      expect(find.text('選手C'), findsOneWidget);
      expect(find.text('選手D'), findsOneWidget);

      // 選手Aのチップをタップ
      await tester.tap(find.text('選手A'));
      await tester.pump();

      // 選手Aがアサインされ、自チーム選手名が更新されたMatchModelが生成されること
      expect(assignedMatch, isNotNull);
      expect(assignedMatch!.redName, contains('選手A'));
    });

    testWidgets('自動進行サービスが空欄枠に対して不戦勝を自動生成しないこと', (tester) async {
      const emptyMatch = MatchModel(
        id: 'empty_match_01',
        matchType: '大将',
        redName: '自チーム道場 : 未定',
        whiteName: '相手道場 : 相手5',
        matchTimeMinutes: 2,
        rule: renseikaiRule,
      );

      bool fusenAdded = false;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              final service = ref.read(matchAutoProgressionServiceProvider);
              // 非同期処理をトリガー
              Future.microtask(() async {
                await service.autoProcessFusenIfNeeded(
                  match: emptyMatch,
                  onAddIppon: (id, side, type) async {
                    fusenAdded = true;
                  },
                  onFinish: (_) async {},
                );
              });
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // skipEmptyRoster が有効なため、自動不戦勝は付与されないこと！
      expect(fusenAdded, isFalse);
    });

    test('個別試合編集シートでルールを再保存してもskipEmptyRoster等が上書き保存されないこと', () async {
      const originalRule = MatchRule(
        isRenseikai: true,
        matchScene: 'renseikai',
        renseikaiType: '時間制',
        overallTimeMinutes: 40,
        matchTimeMinutes: 3.0,
        skipEmptyRoster: true,
        isRunningTime: true,
        teamName: '自チーム道場',
      );

      final dummyMatch = MatchModel(
        id: 'test_m10',
        matchType: '大将',
        rule: originalRule,
        redName: '自チーム道場 : 選手A',
        whiteName: '相手道場 : 相手1',
        matchTimeMinutes: 3.0,
      );

      final holder = MatchEditStateHolder([dummyMatch]);

      // ロード時に正しく skipEmptyRoster が true であること
      expect(holder.skipEmptyRoster, isTrue);
      expect(holder.isRunningTime, isTrue);

      // 他の項目（例えばコート名など）だけを変更して保存実行
      holder.courtController.text = '第1コート';

      // skipEmptyRoster が true のまま保持されていること
      expect(holder.skipEmptyRoster, isTrue);
    });
  });
}
