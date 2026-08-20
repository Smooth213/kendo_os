import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/manual_index_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ manualIndexProvider Tests', () {
    test('Provider exists and is a FutureProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(manualIndexProvider), isA<AsyncValue>());
    });
  });
}
