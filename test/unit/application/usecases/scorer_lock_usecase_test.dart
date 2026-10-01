import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/application/usecases/scorer_lock_usecase.dart';

void main() {
  group('[Unit] ScorerLockUseCase テスト', () {
    const useCase = ScorerLockUseCase();
    final baseMatch = MatchModel(
      id: 'match_1',
      matchType: '個人戦',
      redName: '赤選手',
      whiteName: '白選手',
      tournamentId: 'tournament_1',
    );

    test('記録係IDが未設定の場合に記録権限の取得に成功すること', () {
      final now = DateTime(2026, 8, 16, 12, 0);
      final updated = useCase.tryClaimScorer(baseMatch, 'user_A', now: now);

      expect(updated, isNotNull);
      expect(updated!.scorerId, 'user_A');
      expect(updated.lockExpiresAt, DateTime(2026, 8, 16, 12, 30));
    });

    test('同一ユーザーによる記録係権限の再取得が成功すること', () {
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

    test('他ユーザーによりロックされ期限内の場合、tryClaimScorerが失敗すること', () {
      final locked = baseMatch.copyWith(
        scorerId: 'user_A',
        lockExpiresAt: DateTime(2026, 8, 16, 12, 30),
      );
      final now = DateTime(2026, 8, 16, 12, 0);
      final updated = useCase.tryClaimScorer(locked, 'user_B', now: now);

      expect(updated, isNull);
    });

    test('過去のロックが期限切れの場合に記録係権限の取得に成功すること', () {
      final locked = baseMatch.copyWith(
        scorerId: 'user_A',
        lockExpiresAt: DateTime(2026, 8, 16, 11, 59),
      );
      final now = DateTime(2026, 8, 16, 12, 0);
      final updated = useCase.tryClaimScorer(locked, 'user_B', now: now);

      expect(updated, isNotNull);
      expect(updated!.scorerId, 'user_B');
    });

    test('forceClaimScorerが既存のロックを即座に上書きできること', () {
      final locked = baseMatch.copyWith(
        scorerId: 'user_A',
        lockExpiresAt: DateTime(2026, 8, 16, 12, 30),
      );
      final now = DateTime(2026, 8, 16, 12, 0);
      final updated = useCase.forceClaimScorer(locked, 'user_B', now: now);

      expect(updated.scorerId, 'user_B');
      expect(updated.lockExpiresAt, DateTime(2026, 8, 16, 12, 30));
    });

    test('releaseScorer only releases if user matchesこと', () {
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
