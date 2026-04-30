import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'match/widgets/scoreboard.dart';
import 'match/widgets/match_header.dart';
import 'match/widgets/timer_widget.dart';
import '../presentation/provider/viewer_view_state_provider.dart';

class ViewerMatchScreen extends ConsumerWidget {
  final String matchId;
  const ViewerMatchScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 完全に分離されたViewStateを監視
    final viewState = ref.watch(viewerViewStateProvider(matchId));

    if (viewState.statusText == 'エラー') {
      return const Scaffold(body: Center(child: Text('試合データが見つかりません')));
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white, 
      appBar: MatchHeader(
        matchId: matchId,
        isInputLocked: true, 
      ),
      body: Column(
        children: [
          // 閲覧専用バナー ＆ リアルタイムステータス表示
          Container(
            width: double.infinity,
            color: Colors.blueGrey.shade700,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('観客席 (Viewer)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Text(
                  '${viewState.statusText} | 直前: ${viewState.lastEventText}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          TimerWidget(matchId: matchId, isInputLocked: true),
          // 👇 観戦者向けのスコア確認ボタン（公式記録を削除し、スコア表のみ横幅いっぱいに表示）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // 遷移先も安全な Viewer 専用パスに変更
                  if (viewState.isKachinuki) {
                    context.push('/viewer-kachinuki/${viewState.groupName}');
                  } else {
                    context.push('/viewer-team/${viewState.groupName}');
                  }
                },
                icon: Icon(viewState.isKachinuki ? Icons.timeline : Icons.table_chart_outlined, size: 16),
                label: const Text('現在のスコア表', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  minimumSize: const Size(0, 36), 
                  padding: EdgeInsets.zero
                ),
              ),
            ),
          ),
          // 👆 ここまで
          Expanded(
            child: MatchScoreboard(
              matchId: matchId, 
              myUserId: 'viewer',
              onNameTap: (side) {}, 
            ),
          ),
        ],
      ),
    );
  }
}