import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

void main() {
  group('🛡️ Representative Match Regulation Rescue Guard Tests', () {
    late MockLocalMatchRepository mockLocalRepo;

    setUp(() {
      mockLocalRepo = MockLocalMatchRepository();
      // Setup mock behaviors for MockLocalMatchRepository to avoid null exceptions during watch
      when(
        () => mockLocalRepo.watchLocalMatches(any()),
      ).thenAnswer((_) => Stream.value([]));
    });

    test(
      '1. Web environment parsing - automatically heals finished/approved/corrupted representative match with no events',
      () async {
        debugIsWebOverride = true;
        final fakeFirestore = FakeFirebaseFirestore();
        const targetTournamentId = 't_web_rep_test';

        // Insert a corrupted representative match (status = 'finished', no events)
        await fakeFirestore
            .collection('organizations')
            .doc('test202')
            .collection('tournaments')
            .doc(targetTournamentId)
            .collection('matches')
            .doc('match_rep_01')
            .set({
              'tournamentId': targetTournamentId,
              'redName': 'ウェブ赤',
              'whiteName': 'ウェブ白',
              'matchType': '代表戦',
              'status': 'finished', // should be waiting
              'order': 1.0,
              'events': [],
            });

        final container = ProviderContainer(
          overrides: [
            firestoreProvider.overrideWithValue(fakeFirestore),
            currentDojoIdProvider.overrideWith((ref) => 'test202'),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
          ],
        );

        final subscription = container.listen(
          matchListByTournamentProvider(targetTournamentId),
          (previous, next) {},
        );

        final List<MatchModel> resultMatches = await container.read(
          matchListByTournamentProvider(targetTournamentId).future,
        );

        expect(resultMatches.length, 1);
        final match = resultMatches.first;
        expect(match.id, 'match_rep_01');
        expect(match.matchType, '代表戦');
        expect(match.status, 'waiting'); // Healed!
        expect(match.timerStartedAt, isNull);

        subscription.close();
        debugIsWebOverride = false;
      },
    );

    test(
      '2. Native environment downstream sync - heals representative match and saves bulk',
      () async {
        debugIsWebOverride = false;
        final fakeFirestore = FakeFirebaseFirestore();
        const targetTournamentId = 't_native_rep_test';

        final savedMatches = <List<MatchModel>>[];
        when(() => mockLocalRepo.saveMatchesBulk(any())).thenAnswer((
          invocation,
        ) async {
          final matches = invocation.positionalArguments[0] as List<MatchModel>;
          savedMatches.add(matches);
        });

        // Insert corrupted representative match in Firestore
        await fakeFirestore
            .collection('organizations')
            .doc('test202')
            .collection('tournaments')
            .doc(targetTournamentId)
            .collection('matches')
            .doc('match_rep_02')
            .set({
              'tournamentId': targetTournamentId,
              'redName': 'ネイティブ赤',
              'whiteName': 'ネイティブ白',
              'matchType': '代表戦',
              'status': 'corrupted', // should be waiting
              'order': 2.0,
              'events': [],
            });

        final container = ProviderContainer(
          overrides: [
            firestoreProvider.overrideWithValue(fakeFirestore),
            currentDojoIdProvider.overrideWith((ref) => 'test202'),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
          ],
        );

        final subscription = container.listen(
          matchListByTournamentProvider(targetTournamentId),
          (previous, next) {},
        );

        // Give sync list listener some time to process downstream Firestore snapshots
        await Future.delayed(const Duration(milliseconds: 500));

        expect(savedMatches.isNotEmpty, isTrue);
        final firstBulk = savedMatches.first;
        expect(firstBulk.length, 1);
        final match = firstBulk.first;
        expect(match.id, 'match_rep_02');
        expect(match.status, 'waiting'); // Healed!
        expect(match.timerStartedAt, isNull);

        subscription.close();
      },
    );

    test('3. Bunaiksen stream provider - heals representative match', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      const targetTournamentId = 'bunaiksen_rep_test';

      // Insert corrupted representative match in Firestore
      await fakeFirestore
          .collection('organizations')
          .doc('test202')
          .collection('tournaments')
          .doc(targetTournamentId)
          .collection('matches')
          .doc('match_rep_03')
          .set({
            'tournamentId': targetTournamentId,
            'redName': '部内戦赤',
            'whiteName': '部内戦白',
            'matchType': '代表戦',
            'status': 'approved', // should be waiting
            'order': 3.0,
            'events': [],
          });

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
          currentDojoIdProvider.overrideWith((ref) => 'test202'),
          localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
        ],
      );

      final subscription = container.listen(
        bunaiksenMatchesStreamProvider(targetTournamentId),
        (previous, next) {},
      );

      final List<MatchModel> resultMatches = await container.read(
        bunaiksenMatchesStreamProvider(targetTournamentId).future,
      );

      expect(resultMatches.length, 1);
      final match = resultMatches.first;
      expect(match.id, 'match_rep_03');
      expect(match.status, 'waiting'); // Healed!
      expect(match.timerStartedAt, isNull);

      subscription.close();
    });
  });
}
