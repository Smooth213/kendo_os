import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

void main() {
  group(
    '🛡️ Representative Match Regulation Rescue Guard (Bunaiksen Integration) Tests',
    () {
      late MockLocalMatchRepository mockLocalRepo;

      setUp(() {
        mockLocalRepo = MockLocalMatchRepository();
        when(
          () => mockLocalRepo.watchLocalMatches(any()),
        ).thenAnswer((_) => Stream.value([]));
      });

      test(
        '1. [未開始の代表戦における汚染ステート自動中和] - empty events + corrupted/finished status => waiting',
        () async {
          debugIsWebOverride = true;
          final fakeFirestore = FakeFirebaseFirestore();
          const targetTournamentId = 'bunaiksen_rep_heal_test';

          // モックドキュメントを用意 (eventsが空、statusがfinishedまたはcorrupted)
          await fakeFirestore
              .collection('organizations')
              .doc('test202')
              .collection('tournaments')
              .doc(targetTournamentId)
              .collection('matches')
              .doc('match_corrupted_01')
              .set({
                'tournamentId': targetTournamentId,
                'redName': '代表赤',
                'whiteName': '代表白',
                'matchType': '代表戦',
                'status': 'finished', // 汚染されたステータス
                'order': 1.0,
                'events': [],
              });

          await fakeFirestore
              .collection('organizations')
              .doc('test202')
              .collection('tournaments')
              .doc(targetTournamentId)
              .collection('matches')
              .doc('match_corrupted_02')
              .set({
                'tournamentId': targetTournamentId,
                'redName': '代表赤',
                'whiteName': '代表白',
                'matchType': '代表戦',
                'status': 'corrupted', // 汚染されたステータス
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

          final List<MatchModel> resultMatches = await container.read(
            matchListByTournamentProvider(targetTournamentId).future,
          );

          expect(resultMatches.length, 2);

          // match_corrupted_01 (finished) が waiting へ自動修復されていること
          final match01 = resultMatches.firstWhere(
            (m) => m.id == 'match_corrupted_01',
          );
          expect(match01.status, 'waiting');
          expect(match01.timerStartedAt, isNull);

          // match_corrupted_02 (corrupted) が waiting へ自動修復されていること
          final match02 = resultMatches.firstWhere(
            (m) => m.id == 'match_corrupted_02',
          );
          expect(match02.status, 'waiting');
          expect(match02.timerStartedAt, isNull);

          subscription.close();
          debugIsWebOverride = false;
        },
      );

      test(
        '2. [打突開始後の代表戦におけるステート保護] - has events + finished status => remains finished',
        () async {
          debugIsWebOverride = true;
          final fakeFirestore = FakeFirebaseFirestore();
          const targetTournamentId = 'bunaiksen_rep_protect_test';

          // 既に有効な打突ポイント（メン一本）が記録されているモック
          final menEventJson = {
            'id': 'event_men_01',
            'schemaVersion': 2,
            'side': 'red',
            'strikeType': 'men',
            'isIppon': true,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'signature': 'test_signature',
          };

          await fakeFirestore
              .collection('organizations')
              .doc('test202')
              .collection('tournaments')
              .doc(targetTournamentId)
              .collection('matches')
              .doc('match_legit_finished')
              .set({
                'tournamentId': targetTournamentId,
                'redName': '代表赤',
                'whiteName': '代表白',
                'matchType': '代表戦',
                'status': 'finished', // 正当な終了ステータス
                'order': 1.0,
                'events': [menEventJson],
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
          expect(match.id, 'match_legit_finished');
          expect(match.status, 'finished'); // 誤上書きされず、finishedが維持されていること
          expect(match.events.length, 1);
          expect(match.events.first.strikeType, StrikeType.men);

          subscription.close();
          debugIsWebOverride = false;
        },
      );
    },
  );
}
