import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/application/usecases/scorer_lock_usecase.dart';

void main() {
  group('🛡️ ScorerLockUseCase Tests', () {
    const useCase = ScorerLockUseCase();
    final baseMatch = MatchModel(
      id: 'match_1',
      matchType: '個人戦',
      redName: '赤選手',
      whiteName: '白選手',
      tournamentId: 'tournament_1',
    );

    test('tryClaimScorer succeeds when scorerId is null', () {
      final now = DateTime(2026, 8, 16, 12, 0);
      final updated = useCase.tryClaimScorer(baseMatch, 'user_A', now: now);

      expect(updated, isNotNull);
      expect(updated!.scorerId, 'user_A');
      expect(updated.lockExpiresAt, DateTime(2026, 8, 16, 12, 30));
    });

    test('tryClaimScorer succeeds when claimed by same user', () {
      final locked = baseMatch.copyWith(
        scorerId: 'user_A',
        lockExpiresAt: DateTime(2026, 8, 16, 12, 10),
      );
      final now = DateTime(2026, 8, 16, 12, 0);
      final updated = useCase.tryClaimScorer(locked, 'user_A', now: now);

      expect(updated, isNotNull);
      expect(updated!.scorerId, 'user_A');
      expect(updated.lockExpiresAt, DateTime(2026, 8, 16, 12, 30));
    });

    test(
      'tryClaimScorer fails when locked by different user and not expired',
      () {
        final locked = baseMatch.copyWith(
          scorerId: 'user_A',
          lockExpiresAt: DateTime(2026, 8, 16, 12, 30),
        );
        final now = DateTime(2026, 8, 16, 12, 0);
        final updated = useCase.tryClaimScorer(locked, 'user_B', now: now);

        expect(updated, isNull);
      },
    );

    test('tryClaimScorer succeeds when previous lock is expired', () {
      final locked = baseMatch.copyWith(
        scorerId: 'user_A',
        lockExpiresAt: DateTime(2026, 8, 16, 11, 59),
      );
      final now = DateTime(2026, 8, 16, 12, 0);
      final updated = useCase.tryClaimScorer(locked, 'user_B', now: now);

      expect(updated, isNotNull);
      expect(updated!.scorerId, 'user_B');
    });

    test('forceClaimScorer overrides existing lock immediately', () {
      final locked = baseMatch.copyWith(
        scorerId: 'user_A',
        lockExpiresAt: DateTime(2026, 8, 16, 12, 30),
      );
      final now = DateTime(2026, 8, 16, 12, 0);
      final updated = useCase.forceClaimScorer(locked, 'user_B', now: now);

      expect(updated.scorerId, 'user_B');
      expect(updated.lockExpiresAt, DateTime(2026, 8, 16, 12, 30));
    });

    test('releaseScorer only releases if user matches', () {
      final locked = baseMatch.copyWith(
        scorerId: 'user_A',
        lockExpiresAt: DateTime(2026, 8, 16, 12, 30),
      );

      final failed = useCase.releaseScorer(locked, 'user_B');
      expect(failed, isNull);

      final succeeded = useCase.releaseScorer(locked, 'user_A');
      expect(succeeded, isNotNull);
      expect(succeeded!.scorerId, isNull);
      expect(succeeded.lockExpiresAt, isNull);
    });
  });
}
