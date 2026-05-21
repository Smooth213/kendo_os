import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'operate/screens/match_screen.dart'; 
import 'viewer/screens/viewer_match_screen.dart'; 
import 'operate/providers/permission_provider.dart';
import '../core/config/beta_feature_flags.dart'; // ★ 追加: β機能制限フラグのインポート

class MatchRouter extends ConsumerWidget {
  final String matchId;
  const MatchRouter({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ Phase 1-2 & 1-3: ロードマップ指定のFeature Flag（showObservability等）による全特権画面・ルートの物理封鎖
    // フラグがOFFの時は、画面をレンダリングせず、ディープリンクや不正なURL直打ちを即座に完全拒否（404・アクセス制限画面へ誘導）
    if (!BetaFeatureFlags.showObservability || !BetaFeatureFlags.showReplayTools) {
      if (matchId.startsWith('sys_') || matchId == 'observability-dashboard' || matchId == 'audit-log' || matchId == 'rule-config') {
        return const Scaffold(
          body: Center(
            child: Text(
              '🔒 アクセス制限：この機能は開発者専用モード（Internal Mode）でのみ利用可能です。',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    }

    // 🌟 Phase 6-2: ゼロトラストURLガードのインジェクション
    // 状態管理の初期化ラグを狙った特権昇格を防ぐため、URLパラメータに viewer 属性がある場合は物理的に記録画面を返さない
    final bool isUrlViewer = GoRouterState.of(context).uri.queryParameters['role'] == 'viewer';
    final permissions = ref.watch(permissionProvider);

    if (permissions.isReadOnly || isUrlViewer) {
      // 閲覧専用権限、または観客URLからのアクセスの場合は、入力ロジックが1ミリも存在しない安全な Viewer画面 へ完全隔離
      return ViewerMatchScreen(matchId: matchId);
    } else {
      // 本部スタッフかつ入力権限がある場合のみ、最速入力に特化した Scorer画面（MatchScreen）へ到達可能
      return MatchScreen(matchId: matchId);
    }
  }
}