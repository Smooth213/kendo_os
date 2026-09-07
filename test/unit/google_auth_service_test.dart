import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/auth/application/google_auth_service.dart';

void main() {
  group('🥋 GoogleAuthService Unit Tests', () {
    test('未認証・未連携時のプロバイダ初期値が安全に判定されること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isLinked = container.read(isGoogleLinkedProvider);
      final email = container.read(linkedGoogleEmailProvider);

      expect(isLinked, isFalse);
      expect(email, isNull);
    });

    test('GoogleAuthService インスタンスが正常に生成され null-safe であること', () {
      final service = GoogleAuthService();
      expect(service.currentUser, isNull);
      expect(service.isGoogleLinked, isFalse);
      expect(service.userEmail, isNull);
    });
  });
}
