import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'match_screen.dart'; 
import 'viewer_match_screen.dart'; 
import '../presentation/provider/permission_provider.dart';

class MatchRouter extends ConsumerWidget {
  final String matchId;
  const MatchRouter({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionProvider);

    // ★ Phase 5: 権限に応じて画面を「物理的に」分離する
    if (permissions.isReadOnly) {
      // 閲覧専用権限なら、入力ロジックが一切ない安全な Viewer画面 へ
      return ViewerMatchScreen(matchId: matchId);
    } else {
      // 入力権限があるなら、最速入力に特化した Scorer画面（既存のMatchScreen）へ
      return MatchScreen(matchId: matchId);
    }
  }
}