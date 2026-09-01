import 'package:kendo_os/features/match/domain/match_model.dart';

/// 🥋 自道場エントリーチーム別の進行ステータスモデル
class TeamProgressStatus {
  final String teamName;
  final String categoryName;
  final String currentCourtName;
  final String matchupTitle;
  final String? targetGroupId;
  final String? tournamentId;
  final List<MatchModel> matches;
  final MatchModel? inProgressMatch;
  final MatchModel? lastFinishedMatch;
  final MatchModel? nextWaitingMatch;
  final int completedCount;
  final int totalCount;
  final int waitingMatchCount;
  final int totalWins;
  final int totalLosses;
  final int totalDraws;
  final int totalPoints;
  final bool hasLiveMatch;

  const TeamProgressStatus({
    required this.teamName,
    this.categoryName = '',
    this.currentCourtName = '',
    this.matchupTitle = '',
    this.targetGroupId,
    this.tournamentId,
    required this.matches,
    this.inProgressMatch,
    this.lastFinishedMatch,
    this.nextWaitingMatch,
    required this.completedCount,
    required this.totalCount,
    this.waitingMatchCount = 0,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.totalDraws = 0,
    this.totalPoints = 0,
    required this.hasLiveMatch,
  });

  /// 進行度（0.0 〜 1.0）
  double get progressRatio =>
      totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;

  /// 進行パーセンテージ（0 〜 100%）
  int get progressPercent => (progressRatio * 100).toInt();

  /// 全試合終了フラグ（そのチーム全体の全対戦カードが終了）
  bool get isAllFinished => totalCount > 0 && completedCount >= totalCount;

  /// この対戦カード自体が終了しているかフラグ
  bool get isFinished =>
      matches.isNotEmpty &&
      matches.every((m) => m.status == 'finished' || m.status == 'approved');
}
