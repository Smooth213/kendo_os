import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/provider/match_list_provider.dart';
import 'match/widgets/scoreboard.dart';
import 'match/widgets/match_header.dart';
import 'match/widgets/timer_widget.dart';

class ViewerMatchScreen extends ConsumerWidget {
  final String matchId;
  const ViewerMatchScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchListProvider.select((list) => 
      list.where((m) => m.id == matchId).firstOrNull
    ));

    if (match == null) return const Scaffold(body: Center(child: Text('データなし')));
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white, 
      appBar: MatchHeader(
        match: match,
        isInputLocked: true, // 閲覧なので常にロック
        isAllDone: false,
        isTie: false,
      ),
      body: Column(
        children: [
          // 閲覧専用バナー
          Container(
            width: double.infinity,
            color: Colors.blueGrey.shade700,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('閲覧専用モード', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          TimerWidget(match: match, isInputLocked: true),
          Expanded(
            child: MatchScoreboard(
              match: match, 
              myUserId: 'viewer', // 閲覧用ダミー
              onNameTap: (side) {}, // タップしても何もしない（編集不可）
            ),
          ),
        ],
      ),
    );
  }
}