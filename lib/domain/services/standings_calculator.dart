import '../entities/match_model.dart';
import '../rules/match_rule.dart';

// ==========================================
// ★ Phase 6: ④ 勝敗集計ロジック分離
// 大会形式に応じた順位計算や状況解析を行う専門クラス群
// ==========================================

/// リーグ戦の各チームの成績データを保持するクラス
class LeagueTeamStat {
  final String name;
  int matchWins = 0;
  int matchLosses = 0;
  int matchDraws = 0;
  int individualWinners = 0;
  int totalPointsScored = 0;
  double customPoints = 0.0;
  int rank = 0;
  LeagueTeamStat({required this.name});
}

/// 勝敗集計の基本となる型（インターフェース）
abstract class StandingsCalculator<T> {
  T calculate(List<MatchModel> matches, MatchRule rule);
}

/// リーグ戦専用の集計ロジック（KendoRuleEngineから独立）
class LeagueStandingsCalculator implements StandingsCalculator<List<LeagueTeamStat>> {
  @override
  List<LeagueTeamStat> calculate(List<MatchModel> matches, MatchRule rule) {
    final Map<String, LeagueTeamStat> statsMap = {};
    
    final Set<String> participants = {};
    for (var m in matches) {
      participants.add(m.redName.split(':').first.trim());
      participants.add(m.whiteName.split(':').first.trim());
    }
    for (var p in participants) {
      statsMap[p] = LeagueTeamStat(name: p);
    }

    final Map<String, List<MatchModel>> pairings = {};
    for (var m in matches) {
      final t1 = m.redName.split(':').first.trim();
      final t2 = m.whiteName.split(':').first.trim();
      final key = [t1, t2]..sort();
      pairings.putIfAbsent(key.join(' vs '), () => []).add(m);
    }

    for (var entry in pairings.entries) {
      final bouts = entry.value;
      if (bouts.isEmpty || bouts.every((m) => m.status == 'waiting')) continue;

      final t1 = bouts.first.redName.split(':').first.trim();
      final t2 = bouts.first.whiteName.split(':').first.trim();
      
      int t1Wins = 0, t2Wins = 0, t1Pts = 0, t2Pts = 0;
      for (var b in bouts) {
        final bool isT1Red = b.redName.split(':').first.trim() == t1;
        final int rS = (b.redScore as num).toInt();
        final int wS = (b.whiteScore as num).toInt();
        t1Pts += isT1Red ? rS : wS;
        t2Pts += isT1Red ? wS : rS;
        if (rS > wS) { isT1Red ? t1Wins++ : t2Wins++; }
        else if (wS > rS) { isT1Red ? t2Wins++ : t1Wins++; }
      }

      final s1 = statsMap[t1]!;
      final s2 = statsMap[t2]!;
      s1.individualWinners += t1Wins;
      s1.totalPointsScored += t1Pts;
      s2.individualWinners += t2Wins;
      s2.totalPointsScored += t2Pts;

      if (t1Wins > t2Wins || (t1Wins == t2Wins && t1Pts > t2Pts)) {
        s1.matchWins++; s2.matchLosses++;
        s1.customPoints += rule.winPoint; s2.customPoints += rule.lossPoint;
      } else if (t2Wins > t1Wins || (t2Wins == t1Wins && t2Pts > t1Pts)) {
        s2.matchWins++; s1.matchLosses++;
        s2.customPoints += rule.winPoint; s1.customPoints += rule.lossPoint;
      } else {
        s1.matchDraws++; s2.matchDraws++;
        s1.customPoints += rule.drawPoint; s2.customPoints += rule.drawPoint;
      }
    }

    final sortedList = statsMap.values.toList();
    sortedList.sort((a, b) {
      if (rule.winPoint > 0 || rule.drawPoint > 0) {
        if (b.customPoints != a.customPoints) return b.customPoints.compareTo(a.customPoints);
      }
      if (b.matchWins != a.matchWins) return b.matchWins.compareTo(a.matchWins);
      if (b.individualWinners != a.individualWinners) return b.individualWinners.compareTo(a.individualWinners);
      return b.totalPointsScored.compareTo(a.totalPointsScored);
    });

    for (int i = 0; i < sortedList.length; i++) {
      sortedList[i].rank = i + 1;
    }
    return sortedList;
  }
}