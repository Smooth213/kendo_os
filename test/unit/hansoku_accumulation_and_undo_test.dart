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
  group('🥋 反則累積（2回一本/4回二本）＆ Undo連動テスト', () {
    late KendoRuleEngine ruleEngine;
    late PermissionService permissionService;
    late SystemTimeSource timeSource;
    late AddScoreUseCase addScoreUseCase;
    late UndoScoreUseCase undoScoreUseCase;

    final testUser = const User(
      id: 'admin_scorer',
      role: Role.admin,
      organizationId: 'org_test',
    );

    final initialMatch = MatchModel(
      id: 'match_hansoku_undo_01',
      tournamentId: 't1',
      matchType: '個人戦',
      redName: '赤選手',
      whiteName: '白選手',
      matchTimeMinutes: 3.0,
      rule: const MatchRule(),
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
      undoScoreUseCase = UndoScoreUseCase(
        ruleEngine,
        permissionService,
        timeSource,
      );
    });

    test('1. 赤の反則1回〜4回累積時の相手一本・二本判定境界値', () {
      expect(ruleEngine.isHansokuIppon(1), isFalse);
      expect(ruleEngine.isHansokuIppon(2), isTrue); // 2回目で相手一本
      expect(ruleEngine.isHansokuIppon(3), isFalse);
      expect(ruleEngine.isHansokuIppon(4), isTrue); // 4回目で相手二本（勝ち）
    });

    test('2. 赤の反則2回で白に「反」が1本付与され、Undoで取り消されること', () {
      const rule = MatchRule();
      var match = initialMatch;

      // 1回目の赤反則
      final h1 = ScoreEvent(
        id: 'h_red_1',
        side: Side.red,
        isHansoku: true,
        timestamp: DateTime(2026, 9, 25, 10, 0, 10),
        sequence: 1,
        logicalClock: 1,
      );
      match = addScoreUseCase.execute(testUser, match, h1, rule);

      var analysis = ruleEngine.analyzeHistory(match.events, match, rule);
      expect(analysis.context.redHansoku, 1);
      expect(analysis.context.whiteIppon, 0);
      expect(
        analysis.displays[Side.red]?.where((d) => d.mark == '△').length,
        1,
      );

      // 2回目の赤反則 -> 白に一本（反）が付与される
      final h2 = ScoreEvent(
        id: 'h_red_2',
        side: Side.red,
        isHansoku: true,
        timestamp: DateTime(2026, 9, 25, 10, 0, 20),
        sequence: 2,
        logicalClock: 2,
      );
      match = addScoreUseCase.execute(testUser, match, h2, rule);

      analysis = ruleEngine.analyzeHistory(match.events, match, rule);
      expect(analysis.context.redHansoku, 2);
      expect(analysis.context.whiteIppon, 1);
      // 白のスコアボードに「反」
      final whiteDisplays = analysis.displays[Side.white] ?? [];
      expect(whiteDisplays.any((d) => d.mark == '反'), isTrue);

      // Undo 実行: 2回目の反則が取り消される
      match = undoScoreUseCase.execute(testUser, match, rule);

      analysis = ruleEngine.analyzeHistory(match.events, match, rule);
      // 赤の反則は1回に戻り、白の一本は0に巻き戻る
      expect(analysis.context.redHansoku, 1);
      expect(analysis.context.whiteIppon, 0);
      final whiteDisplaysAfterUndo = analysis.displays[Side.white] ?? [];
      expect(whiteDisplaysAfterUndo.any((d) => d.mark == '反'), isFalse);
    });

    test('3. 赤の反則4回で白の二本勝ち確定後、Undoで3回に戻り試合継続状態に復元されること', () {
      const rule = MatchRule();
      var match = initialMatch;

      for (int i = 1; i <= 4; i++) {
        final hEvent = ScoreEvent(
          id: 'h_red_$i',
          side: Side.red,
          isHansoku: true,
          timestamp: DateTime(2026, 9, 25, 10, 0, i * 10),
          sequence: i,
          logicalClock: i,
        );
        match = addScoreUseCase.execute(testUser, match, hEvent, rule);
      }

      var analysis = ruleEngine.analyzeHistory(match.events, match, rule);
      expect(analysis.context.redHansoku, 4);
      expect(analysis.context.whiteIppon, 2);
      var result = ruleEngine.decideResult(analysis.context, rule);
      expect(result, MatchResultStatus.whiteWin);

      // 4回目の反則を取り消し (Undo)
      match = undoScoreUseCase.execute(testUser, match, rule);

      analysis = ruleEngine.analyzeHistory(match.events, match, rule);
      expect(analysis.context.redHansoku, 3);
      expect(analysis.context.whiteIppon, 1); // 2本目のみ取り消され1本に戻る
      result = ruleEngine.decideResult(analysis.context, rule);
      expect(result, MatchResultStatus.inProgress);
    });
  });
}
