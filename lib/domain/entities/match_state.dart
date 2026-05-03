enum MatchStatus { waiting, inProgress, finished, approved }

class MatchState {
  final int leftScore;
  final int rightScore;
  final MatchStatus status;

  const MatchState({
    required this.leftScore,
    required this.rightScore,
    required this.status,
  });
}