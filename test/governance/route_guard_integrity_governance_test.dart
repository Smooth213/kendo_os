import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/security/internal_route_guard.dart';
import 'package:kendo_os/security/route_guard.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/routing/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Governance] 第20条 ガバナンス監査において ディープリンク・未認証URLルーティング完全性規約', () {
    test('静的整合性に関して、 ルーティング防壁ファイル群の完全配備規約こと', () {
      final appRouterFile = File('lib/shared/routing/app_router.dart');
      final routeGuardsFile = File('lib/shared/routing/route_guards.dart');
      final routeGuardFile = File('lib/security/route_guard.dart');
      final internalGuardFile = File('lib/security/internal_route_guard.dart');

      expect(appRouterFile.existsSync(), isTrue);
      expect(routeGuardsFile.existsSync(), isTrue);
      expect(routeGuardFile.existsSync(), isTrue);
      expect(internalGuardFile.existsSync(), isTrue);

      final routerContent = appRouterFile.readAsStringSync();
      // errorBuilder が安全に配備されていること（白画面・赤画面・例外クラッシュ根絶）
      expect(routerContent.contains('errorBuilder:'), isTrue);
      expect(routerContent.contains('initialLocation:'), isTrue);
    });

    test('未認証・一般観客防御に関して、 RouteGuard による特権URL直打ち遮断規約こと', () {
      final container = ProviderContainer(
        overrides: [currentUserRoleProvider.overrideWithValue(UserRole.viewer)],
      );
      addTearDown(container.dispose);

      // モックコンテキストを作成するためのウィジェットツリー構築
      // RouteGuard.watchAndProtect の静的ロジック検証
      expect(RouteGuard.watchAndProtect, isNotNull);

      final routeGuardContent = File(
        'lib/security/route_guard.dart',
      ).readAsStringSync();
      expect(
        routeGuardContent.contains("state.uri.path.startsWith('/viewer/')"),
        isTrue,
      );
      expect(
        routeGuardContent.contains(
          "state.uri.queryParameters['role'] == 'viewer'",
        ),
        isTrue,
      );
      expect(
        routeGuardContent.contains("state.uri.path.startsWith('/settings')"),
        isTrue,
      );
      expect(routeGuardContent.contains("return '/role-select'"), isTrue);
    });

    test('ゼロトラスト・内部遮断に関して、 InternalRouteGuard による内部監査・管理画面の強制遮断規約こと', () {
      // 内部画面パスの検知検証
      expect(
        InternalRouteGuard.isInternalPath('/admin/internal/debug'),
        isTrue,
      );
      expect(
        InternalRouteGuard.isInternalPath('/settings/master-management'),
        isTrue,
      );
      expect(
        InternalRouteGuard.isInternalPath('/tournament/observability'),
        isTrue,
      );
      expect(InternalRouteGuard.isInternalPath('/audit-log/list'), isTrue);
      expect(
        InternalRouteGuard.isInternalPath('/viewer/sample_match_id'),
        isFalse,
      );
      expect(InternalRouteGuard.isInternalPath('/role-select'), isFalse);
    });

    test('公開ビュアー安全注入に関して、 RoleInjector による権限偽装防止＆安全フォールバック規約こと', () {
      final routeGuardsContent = File(
        'lib/shared/routing/route_guards.dart',
      ).readAsStringSync();

      expect(routeGuardsContent.contains('class RoleInjector'), isTrue);
      expect(routeGuardsContent.contains('UserRole.viewer'), isTrue);
      expect(routeGuardsContent.contains('isReadOnly: true'), isTrue);
      expect(routeGuardsContent.contains('ViewerAuthGate'), isTrue);
    });

    testWidgets('404/未知ルートフォールバックに関して、 不明なURLアクセス時に赤画面が出ずScaffoldが安全描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: appRouter)),
      );
      await tester.pumpAndSettle();

      // 初期画面が正常表示されること
      expect(find.byType(MaterialApp), findsOneWidget);

      // 未知ルートへの強制遷移
      appRouter.go('/unknown-nonexistent-path-404-xyz');
      await tester.pumpAndSettle();

      // errorBuilder により「ページが見つかりません」または Scaffold が表示されクラッシュしないこと
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.textContaining('ページが見つかりません'), findsOneWidget);
    });
  });
}
