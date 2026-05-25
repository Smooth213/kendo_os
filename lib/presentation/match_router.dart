import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kendo_os/presentation/public/operator/match_screen.dart';
import 'package:kendo_os/presentation/public/viewer/viewer_match_screen.dart';
import '../core/security/feature_gate.dart';
import 'shared/providers/current_user_role_provider.dart';
import 'shared/providers/security_level_provider.dart';
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
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final currentRole = ref.watch(currentUserRoleProvider);
    final currentLevel = ref.watch(securityLevelProvider);

    // 🌟 修正版：FeatureGate の動的判定を最優先にする
    final bool canOperate = FeatureGate.canOperateMatch(currentRole, currentLevel);
    final bool isUrlViewer = GoRouterState.of(context).uri.queryParameters['role'] == 'viewer';

    // 動的に権限（canOperate）がない、または初期状態でURLがviewerの場合のみ隔離
    if (!canOperate || (isUrlViewer && currentRole == UserRole.viewer)) {
      return ViewerMatchScreen(matchId: matchId);
    } else {
      return MatchScreen(matchId: matchId);
    }
  }
}