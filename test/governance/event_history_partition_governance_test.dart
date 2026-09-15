import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_event_cloud_codec.dart';

void main() {
  group('イベント履歴分割ガバナンス', () {
    test('イベント本体上限とチャンク上限が定義されている', () {
      expect(MatchEventCloudCodec.hotEventLimit, 200);
      expect(MatchEventCloudCodec.archiveChunkSize, 200);
    });

    test('450件の履歴を本体200件とアーカイブ2チャンクへ分割する', () {
      final events = List.generate(
        450,
        (index) => ScoreEvent(
          id: 'event_$index',
          side: Side.red,
          timestamp: DateTime.fromMillisecondsSinceEpoch(index),
        ),
      );
      final match = MatchModel(
        id: 'governance_match',
        matchType: 'individual',
        redName: '赤',
        whiteName: '白',
        events: events,
      );

      final data = MatchEventCloudCodec.matchData(match);
      final archives = MatchEventCloudCodec.archiveData(match).toList();

      expect((data['events'] as List).length, 200);
      expect(data['eventArchiveVersion'], 450);
      expect(archives.length, 2);
      expect(
        archives.expand((archive) => archive['events'] as List).length,
        250,
      );
    });

    test('分割保存・削除の契約がコードとRulesに存在する', () {
      final repository = File(
        'lib/shared/infrastructure/repository/match_repository.dart',
      ).readAsStringSync();
      final rules = File('firestore.rules').readAsStringSync();

      expect(repository.contains("collection('events')"), isTrue);
      expect(repository.contains('batch.delete(chunk.reference)'), isTrue);
      expect(rules.contains('match /events/{eventChunkId}'), isTrue);
    });
  });
}
