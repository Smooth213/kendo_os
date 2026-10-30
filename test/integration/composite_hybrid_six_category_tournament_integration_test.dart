import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_player_match_classifier.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';

void main() {
  group('[Integration] 混成ハイブリッド6カテゴリ同一コート複合大会進行E2Eテスト', () {
    test(
      '剣道形・基本技・個人戦・団体戦・勝ち抜き戦・代表戦の全6カテゴリが同一コートで連続進行してもルール整合性とタイムライン分類が完全維持されること',
      () async {
        final engine = KendoRuleEngine();
        final baseTime = DateTime(2026, 10, 15, 9, 0, 0);

        // 大会メタ情報
        final tournament = TournamentModel(
          id: 't_hybrid_six_cat',
          organizationId: 'org_hiroshima',
          name: '第20回 広島県少年親善混成武道大会',
          date: DateTime(2026, 10, 15),
          venue: '広島県立武道館 第一競技場',
          categories: [
            '日本剣道形',
            '木刀による基本技稽古法',
            '小学生低学年個人戦',
            '小学生団体戦',
            '中学生勝ち抜き戦',
            '代表戦',
          ],
        );

        final matches = <MatchModel>[];

        // ─────────────────────────────────────────────
        // Category 1: 日本剣道形（打太刀・仕太刀ペア vs 打太刀・仕太刀ペア 旗判定）
        // ─────────────────────────────────────────────
        const kataRule = MatchRule(
          hasHantei: true,
          matchTimeMinutes: 5,
          ipponLimit: 0,
        );

        final kataMatch = MatchModel(
          id: 'm_cat1_kata',
          tournamentId: tournament.id,
          groupName: '第1コート',
          matchType: '個人戦',
          category: '日本剣道形',
          redName: '打太刀: 皿田 脩人・仕太刀: 塚本 大道',
          whiteName: '打太刀: 佐藤 健・仕太刀: 高橋 武',
          rule: kataRule,
          status: 'finished',
          events: [
            ScoreEvent(
              id: 'ev_kata_hantei_1',
              side: Side.red,
              isHantei: true,
              timestamp: baseTime.add(const Duration(minutes: 5)),
              sequence: 1,
              logicalClock: 1,
            ),
            ScoreEvent(
              id: 'ev_kata_hantei_2',
              side: Side.red,
              isHantei: true,
              timestamp: baseTime.add(const Duration(minutes: 5)),
              sequence: 2,
              logicalClock: 2,
            ),
            ScoreEvent(
              id: 'ev_kata_hantei_3',
              side: Side.white,
              isHantei: true,
              timestamp: baseTime.add(const Duration(minutes: 5)),
              sequence: 3,
              logicalClock: 3,
            ),
          ],
        );
        matches.add(kataMatch);

        final kataAnalysis = engine.analyzeHistory(
          kataMatch.events,
          kataMatch,
          kataRule,
        );
        expect(kataAnalysis.context.hasHantei, isTrue);

        // ─────────────────────────────────────────────
        // Category 2: 木刀による基本技稽古法（基本技 旗判定）
        // ─────────────────────────────────────────────
        final kihonMatch = MatchModel(
          id: 'm_cat2_kihon',
          tournamentId: tournament.id,
          groupName: '第1コート',
          matchType: '個人戦',
          category: '木刀による基本技稽古法',
          redName: '打太刀: 木村・仕太刀: 渡辺',
          whiteName: '打太刀: 中村・仕太刀: 小林',
          rule: kataRule,
          status: 'finished',
          events: [
            ScoreEvent(
              id: 'ev_kihon_hantei_1',
              side: Side.white,
              isHantei: true,
              timestamp: baseTime.add(const Duration(minutes: 15)),
              sequence: 1,
              logicalClock: 1,
            ),
            ScoreEvent(
              id: 'ev_kihon_hantei_2',
              side: Side.white,
              isHantei: true,
              timestamp: baseTime.add(const Duration(minutes: 15)),
              sequence: 2,
              logicalClock: 2,
            ),
            ScoreEvent(
              id: 'ev_kihon_hantei_3',
              side: Side.white,
              isHantei: true,
              timestamp: baseTime.add(const Duration(minutes: 15)),
              sequence: 3,
              logicalClock: 3,
            ),
          ],
        );
        matches.add(kihonMatch);

        final kihonAnalysis = engine.analyzeHistory(
          kihonMatch.events,
          kihonMatch,
          kataRule,
        );
        expect(kihonAnalysis.context.hasHantei, isTrue);

        // ─────────────────────────────────────────────
        // Category 3: 小学生低学年個人戦（2分 3本勝負）
        // ─────────────────────────────────────────────
        const indRule = MatchRule(
          matchTimeMinutes: 2,
          ipponLimit: 2,
          isIpponShobu: false,
        );

        final indMatch = MatchModel(
          id: 'm_cat3_ind',
          tournamentId: tournament.id,
          groupName: '第1コート',
          matchType: '個人戦',
          category: '小学生低学年個人戦',
          redName: '皿田 脩人',
          whiteName: '山本 太郎',
          rule: indRule,
          status: 'finished',
          redScore: 2,
          whiteScore: 0,
          events: [
            ScoreEvent(
              id: 'ev_ind_men',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: baseTime.add(const Duration(minutes: 25)),
              sequence: 1,
              logicalClock: 1,
            ),
            ScoreEvent(
              id: 'ev_ind_kote',
              side: Side.red,
              strikeType: StrikeType.kote,
              isIppon: true,
              timestamp: baseTime.add(const Duration(minutes: 26)),
              sequence: 2,
              logicalClock: 2,
            ),
          ],
        );
        matches.add(indMatch);

        final indAnalysis = engine.analyzeHistory(
          indMatch.events,
          indMatch,
          indRule,
        );
        expect(indAnalysis.context.redIppon, equals(2));
        expect(indAnalysis.context.whiteIppon, equals(0));

        // ─────────────────────────────────────────────
        // Category 4: 小学生団体戦（5人制・ポジション別 先鋒〜大将）
        // ─────────────────────────────────────────────
        const teamPositions = ['先鋒', '次鋒', '中堅', '副将', '大将'];
        const teamRule = MatchRule(
          matchTimeMinutes: 3,
          ipponLimit: 2,
          positions: teamPositions,
        );

        for (var i = 0; i < teamPositions.length; i++) {
          final pos = teamPositions[i];
          final match = MatchModel(
            id: 'm_cat4_team_$i',
            tournamentId: tournament.id,
            groupName: '団体戦第1試合',
            matchType: pos,
            category: '小学生団体戦',
            redName: '道上剣友会: 選手$pos',
            whiteName: '修道館: 選手$pos',
            rule: teamRule,
            status: 'finished',
            redScore: i % 2 == 0 ? 1 : 0,
            whiteScore: i % 2 == 1 ? 1 : 0,
            events: [
              ScoreEvent(
                id: 'ev_team_${i}_strike',
                side: i % 2 == 0 ? Side.red : Side.white,
                strikeType: StrikeType.men,
                isIppon: true,
                timestamp: baseTime.add(Duration(minutes: 35 + i * 4)),
                sequence: 1,
                logicalClock: 1,
              ),
            ],
          );
          matches.add(match);
        }

        // ─────────────────────────────────────────────
        // Category 5: 中学生勝ち抜き戦（勝ち抜きルール適用）
        // ─────────────────────────────────────────────
        const kachinukiRule = MatchRule(
          isKachinuki: true,
          matchTimeMinutes: 3,
          ipponLimit: 1,
          isIpponShobu: true,
        );

        final kachinukiMatch = MatchModel(
          id: 'm_cat5_kachinuki_01',
          tournamentId: tournament.id,
          groupName: '勝ち抜き戦第1試合',
          matchType: '先鋒戦',
          category: '中学生勝ち抜き戦',
          redName: '道上剣友会: 先鋒A',
          whiteName: '広島北: 先鋒B',
          rule: kachinukiRule,
          status: 'finished',
          redScore: 1,
          whiteScore: 0,
          events: [
            ScoreEvent(
              id: 'ev_kachi_men',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: baseTime.add(const Duration(minutes: 60)),
              sequence: 1,
              logicalClock: 1,
            ),
          ],
        );
        matches.add(kachinukiMatch);

        final kachinukiAnalysis = engine.analyzeHistory(
          kachinukiMatch.events,
          kachinukiMatch,
          kachinukiRule,
        );
        expect(kachinukiAnalysis.context.redIppon, equals(1));

        // ─────────────────────────────────────────────
        // Category 6: 代表戦（時間無制限1本勝負）
        // ─────────────────────────────────────────────
        const daihyoRule = MatchRule(
          isIpponShobu: true,
          ipponLimit: 1,
          matchTimeMinutes: 0,
        );

        final daihyoMatch = MatchModel(
          id: 'm_cat6_daihyo',
          tournamentId: tournament.id,
          groupName: '団体戦第1試合',
          matchType: '代表戦',
          category: '小学生団体戦 代表決定',
          redName: '道上剣友会: 大将（代表）',
          whiteName: '修道館: 大将（代表）',
          rule: daihyoRule,
          status: 'finished',
          redScore: 1,
          whiteScore: 0,
          events: [
            ScoreEvent(
              id: 'ev_daihyo_dou',
              side: Side.red,
              strikeType: StrikeType.dou,
              isIppon: true,
              timestamp: baseTime.add(const Duration(minutes: 75)),
              sequence: 1,
              logicalClock: 1,
            ),
          ],
        );
        matches.add(daihyoMatch);

        final daihyoAnalysis = engine.analyzeHistory(
          daihyoMatch.events,
          daihyoMatch,
          daihyoRule,
        );
        expect(daihyoAnalysis.context.redIppon, equals(1));

        // ─────────────────────────────────────────────
        // 全6カテゴリ複合状態でのタイムライン分類完全検証
        // ─────────────────────────────────────────────
        final classified = TimelinePlayerMatchClassifier.classifyTeamMatches(
          teamMatchesList: matches,
          teamName: '道上剣友会',
          sanitizedQuery: '',
          matchedMatchIds: {},
          matchedGroupNames: {},
          ownTeams: ['道上剣友会'],
        );

        // 合計試合数が投入した10試合（形1+基本1+個人1+団体5+勝抜1+代表1）すべて集計されていること
        final totalMatchesInTimeline =
            classified.sortedGroups.fold<int>(
              0,
              (sum, entry) => sum + entry.value.length,
            ) +
            classified.sortedPlayers.fold<int>(
              0,
              (sum, entry) => sum + entry.value.length,
            );
        expect(totalMatchesInTimeline, equals(10));

        // 完了した試合がすべて status: finished であること
        for (final group in classified.sortedGroups) {
          for (final m in group.value) {
            expect(m.status, equals('finished'));
          }
        }
        for (final player in classified.sortedPlayers) {
          for (final m in player.value) {
            expect(m.status, equals('finished'));
          }
        }
      },
    );
  });
}
