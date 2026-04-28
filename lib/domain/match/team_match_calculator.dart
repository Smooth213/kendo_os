import '../../models/match_model.dart';

class TeamMatchResult {
  final int redWins;
  final int whiteWins;
  final int redPoints;
  final int whitePoints;
  final bool allFinished;
  final bool hasDaihyo;
  final bool isTie;
  final String teamWinner; // 'red', 'white', 'draw', 'in_progress'
  final MatchModel? daihyoMatch;

  TeamMatchResult({
    required this.redWins,
    required this.whiteWins,
    required this.redPoints,
    required this.whitePoints,
    required this.allFinished,
    required this.hasDaihyo,
    required this.isTie,
    required this.teamWinner,
    this.daihyoMatch,
  });
}

class TeamMatchCalculator {
  static TeamMatchResult calculate(List<MatchModel> teamMatches) {
    int rW = 0, wW = 0, rP = 0, wP = 0;
    bool allFinished = true;
    bool hasDaihyo = false;
    MatchModel? daihyoMatch;

    for (var m in teamMatches) {
      if (m.matchType == '代表戦') {
        hasDaihyo = true;
        daihyoMatch = m;
      }
      if (m.status != 'approved' && m.status != 'finished') {
        allFinished = false;
      }
      if (m.status == 'approved' || m.status == 'finished') {
        rP += (m.redScore as num).toInt();
        wP += (m.whiteScore as num).toInt();
        if ((m.redScore as num) > (m.whiteScore as num)) {
          rW++;
        } else if ((m.whiteScore as num) > (m.redScore as num)) {
          wW++;
        }
      }
    }

    bool isTie = allFinished && !hasDaihyo && (rW == wW) && (rP == wP);

    String teamWinner = 'in_progress';
    if (allFinished) {
      if (rW > wW) {
        teamWinner = 'red';
      } else if (wW > rW) {
        teamWinner = 'white';
      } else if (rP > wP) {
        teamWinner = 'red';
      } else if (wP > rP) {
        teamWinner = 'white';
      } else if (daihyoMatch != null) {
        final rs = (daihyoMatch.redScore as num).toInt();
        final ws = (daihyoMatch.whiteScore as num).toInt();
        if (rs > ws) {
          teamWinner = 'red';
        } else if (ws > rs) {
          teamWinner = 'white';
        } else {
          teamWinner = 'draw';
        }
      } else {
        teamWinner = 'draw';
      }
    }

    return TeamMatchResult(
      redWins: rW,
      whiteWins: wW,
      redPoints: rP,
      whitePoints: wP,
      allFinished: allFinished,
      hasDaihyo: hasDaihyo,
      isTie: isTie,
      teamWinner: teamWinner,
      daihyoMatch: daihyoMatch,
    );
  }
}