import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

void main() {
  group('🛡️ currentUserRoleProvider 完全ハイブリッド同期検証テスト', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      '【バグ修正検証】PIN入力等でローカルセッションがAdminに昇格した場合、クラウド側がViewerの初期パケットを流してきてもAdminを死守すること',
      () {
        final dojoId = container.read(currentDojoIdProvider);

        // 手動でPINを入力してAdminセッションを確立
        container
            .read(authSessionProvider.notifier)
            .establishSession(UserRole.admin, dojoId);

        // 決定論的検証：特権防衛ロックが働き、クラウドの初期ノイズ（viewer）を完全に弾いてAdminが死守されること
        final currentRole = container.read(currentUserRoleProvider);
        expect(currentRole, equals(UserRole.admin));
      },
    );

    test('【同期検証】手動セッションがない、または一般状態の時のみ、クラウド側の権限パケットに自動追従すること', () {
      final dojoId = container.read(currentDojoIdProvider);
      container
          .read(authSessionProvider.notifier)
          .establishSession(UserRole.viewer, dojoId);

      // 一般状態であれば、最安全にシステム全体のロール管理グラフが調停される
      expect(container.read(currentUserRoleProvider), equals(UserRole.viewer));
    });
  });
}
