import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';

void main() {
  group('イベント履歴分割E2E', () {
    late FakeFirebaseFirestore firestore;
    late MatchRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = MatchRepository(firestore, 'e2e_org', 'e2e_tournament');
    });

    test('長期イベント履歴を分割保存し、再読込後に全件復元して削除できる', () async {
      final events = List.generate(
        450,
        (index) => ScoreEvent(
          id: 'e2e_event_$index',
          side: Side.red,
          timestamp: DateTime.fromMillisecondsSinceEpoch(index),
        ),
      );
      final match = MatchModel(
        id: 'e2e_partition_match',
        tournamentId: 'e2e_tournament',
        matchType: 'individual',
        redName: '赤',
        whiteName: '白',
        events: events,
      );

      await repository.saveMatch(match);

      final matchRef = firestore
          .collection('organizations')
          .doc('e2e_org')
          .collection('tournaments')
          .doc('e2e_tournament')
          .collection('matches')
          .doc(match.id);
      final matchSnapshot = await matchRef.get();
      final chunks = await matchRef.collection('events').get();
      final restored = await repository.watchSingleMatch(match.id).first;

      expect((matchSnapshot.data()?['events'] as List).length, 200);
      expect(chunks.docs.length, 2);
      expect(restored.events.length, 450);
      expect(restored.events.first.id, events.first.id);
      expect(restored.events.last.id, events.last.id);

      await repository.deleteMatch(match.id);
      expect((await matchRef.get()).exists, isFalse);
      expect((await matchRef.collection('events').get()).docs, isEmpty);
    });
  });
}
