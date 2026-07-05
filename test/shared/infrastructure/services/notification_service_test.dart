import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/infrastructure/services/notification_service.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';

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
  });
}
