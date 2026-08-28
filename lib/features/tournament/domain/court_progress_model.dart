import 'package:kendo_os/features/match/domain/match_model.dart';

/// 🥋 コート別進行ステータスモデル
class CourtProgressStatus {
  final String courtName;
  final String categoryName;
  final String matchupTitle;
  final String detailNote;
  final List<MatchModel> matches;
  final MatchModel? inProgressMatch;
  final MatchModel? lastFinishedMatch;
  final MatchModel? nextWaitingMatch;
  final int completedCount;
  final int totalCount;
  final bool hasLiveMatch;
  final bool hasMyDojoMatch;

  const CourtProgressStatus({
    required this.courtName,
    this.categoryName = '',
    this.matchupTitle = '',
    this.detailNote = '',
    required this.matches,
    this.inProgressMatch,
    this.lastFinishedMatch,
    this.nextWaitingMatch,
    required this.completedCount,
    required this.totalCount,
    required this.hasLiveMatch,
    required this.hasMyDojoMatch,
  });

  double get progressRatio =>
      totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;

  int get progressPercent => (progressRatio * 100).toInt();
}
