import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/league_standing.dart';

/// 全日本剣道連盟公式大会基準 リーグ戦順位決定（タイブレーク）比較エンジン
class KendoStandingComparator {
  /// 2つの LeagueStanding を比較（降順: 1位が先頭）
  static int compare(LeagueStanding a, LeagueStanding b) {
    // 1. 勝数 (wins)
    if (a.wins != b.wins) {
      return b.wins.compareTo(a.wins);
    }

    // 2. 引分数 (draws) による勝点優劣
    if (a.draws != b.draws) {
      return b.draws.compareTo(a.draws);
    }

    // 3. 総取得本数 (pointsFor)
    if (a.pointsFor != b.pointsFor) {
      return b.pointsFor.compareTo(a.pointsFor);
    }

    // 4. 得失点差 / 本数差 (pointsFor - pointsAgainst)
    final diffA = a.pointsFor - a.pointsAgainst;
    final diffB = b.pointsFor - b.pointsAgainst;
    if (diffA != diffB) {
      return diffB.compareTo(diffA);
    }

    // 5. 喪失本数の少なさ (pointsAgainst)
    return a.pointsAgainst.compareTo(b.pointsAgainst);
  }

  /// リストを受け取り、公式順位順にソートして返す
  static List<LeagueStanding> rank(List<LeagueStanding> standings) {
    final list = List<LeagueStanding>.from(standings);
    list.sort(compare);
    return list;
  }
}

void main() {
  group('🧪 【Unit 5/5】同率タイブレーク（勝点・勝者数・総本数・代表戦）境界値テスト', () {
    test('1. 勝数が異なる場合、勝数の多い選手/チームが上位になること', () {
      const s1 = LeagueStanding(playerName: '選手A', wins: 2, pointsFor: 3);
      const s2 = LeagueStanding(playerName: '選手B', wins: 1, pointsFor: 5);

      final ranked = KendoStandingComparator.rank([s2, s1]);
      expect(ranked.first.playerName, '選手A');
    });

    test('2. 勝数が同率の場合、総取得本数（pointsFor）が多い選手が上位になること', () {
      const s1 = LeagueStanding(
        playerName: '選手A',
        wins: 1,
        draws: 1,
        pointsFor: 2,
        pointsAgainst: 1,
      );
      const s2 = LeagueStanding(
        playerName: '選手B',
        wins: 1,
        draws: 1,
        pointsFor: 4,
        pointsAgainst: 3,
      );

      final ranked = KendoStandingComparator.rank([s1, s2]);
      expect(ranked.first.playerName, '選手B');
    });

    test('3. 勝数・総本数ともに同率の場合、本数差（得失本数差）が優れる選手が上位になること', () {
      const s1 = LeagueStanding(
        playerName: '選手A',
        wins: 1,
        pointsFor: 3,
        pointsAgainst: 1, // 差 +2
      );
      const s2 = LeagueStanding(
        playerName: '選手B',
        wins: 1,
        pointsFor: 3,
        pointsAgainst: 2, // 差 +1
      );

      final ranked = KendoStandingComparator.rank([s2, s1]);
      expect(ranked.first.playerName, '選手A');
    });

    test('4. 完全同率（全項目同数）の場合、代表戦（Playoff）判定フラグが成立すること', () {
      const s1 = LeagueStanding(
        playerName: '選手A',
        wins: 1,
        draws: 1,
        losses: 0,
        pointsFor: 2,
        pointsAgainst: 1,
      );
      const s2 = LeagueStanding(
        playerName: '選手B',
        wins: 1,
        draws: 1,
        losses: 0,
        pointsFor: 2,
        pointsAgainst: 1,
      );

      final diff = KendoStandingComparator.compare(s1, s2);
      expect(diff, 0, reason: '完全同率のため比較値は0となり、代表戦（決定戦）が必要となる');
    });
  });
}
