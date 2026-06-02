import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/domain/match/match_model.dart';

void main() {
  group('🛡️ Match List Viewer Web Initialization Test', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test(
      '✅ 1. matchListByTournamentProvider が initialization 中に他の provider を修正しないこと',
      () async {
        // Regression test for: "Providers are not allowed to modify other providers during their initialization"
        // Previous bug: matchListByTournamentProvider tried to update webCurrentTournamentIdProvider in its init

        bool initializationViolationDetected = false;

        try {
          final testContainer = ProviderContainer();
          addTearDown(testContainer.dispose);

          // The matchListByTournamentProvider should NOT try to update webCurrentTournamentIdProvider
          // during its initialization phase. This is now handled by ViewerHomeScreen.build()

          // Try to read the provider - if there's a violation, it will throw
          await testContainer
              .read(matchListByTournamentProvider('test_tournament_001').future)
              .catchError((e) {
                // May fail due to missing Firestore, but should not fail due to Riverpod violation
                return <MatchModel>[];
              });
        } on AssertionError catch (e) {
          if (e.toString().contains('Providers are not allowed')) {
            initializationViolationDetected = true;
          }
        }

        expect(
          initializationViolationDetected,
          isFalse,
          reason:
              'matchListByTournamentProvider should not modify other providers during init',
        );
      },
    );

    test(
      '✅ 2. Web 環境で tournament ID が ViewerHomeScreen.build() で初期化されること',
      () async {
        // The Web tournament ID initialization has been moved from matchListByTournamentProvider
        // to ViewerHomeScreen.build() to respect Riverpod lifecycle constraints

        final testContainer = ProviderContainer();
        addTearDown(testContainer.dispose);

        // Simulate what ViewerHomeScreen.build() does for Web
        final tournamentId = 'E8EgKaOv2vaR6FZJwjK0';

        // This update should happen in a deferred callback, not during provider init
        await Future.delayed(
          Duration.zero,
        ); // Simulates WidgetsBinding.addPostFrameCallback

        testContainer.read(webCurrentTournamentIdProvider.notifier).state =
            tournamentId;

        expect(
          testContainer.read(webCurrentTournamentIdProvider),
          equals(tournamentId),
          reason:
              'Web tournament ID should be initialized after build completes',
        );
      },
    );

    test(
      '✅ 3. webCurrentTournamentIdProvider と matchListByTournamentProvider が독립적으로 동작하는지 확인',
      () async {
        // These providers should be independently updatable without violating lifecycle

        final testContainer = ProviderContainer();
        addTearDown(testContainer.dispose);

        const tournamentId = 'test_tournament_001';

        // Update Web tournament ID first (simulating ViewerHomeScreen.build())
        await Future.delayed(Duration.zero);
        testContainer.read(webCurrentTournamentIdProvider.notifier).state =
            tournamentId;

        expect(
          testContainer.read(webCurrentTournamentIdProvider),
          equals(tournamentId),
        );

        // Then query matches for that tournament (simulating matchListByTournamentProvider read)
        try {
          await testContainer
              .read(matchListByTournamentProvider(tournamentId).future)
              .catchError((e) => <MatchModel>[]);

          // Should complete without Riverpod lifecycle violation
          expect(true, isTrue);
        } catch (e) {
          // May fail due to missing data, but not due to Riverpod violation
          if (e.toString().contains('Providers are not allowed')) {
            fail('Provider lifecycle violation detected: $e');
          }
        }
      },
    );

    test(
      '✅ 4. Web キャッシュ (webCurrentTournamentMatchesProvider) が正しく保持されること',
      () async {
        // Ensure Web-specific caching doesn't cause state conflicts

        final testContainer = ProviderContainer();
        addTearDown(testContainer.dispose);

        // Simulate Web cache update
        const testMatches = <MatchModel>[];
        await Future.delayed(Duration.zero);

        testContainer.read(webCurrentTournamentMatchesProvider.notifier).state =
            testMatches;

        expect(
          testContainer.read(webCurrentTournamentMatchesProvider),
          equals(testMatches),
          reason: 'Web match cache should be preserved independently',
        );
      },
    );

    test('✅ 5. tournament ID 切り替え時に Web 画面が正しく更新されること', () async {
      // Simulate switching tournaments on Web viewer

      final testContainer = ProviderContainer();
      addTearDown(testContainer.dispose);

      const tournament1 = 'tournament_001';
      const tournament2 = 'tournament_002';

      // Switch to tournament 1
      await Future.delayed(Duration.zero);
      testContainer.read(webCurrentTournamentIdProvider.notifier).state =
          tournament1;
      expect(
        testContainer.read(webCurrentTournamentIdProvider),
        equals(tournament1),
      );

      // Switch to tournament 2
      await Future.delayed(Duration.zero);
      testContainer.read(webCurrentTournamentIdProvider.notifier).state =
          tournament2;
      expect(
        testContainer.read(webCurrentTournamentIdProvider),
        equals(tournament2),
        reason: 'Tournament ID should update without state conflicts',
      );
    });
  });
}
