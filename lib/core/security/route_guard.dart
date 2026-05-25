import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_role.dart';
import '../../presentation/shared/providers/auth_session_provider.dart';
import '../../presentation/shared/providers/current_user_role_provider.dart';
import '../../presentation/shared/providers/current_sync_context_provider.dart';

/// URLの直打ちや裏口からの特権画面進入をパケットレベルで監視・ブロックするルーティングゲート。
class RouteGuard {
  static String? watchAndProtect(BuildContext context, GoRouterState state, WidgetRef ref) {
    final currentRole = ref.read(currentUserRoleProvider);
    final dojoId = ref.read(currentDojoIdProvider);

    // 🔒 1. Viewer専用URL（/viewer/{id}）へのアクセス時は、権限を安全なViewerへ強制固定
    if (state.uri.path.startsWith('/viewer/')) {
      if (currentRole != UserRole.viewer) {
        ref.read(authSessionProvider.notifier).establishSession(UserRole.viewer, dojoId);
      }
      return null;
    }

    // 🔒 2. 不正パラメータ（?role=viewer）による裏口偽装検知時の安全隔離
    if (state.uri.queryParameters['role'] == 'viewer') {
      ref.read(authSessionProvider.notifier).establishSession(UserRole.viewer, dojoId);
      return null;
    }

    // 🔒 3. 強制Viewer導線：一般観客席状態の端末が、本部運営URLまたはシステム設定へ直打ち進入した場合は即時送還
    if (currentRole == UserRole.viewer && 
       (state.uri.path.startsWith('/settings') || state.uri.path.startsWith('/operate'))) {
      return '/role-select';
    }

    return null;
  }
}