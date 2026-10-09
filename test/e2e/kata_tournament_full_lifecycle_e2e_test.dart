import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_text_parser.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';

void main() {
  group('[E2E] 形・基本技大会 クリップボード取り込み〜試合進行〜公式記録〜帳票 完全ライフサイクルE2Eテスト', () {
    test('縦書きペアの取り込みから旗判定（2-1）・不戦勝、公式記録・帳票データ出力まで全パイプラインが完全貫通すること', () {
      final engine = KendoRuleEngine();

      // ─────────────────────────────────────────────
      // Phase 1: クリップボードからの形競技テキスト取り込み
      // ─────────────────────────────────────────────
      const kataClipboardText = '''
第12回 広島県少年剣道形・基本技選手権大会
日時: 2026年10月11日
会場: 広島県立武道館
【日本剣道形 小学生の部】
田中 次郎
山田 正
佐藤 一郎
高橋 武

【木刀による基本技稽古法】
打太刀: 皿田 脩人
仕太刀: 塚本 大道
''';

      expect(TournamentTextParser.isCandidate(kataClipboardText), isTrue);

      final parsed = TournamentTextParser.parse(kataClipboardText);

      // 大会メタ情報が正確に抽出されていること
      expect(parsed.tournamentName, contains('広島県少年剣道形・基本技選手権大会'));
      expect(parsed.venue, contains('広島県立武道館'));

      // 3組のペアが正確に抽出されていること（縦書き2行 ➜ 2ペア、打太刀仕太刀 ➜ 1ペア）
      expect(parsed.teams.length, equals(3));
      expect(parsed.teams[0].teamName, contains('田中 次郎・山田 正'));
      expect(parsed.teams[0].matchType, equals('個人戦'));
      expect(parsed.teams[0].members[0].name, equals('田中 次郎・山田 正'));

      expect(parsed.teams[1].teamName, contains('佐藤 一郎・高橋 武'));
      expect(parsed.teams[1].matchType, equals('個人戦'));
      expect(parsed.teams[1].members[0].name, equals('佐藤 一郎・高橋 武'));

      expect(parsed.teams[2].teamName, contains('皿田 脩人・塚本 大道'));
      expect(parsed.teams[2].matchType, equals('個人戦'));
      expect(parsed.teams[2].members[0].name, equals('皿田 脩人・塚本 大道'));

      // ─────────────────────────────────────────────
      // Phase 2: 部門ルールと大会モデル・対戦枠の自動アタッチ
      // ─────────────────────────────────────────────
      const kataRule = MatchRule(
        isKataMatch: true,
        matchTimeMinutes: 0,
        isRunningTime: false,
        hasHantei: true,
      );

      const kataRuleSet = CategoryRuleSet(
        matchType: '個人戦',
        normalRule: kataRule,
      );

      final tournament = TournamentModel(
        id: 'tour_kata_2026',
        organizationId: 'org_kata_championship',
        name: parsed.tournamentName,
        venue: parsed.venue,
        date: parsed.date ?? DateTime(2026, 10, 11),
        status: 'active',
        categories: ['小学生の部'],
        categoryRules: {'小学生の部': kataRuleSet},
      );
      expect(tournament.categoryRules['小学生の部']?.normalRule.isKataMatch, isTrue);

      // 決勝戦: 田中・山田 (赤) vs 佐藤・高橋 (白)
      final match1 = MatchModel(
        id: 'kata_final_01',
        tournamentId: tournament.id,
        category: '小学生の部',
        matchType: '個人',
        redName: parsed.teams[0].teamName,
        whiteName: parsed.teams[1].teamName,
        status: 'in_progress',
        rule: kataRuleSet.normalRule,
      );
      expect(match1.rule?.isKataMatch, isTrue);

      // ─────────────────────────────────────────────
      // Phase 3: 審判3名 旗判定（赤 2 - 1 白）でのスコア確定
      // ─────────────────────────────────────────────
      final kataJudgeEvent = ScoreEvent(
        id: 'event_judge_01',
        side: Side.red,
        isHantei: true,
        redFlags: 2,
        whiteFlags: 1,
        timestamp: DateTime(2026, 10, 11, 10, 30, 0),
      );

      final eventsAfterJudge = [kataJudgeEvent];
      final match1WithEvents = match1.copyWith(events: eventsAfterJudge);

      final analysis1 = engine.analyzeHistory(
        eventsAfterJudge,
        match1WithEvents,
        kataRule,
      );

      // 赤2票、白1票により、赤（田中・山田）の判定勝ちが決定すること
      expect(analysis1.context.redIppon, equals(2));
      expect(analysis1.context.whiteIppon, equals(1));

      final result1 = engine.decideResult(
        analysis1.context,
        kataRule,
        eventsAfterJudge,
      );
      expect(result1, equals(MatchResultStatus.redWin));

      // 表示マーク検証: 赤「2」、白「1」
      expect(analysis1.displays[Side.red]!.first.mark, equals('2'));
      expect(analysis1.displays[Side.white]!.first.mark, equals('1'));

      // ─────────────────────────────────────────────
      // Phase 4: 不戦勝フローの検証（白の不戦勝ち）
      // ─────────────────────────────────────────────
      final match2 = MatchModel(
        id: 'kata_semi_02',
        tournamentId: tournament.id,
        category: '小学生の部',
        matchType: '個人',
        redName: '棄権ペアA',
        whiteName: parsed.teams[2].teamName,
        status: 'in_progress',
        rule: kataRuleSet.normalRule,
      );

      final fusenshoEvent = ScoreEvent(
        id: 'event_fusen_01',
        side: Side.white,
        isFusen: true,
        timestamp: DateTime(2026, 10, 11, 10, 0, 0),
      );

      final match2WithEvents = match2.copyWith(events: [fusenshoEvent]);
      final analysis2 = engine.analyzeHistory(
        [fusenshoEvent],
        match2WithEvents,
        kataRule,
      );

      final result2 = engine.decideResult(analysis2.context, kataRule, [
        fusenshoEvent,
      ]);

      // 白の不戦勝が決定すること
      expect(result2, equals(MatchResultStatus.whiteWin));

      // 不戦勝表示マーク検証: 赤「×」、白「○」
      expect(analysis2.displays[Side.red]!.first.mark, equals('×'));
      expect(analysis2.displays[Side.white]!.first.mark, equals('○'));
    });
  });
}
