import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/services/match_persistence_helper.dart';

void main() {
  group('[Unit] MatchPersistenceHelper 単体テスト', () {
    test('Can be instantiated properly with Refであること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final helper = MatchPersistenceHelper(
        container.read(Provider((ref) => ref)),
      );
      expect(helper, isNotNull);
    });
  });
}
