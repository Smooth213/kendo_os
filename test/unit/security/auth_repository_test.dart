import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/infrastructure/repository/auth_repository.dart';

void main() {
  group('[Unit] AuthRepository 単体テスト', () {
    test('プロバイダからAuthRepositoryが正常に解決されること', () {
      final container = ProviderContainer();
      final repo = container.read(authRepositoryProvider);
      expect(repo, isNotNull);
      expect(repo, isA<AuthRepository>());
    });

    test('Firebase未初期化環境においてauthStateChangesがnullのStreamを安全に返却すること', () async {
      final repo = AuthRepository();
      final stream = repo.authStateChanges;

      final firstValue = await stream.first;
      expect(firstValue, isNull);
    });

    test('signOut実行時に例外が発生しても上位に漏洩せず安全に終了すること', () async {
      final repo = AuthRepository();
      // テスト環境下でFirebase未初期化でもtry-catchにより例外が安全に吸収されること
      await expectLater(repo.signOut(), completes);
    });
  });
}
