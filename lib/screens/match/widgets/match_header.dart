import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/match_model.dart';
import '../../../presentation/provider/match_rule_provider.dart';
import '../../../presentation/provider/match_timer_provider.dart';

class MatchHeader extends ConsumerWidget implements PreferredSizeWidget {
  final MatchModel match;
  final bool isInputLocked;
  final bool isAllDone;
  final bool isTie;

  const MatchHeader({
    super.key,
    required this.match,
    required this.isInputLocked,
    required this.isAllDone,
    required this.isTie,
  });

  @override
  Size get preferredSize => const Size.fromHeight(150); // AppBar + Status + MasterTimerの高さ

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rule = ref.watch(matchRuleProvider);
    final isApproved = match.status == 'approved';
    final headerColor = Colors.indigo.shade900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ★ ステータスバーへのめり込みを防ぐため、AppBarを自前のセーフエリア付きContainerに置き換え
        Container(
          color: isDark ? const Color(0xFF1C1C1E) : headerColor,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top, // ここで時計やバッテリーのスペースを確実に確保
            bottom: 4,
            left: 8,
            right: 16,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () => context.go('/home/${match.tournamentId}'),
              ),
              Expanded(
                child: Text(
                  (match.category ?? '').isNotEmpty ? '${match.category} - ${match.matchType}' : match.matchType,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              if (isApproved)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Text('確定済', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                )
              else
                const SizedBox(width: 48), // ★ Phase 4: Undoボタンを下部に移したため削除。タイトルを中央に保つための見えない余白。
              // ★ Phase 7: 大会ホームに集約したため、個別試合のQRボタンは削除
            ],
          ),
        ),
        // 大会サブタイトル（団体戦名など）が必要な場合のみ表示
        if (match.groupName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(match.groupName!, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        
        if (rule.isRenseikai && rule.renseikaiType == '時間制' && match.groupName != null)
          _buildMasterTimerDisplay(context, ref, match.groupName!),
      ],
    );
  }

  Widget _buildMasterTimerDisplay(BuildContext context, WidgetRef ref, String groupName) {
    final masterTime = ref.watch(renseikaiMasterTimerProvider(groupName));
    final isRunning = ref.watch(isMasterTimerRunningProvider(groupName));
    final isTimeUp = masterTime == 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isRunning && !isTimeUp) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: ElevatedButton.icon(
          onPressed: () => ref.read(isMasterTimerRunningProvider(groupName).notifier).state = true,
          icon: const Icon(Icons.play_arrow),
          label: const Text('錬成会（全体時間）を開始'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      );
    }

    final bgColor = isTimeUp 
        ? (isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50)
        : (isDark ? Colors.indigo.shade900.withValues(alpha: 0.3) : Colors.indigo.shade50);
    final borderColor = isTimeUp 
        ? (isDark ? Colors.red.shade400 : Colors.red.shade300)
        : (isDark ? Colors.indigo.shade400 : Colors.indigo.shade200);
    final textColor = isTimeUp
        ? (isDark ? Colors.red.shade100 : Colors.red.shade800)
        : (isDark ? Colors.indigo.shade100 : Colors.indigo.shade800);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isTimeUp ? Icons.timer_off : Icons.timer, color: isTimeUp ? Colors.red : (isDark ? Colors.indigo.shade200 : Colors.indigo), size: 16),
          const SizedBox(width: 8),
          Text(
            isTimeUp ? '錬成会 終了時間！' : '全体の残り時間: ${_formatTime(masterTime > 0 ? masterTime : 0)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}