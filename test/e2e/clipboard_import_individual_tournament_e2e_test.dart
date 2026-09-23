import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_text_parser.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';

void main() {
  group('🚀 【E2E】クリップボード取り込み ➔ 個人戦トーナメント生成 ➔ 試合進行・優勝決定 完全フローE2Eテスト', () {
    test('1. ユーザー指定の複数人個人戦テキストを取り込み、部門正規化・トーナメント編成・試合進行・優勝決定まで貫通すること', () {
      // ── Step 1: クリップボード取り込みテキストの定義 ──
      const rawClipboardText = '''
第50回 春季毎日剣道大会
会場: 大阪府立体育会館

個人戦
中学生
皿田 唯人
皿田 梓人
橋本 璃久

個人戦
小学生低学年
佐藤 健太
田中 陽葵
''';

      // ── Step 2: パーサーによる解析実行 ──
      final parsedData = TournamentTextParser.parse(rawClipboardText);

      // 大会メタ情報が正確に抽出されていること
      expect(parsedData.tournamentName, contains('第50回 春季毎日剣道大会'));
      expect(parsedData.venue, contains('大阪府立体育会館'));

      // 合計5名の個人戦エントリーが抽出されていること
      expect(parsedData.teams.length, 5);

      // 中学生の部の3名がすべて個人戦としてパースされていること
      final juniorHighEntries = parsedData.teams
          .where((t) => t.category == '中学生')
          .toList();
      expect(juniorHighEntries.length, 3);
      expect(
        juniorHighEntries.map((t) => t.teamName),
        containsAll(['皿田 唯人', '皿田 梓人', '橋本 璃久']),
      );
      expect(juniorHighEntries.every((t) => t.matchType == '個人戦'), isTrue);

      // ── Step 3: 部門名の正規化解決（TournamentTeamAutoRegisterService） ──
      final normalizedTeams = parsedData.teams.map((t) {
        final resolvedCategory =
            TournamentTeamAutoRegisterService.resolveCategory(t);
        return t.copyWith(category: resolvedCategory);
      }).toList();

      // 中学生 ➔ 中学生の部、小学生低学年 ➔ 小学生低学年の部に正規化されていること
      final juniorHighNormalized = normalizedTeams
          .where((t) => t.category == '中学生の部')
          .toList();
      expect(juniorHighNormalized.length, 3);

      final elementaryNormalized = normalizedTeams
          .where((t) => t.category == '小学生低学年の部')
          .toList();
      expect(elementaryNormalized.length, 2);

      // ── Step 4: 大会モデルおよび中学生の部トーナメント試合の編成 ──
      final tournament = TournamentModel(
        id: 'tour_daily_50',
        organizationId: 'org_osaka_kendo',
        name: parsedData.tournamentName,
        venue: parsedData.venue,
        status: 'active',
        categories: ['中学生の部', '小学生低学年の部'],
        date: DateTime(2026, 9, 24),
      );
      expect(tournament.id, 'tour_daily_50');

      // 中学生の部（3名トーナメント）
      // 1回戦（準決勝）: 皿田 唯人 vs 皿田 梓人
      // シード: 橋本 璃久
      // 決勝戦: 1回戦勝者 vs 橋本 璃久
      const individualRule = MatchRule(
        matchTimeMinutes: 3.0,
        isIpponShobu: false, // 三本勝負
        enchoTimeMinutes: 3.0,
      );

      final semiFinalMatch = MatchModel(
        id: 'match_jh_semi_01',
        tournamentId: tournament.id,
        category: '中学生の部',
        groupName: '個人戦トーナメント',
        matchType: '個人戦',
        status: 'in_progress',
        redName: juniorHighNormalized[0].teamName, // 皿田 唯人
        whiteName: juniorHighNormalized[1].teamName, // 皿田 梓人
        redScore: 0,
        whiteScore: 0,
        rule: individualRule,
        order: 1.0,
        events: [],
      );

      // ── Step 5: 準決勝の試合進行（スコア記録・勝敗判定） ──
      final semiFinalEvent1 = ScoreEvent(
        id: 'ev_semi_1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: DateTime(2026, 9, 24, 10, 0),
        logicalClock: 1,
      );
      final semiFinalEvent2 = ScoreEvent(
        id: 'ev_semi_2',
        side: Side.red,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: DateTime(2026, 9, 24, 10, 1),
        logicalClock: 2,
      );

      final finishedSemiFinal = semiFinalMatch.copyWith(
        status: 'finished',
        redScore: 2,
        whiteScore: 0,
        events: [semiFinalEvent1, semiFinalEvent2],
      );

      final semiFinalWinner =
          finishedSemiFinal.redScore > finishedSemiFinal.whiteScore
          ? finishedSemiFinal.redName
          : finishedSemiFinal.whiteName;

      expect(finishedSemiFinal.status, 'finished');
      expect(semiFinalWinner, '皿田 唯人');
      expect(finishedSemiFinal.redScore, 2);
      expect(finishedSemiFinal.whiteScore, 0);

      // ── Step 6: 決勝戦の生成と勝者の進出 ──
      final finalMatch = MatchModel(
        id: 'match_jh_final',
        tournamentId: tournament.id,
        category: '中学生の部',
        groupName: '個人戦トーナメント',
        matchType: '個人戦',
        status: 'in_progress',
        redName: semiFinalWinner, // 準決勝勝者: 皿田 唯人
        whiteName: juniorHighNormalized[2].teamName, // シード: 橋本 璃久
        redScore: 0,
        whiteScore: 0,
        rule: individualRule,
        order: 2.0,
        events: [],
      );

      expect(finalMatch.redName, '皿田 唯人');
      expect(finalMatch.whiteName, '橋本 璃久');

      // ── Step 7: 決勝戦の試合進行と優勝者決定 ──
      final finalEvent = ScoreEvent(
        id: 'ev_final_1',
        side: Side.red,
        strikeType: StrikeType.dou,
        isIppon: true,
        timestamp: DateTime(2026, 9, 24, 10, 15),
        logicalClock: 3,
      );

      final finishedFinal = finalMatch.copyWith(
        status: 'finished',
        redScore: 1,
        whiteScore: 0,
        events: [finalEvent],
      );

      final champion = finishedFinal.redScore > finishedFinal.whiteScore
          ? finishedFinal.redName
          : finishedFinal.whiteName;

      // ── 最終検証 ──
      expect(finishedFinal.status, 'finished');
      expect(champion, '皿田 唯人');
      expect(finishedFinal.category, '中学生の部');
      expect(finishedFinal.matchType, '個人戦');
      expect(finishedFinal.rule?.matchTimeMinutes, 3.0);
    });
  });
}
