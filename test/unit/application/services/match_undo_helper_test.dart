import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/services/match_persistence_helper.dart';
import 'package:kendo_os/features/match/application/services/match_undo_helper.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ MatchUndoHelper Unit Tests', () {
    test('1. MatchUndoHelper can be instantiated properly', () {
      final container = ProviderContainer(
        overrides: [isarProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);
      final ref = container.read(Provider((ref) => ref));

      final persistenceHelper = MatchPersistenceHelper(ref);
      final addScoreUseCase = container.read(addScoreUseCaseProvider);

      final helper = MatchUndoHelper(ref, addScoreUseCase, persistenceHelper);

      expect(helper, isNotNull);
    });

    test(
      '2. executeUndo handles empty events gracefully without throwing',
      () async {
        final container = ProviderContainer(
          overrides: [isarProvider.overrideWithValue(null)],
        );
        addTearDown(container.dispose);
        final ref = container.read(Provider((ref) => ref));

        final persistenceHelper = MatchPersistenceHelper(ref);
        final addScoreUseCase = container.read(addScoreUseCaseProvider);

        final helper = MatchUndoHelper(ref, addScoreUseCase, persistenceHelper);

        const currentUser = User(
          id: 'u1',
          role: Role.admin,
          organizationId: 'org1',
        );

        // 存在しない試合IDでのUndo実行（例外なく安全終了）
        await expectLater(
          helper.executeUndo(
            matchId: 'non_existent_match',
            currentUser: currentUser,
            traceId: 'trace-1',
          ),
          completes,
        );
      },
    );
  });
}
