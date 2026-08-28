/// 選手ごとの詳細スタッツモデル
class DetailedPlayerStats {
  // --- 通算（総合） ---
  int win = 0;
  int loss = 0;
  int draw = 0;
  int totalPoints = 0;
  int concededPoints = 0;

  // --- 🥋 団体戦 内訳 ---
  int teamWin = 0;
  int teamLoss = 0;
  int teamDraw = 0;
  int teamPoints = 0;
  int teamConceded = 0;

  // --- ⚔️ 個人戦 内訳 ---
  int individualWin = 0;
  int individualLoss = 0;
  int individualDraw = 0;
  int individualPoints = 0;
  int individualConceded = 0;

  // --- 技内訳（有効打突） ---
  int men = 0;
  int kote = 0;
  int dou = 0;
  int tsuki = 0;
  int hansoku = 0;
  int other = 0;
}

/// 対戦カード結果モデル（団体戦または個人戦）
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
  final bool isIndividual; // ★ 個人戦フラグ

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
    this.isIndividual = false,
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

  // 個人戦サマリー勝敗
  final int individualTotalWins;
  final int individualTotalLosses;
  final int individualTotalDraws;

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
    this.individualTotalWins = 0,
    this.individualTotalLosses = 0,
    this.individualTotalDraws = 0,
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
