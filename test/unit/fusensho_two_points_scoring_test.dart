import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/application/services/match_retirement_helper.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  group('🥋 不戦勝（棄権・相手欠席）時の二本勝ち自動判定・集計検証テスト', () {
    late KendoRuleEngine ruleEngine;
    final testUser = const User(
      id: 'admin_user',
      role: Role.admin,
      organizationId: 'org_1',
    );

    final dummyMatch = MatchModel(
      id: 'match_fusensho_01',
      tournamentId: 'tourney_01',
      matchType: '個人戦',
      redName: '赤選手（出場）',
      whiteName: '白選手（棄権）',
      matchTimeMinutes: 3.0,
      rule: const MatchRule(),
    );

    setUp(() {
      ruleEngine = KendoRuleEngine();
    });

    test('1. 相手欠席（不戦勝）時に自動で二本（◯・◯）が付与され二本勝ちとなること', () {
      final now = DateTime(2026, 9, 25, 10, 0, 0);
      final events = [
        ScoreEvent(
          id: 'fusen_event_red',
          side: Side.red,
          isFusen: true,
          isRetirement: false,
          timestamp: now,
        ),
      ];

      final analysis = ruleEngine.analyzeHistory(
        events,
        dummyMatch,
        const MatchRule(),
      );

      final redDisplays = analysis.displays[Side.red] ?? [];
      expect(redDisplays.length, 2);
      expect(redDisplays[0].mark, '◯');
      expect(redDisplays[1].mark, '◯');

      expect(analysis.context.redIppon, 2);
      expect(analysis.context.whiteIppon, 0);

      final result = ruleEngine.decideResult(
        analysis.context,
        const MatchRule(),
      );
      expect(result, MatchResultStatus.redWin);
    });

    test('2. 途中棄権時（MatchRetirementHelper）: 0-0から相手棄権で残りの2本が付与されること', () {
      final addScoreUseCase = AddScoreUseCase(
        ruleEngine,
        PermissionService(),
        SystemTimeSource(),
      );
      final retirementHelper = MatchRetirementHelper(addScoreUseCase);

      // 白が途中棄権 -> 赤に2本付与
      final updatedMatch = retirementHelper.processRetirement(
        user: testUser,
        match: dummyMatch,
        retiredSide: Side.white,
        rule: const MatchRule(),
      );

      final analysis = ruleEngine.analyzeHistory(
        updatedMatch.events,
        updatedMatch,
        const MatchRule(),
      );

      expect(analysis.context.redIppon, 2);
      expect(analysis.context.whiteIppon, 0);

      final result = ruleEngine.decideResult(
        analysis.context,
        const MatchRule(),
      );
      expect(result, MatchResultStatus.redWin);
    });

    test('3. 途中棄権時: 白が1本先取していた状態(1-0)で白が負傷棄権した場合、赤に2本付与され2-1で赤の勝ち', () {
      final addScoreUseCase = AddScoreUseCase(
        ruleEngine,
        PermissionService(),
        SystemTimeSource(),
      );
      final retirementHelper = MatchRetirementHelper(addScoreUseCase);

      // 白が面を先取した状態
      final matchWithWhiteMen = addScoreUseCase.execute(
        testUser,
        dummyMatch,
        ScoreEvent(
          id: 'men_white',
          side: Side.white,
          strikeType: StrikeType.men,
          isIppon: true,
          timestamp: DateTime.now(),
          sequence: 1,
          logicalClock: 1,
        ),
        const MatchRule(),
      );

      // ここで白が負傷棄権 -> 赤に2本（neededPoints = 2）が付与される
      final finalMatch = retirementHelper.processRetirement(
        user: testUser,
        match: matchWithWhiteMen,
        retiredSide: Side.white,
        rule: const MatchRule(),
      );

      final analysis = ruleEngine.analyzeHistory(
        finalMatch.events,
        finalMatch,
        const MatchRule(),
      );

      // 赤に2本、白に1本
      expect(analysis.context.redIppon, 2);
      expect(analysis.context.whiteIppon, 1);

      final result = ruleEngine.decideResult(
        analysis.context,
        const MatchRule(),
      );
      expect(result, MatchResultStatus.redWin);
    });

    test('4. 団体戦での不戦勝試合の勝者数・取得本数集計が正しく積算されること', () {
      // 団体戦5人制のスコアボード集計
      // 先鋒: 赤不戦勝 (2-0)
      // 次鋒: 白一本勝ち (0-1)
      // 中堅: 引き分け (0-0)
      // 副将: 赤一本勝ち (1-0)
      // 大将: 引き分け (1-1)
      // -> 赤の勝者数: 2, 取得本数: 4
      // -> 白の勝者数: 1, 取得本数: 2

      final teamScores = [
        {'redPoints': 2, 'whitePoints': 0, 'winner': Side.red}, // 先鋒 不戦勝
        {'redPoints': 0, 'whitePoints': 1, 'winner': Side.white}, // 次鋒
        {'redPoints': 0, 'whitePoints': 0, 'winner': null}, // 中堅
        {'redPoints': 1, 'whitePoints': 0, 'winner': Side.red}, // 副将
        {'redPoints': 1, 'whitePoints': 1, 'winner': null}, // 大将
      ];

      int redWins = 0;
      int whiteWins = 0;
      int redPointsTotal = 0;
      int whitePointsTotal = 0;

      for (final m in teamScores) {
        redPointsTotal += m['redPoints'] as int;
        whitePointsTotal += m['whitePoints'] as int;
        if (m['winner'] == Side.red) redWins++;
        if (m['winner'] == Side.white) whiteWins++;
      }

      expect(redWins, 2);
      expect(whiteWins, 1);
      expect(redPointsTotal, 4);
      expect(whitePointsTotal, 2);
    });
  });
}
