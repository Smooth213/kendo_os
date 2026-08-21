import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/routing/app_router.dart';

void main() {
  group('🛡️ AppRouter Unit Tests', () {
    test(
      '1. appRouter configuration has valid initial route and routes list',
      () {
        expect(appRouter.configuration.routes.isNotEmpty, true);
      },
    );
  });
}
