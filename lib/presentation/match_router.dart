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
    // ★ Phase 1-2: Feature Flagによる未解放機能・画面のガード制御
    if (!BetaFeatureFlags.enableReplayTools && matchId.startsWith('sys_')) {
      return const Scaffold(
        body: Center(child: Text('この機能はβ版では制限されています')),
      );
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