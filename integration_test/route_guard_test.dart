import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/security/route_guard.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

void main() {
  group('🔒 Stage2 β - ルーティングガード＆不正昇格遮断テスト', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          firestoreRoleStreamProvider.overrideWith(
            (ref) => Stream.value(
              ref.read(authSessionProvider)?.role ?? UserRole.viewer,
            ),
          ),
          currentUserRoleProvider.overrideWith(
            (ref) => ref.read(authSessionProvider)?.role ?? UserRole.viewer,
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'Viewerロールが /settings へ直接URL直打ち遷移しようとした場合、拒絶されて選択画面へ送還されること',
      () async {
        final dojoId = container.read(currentDojoIdProvider);
        container
            .read(authSessionProvider.notifier)
            .establishSession(UserRole.viewer, dojoId);
        await Future.delayed(Duration.zero);

        final state = MockGoRouterState(Uri.parse('/settings'));

        final redirectPath = RouteGuard.watchAndProtect(
          FakeBuildContext(),
          state,
          WidgetRefMock(container),
        );

        expect(redirectPath, equals('/role-select'));
      },
    );

    test(
      'URLに role=viewer を付与して特権へ裏口昇格しようとしても、Viewer権限へ強制降格・隔離されること',
      () async {
        // 🌟 新仕様への修正：レガシーなnotifier.stateへの直接代入をパージ
        // テストの初期状態として、一度中央セッションに Admin 権限の有効セッションを確立させる
        final dojoId = container.read(currentDojoIdProvider);
        container
            .read(authSessionProvider.notifier)
            .establishSession(UserRole.admin, dojoId);
        await Future.delayed(Duration.zero);

        final state = MockGoRouterState(Uri.parse('/?role=viewer'));

        RouteGuard.watchAndProtect(
          FakeBuildContext(),
          state,
          WidgetRefMock(container),
        );

        // Providerを明示的にリフレッシュして値を再取得
        container.refresh(currentUserRoleProvider);
        final role = container.read(currentUserRoleProvider);
        expect(role, equals(UserRole.viewer));
      },
    );
  });
}

class MockGoRouterState implements GoRouterState {
  @override
  final Uri uri;

  MockGoRouterState(this.uri);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// テスト実行用の軽量Fake定義
class FakeBuildContext extends BlankBuildContext {}

abstract class BlankBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class WidgetRefMock implements WidgetRef {
  final ProviderContainer container;
  WidgetRefMock(this.container);
  @override
  T read<T>(ProviderListenable<T> provider) => container.read(provider);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
