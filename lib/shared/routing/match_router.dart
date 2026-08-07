import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kendo_os/features/tournament/presentation/operate/match_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_match_screen.dart';
import 'package:kendo_os/security/feature_gate.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/security_level_provider.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import '../domain/entities/user_role.dart'; // UserRole.viewer の評価のために追加

class MatchRouter extends ConsumerWidget {
  final String matchId;
  const MatchRouter({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔒 Phase 9: 内部開発画面へのディープリンク・直接進入の完全物理隔離
    if (matchId.startsWith('sys_') ||
        matchId == 'observability-dashboard' ||
        matchId == 'audit-log' ||
        matchId == 'rule-config') {
      return const Scaffold(
        body: Center(
          child: Text(
            '🔒 アクセス制限：指定されたページへアクセスする権限がありません。',
            style: TextStyle(fontWeight: AppFontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final currentRole = ref.watch(currentUserRoleProvider);
    final currentLevel = ref.watch(securityLevelProvider);
    final session = ref.watch(authSessionProvider);

    // 🌟 修正版：FeatureGate の動的判定を最優先にする
    final bool canOperate = FeatureGate.canOperateMatch(
      currentRole,
      currentLevel,
    );
    final bool isViewerSession = session?.role == UserRole.viewer;
    final bool isUrlViewer =
        GoRouterState.of(context).uri.queryParameters['role'] == 'viewer';

    // 動的に権限（canOperate）がない、またはViewerセッションが確立されている場合はViewer画面へ切り替え
    if (!canOperate ||
        isViewerSession ||
        (isUrlViewer && currentRole == UserRole.viewer)) {
      return ViewerMatchScreen(matchId: matchId);
    } else {
      return MatchScreen(matchId: matchId);
    }
  }
}
