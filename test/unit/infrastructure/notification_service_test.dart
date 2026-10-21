import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/infrastructure/services/notification_service.dart';

class MockRef extends Mock implements Ref {}

void main() {
  group('[Unit] NotificationService Compilation and Safe Boundary テスト', () {
    late MockRef mockRef;

    setUp(() {
      mockRef = MockRef();
    });

    test('NotificationServiceが正常にコンパイルおよびインスタンス化されること', () {
      final service = NotificationService(mockRef);
      expect(service, isNotNull);
    });

    test('ProviderからNotificationServiceが正常に解決されること', () {
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

    test('Firebase未初期化時にregisterPushNotificationが安全に復帰すること', () async {
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
    });
  });
}
