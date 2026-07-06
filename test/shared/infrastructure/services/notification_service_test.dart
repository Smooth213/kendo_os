import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/infrastructure/services/notification_service.dart';

class MockRef extends Mock implements Ref {}

void main() {
  group('🛡️ NotificationService Compilation and Safe Boundary Tests', () {
    late MockRef mockRef;

    setUp(() {
      mockRef = MockRef();
    });

    test('1. NotificationService compiles and instantiates correctly', () {
      final service = NotificationService(mockRef);
      expect(service, isNotNull);
    });

    test('2. Provider successfully resolves NotificationService', () {
      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWith(
            (ref) => NotificationService(ref),
          ),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(notificationServiceProvider);
      expect(service, isNotNull);
    });

    test(
      '3. registerPushNotification returns safely if Firebase is not initialized',
      () async {
        final service = NotificationService(mockRef);
        // Firebase is not initialized in standard unit tests, so this should execute
        // the safety boundary condition and return cleanly without throwing exceptions.
        await expectLater(
          service.registerPushNotification(
            tournamentId: 'test_tournament_123',
            isStaff: true,
          ),
          completes,
        );
      },
    );
  });
}
