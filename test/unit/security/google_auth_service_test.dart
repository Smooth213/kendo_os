import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/auth/application/google_auth_service.dart';

void main() {
  group('[Unit] GoogleAuthService 単体テスト', () {
    test('未認証・未連携時のプロバイダ初期値が安全に判定されること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isLinked = container.read(isGoogleLinkedProvider);
      final email = container.read(linkedGoogleEmailProvider);

      expect(isLinked, isFalse);
      expect(email, isNull);
    });

    test('GoogleAuthService インスタンスが正常に生成され null-safeこと', () {
      final service = GoogleAuthService();
      addTearDown(service.dispose);
      expect(service.currentUser, isNull);
      expect(service.isGoogleLinked, isFalse);
      expect(service.userEmail, isNull);
    });

    test('notifyUserChangedによりuserChangesストリームへ即座に更新イベントが流れること', () async {
      final service = GoogleAuthService();
      addTearDown(service.dispose);

      final events = <dynamic>[];
      final sub = service.userChanges.listen(events.add);
      addTearDown(sub.cancel);

      // 初回購読イベント（null）
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(events, contains(null));

      // 明示的な通知
      service.notifyUserChanged(null);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(events.length, greaterThanOrEqualTo(2));
    });
  });
}
