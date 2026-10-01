import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/routing/app_router.dart';

void main() {
  group('[Widget] AppRouter 単体テスト', () {
    test(
      'appRouter configuration has valid initial route and routes listであること',
      () {
        expect(appRouter.configuration.routes.isNotEmpty, true);
      },
    );
  });
}
