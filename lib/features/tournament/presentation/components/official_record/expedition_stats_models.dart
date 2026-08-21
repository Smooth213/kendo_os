/// 選手ごとの詳細スタッツモデル
class DetailedPlayerStats {
  int win = 0;
  int loss = 0;
  int draw = 0;
  int men = 0;
  int kote = 0;
  int dou = 0;
  int tsuki = 0;
  int hansoku = 0;
  int other = 0;
  int totalPoints = 0;
  int concededPoints = 0;
}

/// 団体戦カード対戦結果モデル
class ExpeditionCardResult {
  final String cardTitle;
  final String opponentTeamName;
  final int myWins;
  final int oppWins;
  final int myPoints;
  final int oppPoints;
  final String resultType;
  final bool isWin;
  final bool isDraw;
  final String scene;

  ExpeditionCardResult({
    required this.cardTitle,
    required this.opponentTeamName,
    required this.myWins,
    required this.oppWins,
    required this.myPoints,
    required this.oppPoints,
    required this.resultType,
    required this.isWin,
    required this.isDraw,
    required this.scene,
  });
}

/// 遠征集計サマリー全体の算出結果オブジェクト
class ExpeditionSummaryData {
  final List<String> teamsList;
  final int renseikaiWin;
  final int renseikaiLoss;
  final int renseikaiDraw;
  final int honsenWin;
  final int honsenLoss;
  final int honsenDraw;
  final int moushiawaseWin;
  final int moushiawaseLoss;
  final int moushiawaseDraw;
  final int teamMen;
  final int teamKote;
  final int teamDou;
  final int teamTsuki;
  final int teamHansoku;
  final int teamOther;
  final int teamTotalScored;
  final int teamTotalConceded;
  final Map<String, DetailedPlayerStats> playerStatsMap;
  final List<ExpeditionCardResult> cardResults;

  ExpeditionSummaryData({
    required this.teamsList,
    required this.renseikaiWin,
    required this.renseikaiLoss,
    required this.renseikaiDraw,
    required this.honsenWin,
    required this.honsenLoss,
    required this.honsenDraw,
    required this.moushiawaseWin,
    required this.moushiawaseLoss,
    required this.moushiawaseDraw,
    required this.teamMen,
    required this.teamKote,
    required this.teamDou,
    required this.teamTsuki,
    required this.teamHansoku,
    required this.teamOther,
    required this.teamTotalScored,
    required this.teamTotalConceded,
    required this.playerStatsMap,
    required this.cardResults,
  });
}
