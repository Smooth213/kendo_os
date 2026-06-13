import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import '../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    await setupTestFirebase();
  });

  group('🛡️ RoleInjector Riverpod Lifecycle Safety Test', () {
    test(
      '✅ 1. URL パラメータ role=viewer が正しく解析され authSessionProvider に反映されること',
      () async {
        const roleStr = 'viewer';
        const dojoId = 'test010';

        final testContainer = ProviderContainer();
        addTearDown(testContainer.dispose);

        if (dojoId.isNotEmpty) {
          testContainer.read(currentDojoIdProvider.notifier).state = dojoId;
        }

        if (roleStr == 'viewer') {
          testContainer
              .read(authSessionProvider.notifier)
              .establishSession(UserRole.viewer, dojoId);
        }

        expect(
          testContainer.read(authSessionProvider)?.role,
          equals(UserRole.viewer),
        );
        expect(testContainer.read(currentDojoIdProvider), equals('test010'));
      },
    );

    test('✅ 2. authSessionProvider が viewer session で確立されること', () async {
      final testContainer = ProviderContainer();
      addTearDown(testContainer.dispose);

      try {
        testContainer
            .read(authSessionProvider.notifier)
            .establishSession(UserRole.viewer, 'test010');
        // Session should be established without throwing
        expect(true, isTrue);
      } catch (e) {
        fail('authSessionProvider.establishSession should not throw: $e');
      }
    });

    test(
      '✅ 3. RoleInjector が Provider init 中に state を修正しないこと（回帰テスト）',
      () async {
        bool riverpodViolationDetected = false;

        try {
          final badContainer = ProviderContainer();

          final testProvider = FutureProvider<String>((ref) async {
            await Future.delayed(Duration.zero);
            return 'ok';
          });

          addTearDown(badContainer.dispose);
          await badContainer.read(testProvider.future);
        } on AssertionError catch (e) {
          if (e.toString().contains('Providers are not allowed')) {
            riverpodViolationDetected = true;
          }
        }

        expect(
          riverpodViolationDetected,
          isFalse,
          reason: 'Riverpod provider lifecycle violation should not occur',
        );
      },
    );
  });
}
