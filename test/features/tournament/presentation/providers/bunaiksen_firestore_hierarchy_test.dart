import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

void main() {
  group('🛡️ Bunaiksen Firestore Hierarchy Verification Tests', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test(
      '1. Guest Player registration saves under the correct organization, tournament (date), and guest name subcollection path',
      () async {
        final targetDojoId = 'dojo_chiba_abc';
        final targetDate = DateTime(2026, 7, 3);
        final expectedDateStr = DateFormat('yyyyMMdd').format(targetDate);
        final expectedTournamentId = 'bunaiksen_$expectedDateStr';

        final container = ProviderContainer(
          overrides: [
            firestoreProvider.overrideWithValue(fakeFirestore),
            currentDojoIdProvider.overrideWith((ref) => targetDojoId),
            bunaiksenViewDateProvider.overrideWith((ref) => targetDate),
          ],
        );
        addTearDown(container.dispose);

        // Add guest player
        final notifier = container.read(bunaiksenGuestProvider.notifier);
        await notifier.addGuest('坂本 竜馬');

        // Verify the document exists at the exact hierarchical path
        final docRef = fakeFirestore
            .collection('organizations')
            .doc(targetDojoId)
            .collection('tournaments')
            .doc(expectedTournamentId)
            .collection('bunaiksen_guests')
            .doc('坂本 竜馬');

        final snapshot = await docRef.get();
        expect(snapshot.exists, true);
        expect(snapshot.data()?['name'], '坂本 竜馬');
      },
    );

    test(
      '2. Practice Match creation saves under the correct organization, tournament (date), and match ID subcollection path',
      () async {
        final targetDojoId = 'dojo_kanagawa_xyz';
        final targetDate = DateTime(2026, 7, 3);
        final expectedDateStr = DateFormat('yyyyMMdd').format(targetDate);
        final expectedTournamentId = 'bunaiksen_$expectedDateStr';
        final matchId = 'test_match_id_001';

        final matchModel = MatchModel(
          id: matchId,
          tournamentId: expectedTournamentId,
          organizationId: targetDojoId,
          groupName: 'infinite_$expectedDateStr',
          matchType: '無限勝ち抜き',
          redName: '選手A',
          whiteName: '選手B',
          matchTimeMinutes: 3.0,
          status: 'waiting',
          version: 1,
        );

        final matchRepository = MatchRepository(fakeFirestore, targetDojoId);

        // Save the match
        await matchRepository.saveMatch(matchModel);

        // Verify the document exists at the exact hierarchical path
        final docRef = fakeFirestore
            .collection('organizations')
            .doc(targetDojoId)
            .collection('tournaments')
            .doc(expectedTournamentId)
            .collection('matches')
            .doc(matchId);

        final snapshot = await docRef.get();
        expect(snapshot.exists, true);
        expect(snapshot.data()?['redName'], '選手A');
        expect(snapshot.data()?['whiteName'], '選手B');
        expect(snapshot.data()?['matchType'], '無限勝ち抜き');
      },
    );
  });
}
