class MatchCorruptionException implements Exception {
  final String message;
  final String? matchId;

  MatchCorruptionException(this.message, {this.matchId});

  @override
  String toString() => 'MatchCorruptionException: $message${matchId != null ? ' (Match ID: $matchId)' : ''}';
}