import 'package:kendo_os/features/match/domain/match_model.dart';

/// Firestoreの試合ドキュメントを肥大化させないための段階移行codec。
class MatchEventCloudCodec {
  static const int hotEventLimit = 200;
  static const int archiveChunkSize = 200;

  const MatchEventCloudCodec._();

  static Map<String, dynamic> matchData(MatchModel match) {
    final data = match.toJson();
    if (match.events.length <= hotEventLimit) return data;
    data['events'] = match.events
        .skip(match.events.length - hotEventLimit)
        .map((event) => event.toJson())
        .toList();
    data['eventArchiveVersion'] = match.events.length;
    return data;
  }

  static Iterable<Map<String, dynamic>> archiveData(MatchModel match) sync* {
    if (match.events.length <= hotEventLimit) return;
    final coldEvents = match.events.take(match.events.length - hotEventLimit);
    for (
      var offset = 0;
      offset < coldEvents.length;
      offset += archiveChunkSize
    ) {
      final events = coldEvents
          .skip(offset)
          .take(archiveChunkSize)
          .map((event) => event.toJson())
          .toList();
      yield {
        'matchId': match.id,
        'chunkIndex': offset ~/ archiveChunkSize,
        'version': offset + events.length,
        'events': events,
      };
    }
  }
}
