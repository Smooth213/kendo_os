import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  group('🥋 【E2E】団体戦 同点→代表戦（1本勝負）指名・決着E2Eテスト', () {
    late KendoRuleEngine ruleEngine;
    late PermissionService permissionService;
    late SystemTimeSource timeSource;
    late AddScoreUseCase addScoreUseCase;

    final adminUser = const User(
      id: 'admin_director',
      role: Role.admin,
      organizationId: 'org_championship',
    );

    setUp(() {
      ruleEngine = KendoRuleEngine();
      permissionService = PermissionService();
      timeSource = SystemTimeSource();
      addScoreUseCase = AddScoreUseCase(
        ruleEngine,
        permissionService,
        timeSource,
      );
    });

    test('1. 5人制団体戦で勝者数・総取得本数が完全に同点となるシナリオの集計', () {
      // 先鋒: 赤一本勝ち (1-0)
      // 次鋒: 白一本勝ち (0-1)
      // 中堅: 引き分け (0-0)
      // 副将: 赤一本勝ち (1-0)
      // 大将: 白一本勝ち (0-1)
      // 結果: 勝者数 赤2 - 白2, 取得本数 赤2 - 白2 -> 同点・代表戦要件成立！

      final bouts = [
        {'redWins': 1, 'whiteWins': 0, 'redPts': 1, 'whitePts': 0},
        {'redWins': 0, 'whiteWins': 1, 'redPts': 0, 'whitePts': 1},
        {'redWins': 0, 'whiteWins': 0, 'redPts': 0, 'whitePts': 0},
        {'redWins': 1, 'whiteWins': 0, 'redPts': 1, 'whitePts': 0},
        {'redWins': 0, 'whiteWins': 1, 'redPts': 0, 'whitePts': 1},
      ];

      int totalRedWins = 0;
      int totalWhiteWins = 0;
      int totalRedPts = 0;
      int totalWhitePts = 0;

      for (final b in bouts) {
        totalRedWins += b['redWins']!;
        totalWhiteWins += b['whiteWins']!;
        totalRedPts += b['redPts']!;
        totalWhitePts += b['whitePts']!;
      }

      expect(totalRedWins, totalWhiteWins);
      expect(totalRedPts, totalWhitePts);
      final needsRepresentative =
          (totalRedWins == totalWhiteWins && totalRedPts == totalWhitePts);
      expect(needsRepresentative, isTrue);
    });

    test('2. 代表戦の自動生成と時間無制限一本勝負（一本先取で即時決着）の完全フロー', () {
      // 代表戦のルール定義（一本勝負）
      const repRule = MatchRule(
        isIpponShobu: true,
        matchTimeMinutes: 0.0, // 時間無制限
      );

      final repMatch = MatchModel(
        id: 'team_match_daihyosen_01',
        tournamentId: 'tourney_inter_high',
        matchType: '代表戦',
        redName: '剣道高校A: 代表 鈴木',
        whiteName: '武道高校B: 代表 高橋',
        status: 'in_progress',
        rule: repRule,
      );

      // 代表戦開始時はスコア0-0、規定本数1本
      var analysis = ruleEngine.analyzeHistory(
        repMatch.events,
        repMatch,
        repRule,
      );
      expect(analysis.context.redIppon, 0);
      expect(analysis.context.whiteIppon, 0);
      expect(analysis.context.targetIppon, 1);
      expect(
        ruleEngine.decideResult(analysis.context, repRule),
        MatchResultStatus.inProgress,
      );

      // 赤代表選手が面を決める
      final menEvent = ScoreEvent(
        id: 'rep_men_event',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: DateTime.now(),
        sequence: 1,
        logicalClock: 1,
      );

      final updatedRepMatch = addScoreUseCase.execute(
        adminUser,
        repMatch,
        menEvent,
        repRule,
      );

      // 一本勝負のため1本で即座に赤の勝利確定
      analysis = ruleEngine.analyzeHistory(
        updatedRepMatch.events,
        updatedRepMatch,
        repRule,
      );
      expect(analysis.context.redIppon, 1);
      expect(analysis.context.whiteIppon, 0);
      final finalResult = ruleEngine.decideResult(analysis.context, repRule);
      expect(finalResult, MatchResultStatus.redWin);
    });
  });
}
