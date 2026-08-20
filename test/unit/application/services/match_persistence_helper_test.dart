import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/services/match_persistence_helper.dart';

void main() {
  group('🛡️ MatchPersistenceHelper Unit Tests', () {
    test('Can be instantiated properly with Ref', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final helper = MatchPersistenceHelper(
        container.read(Provider((ref) => ref)),
      );
      expect(helper, isNotNull);
    });
  });
}
