import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/match_model.dart';
import '../../../../providers/match_rule_provider.dart';
import '../../../../providers/match_timer_provider.dart';
import '../../../../models/score_event.dart'; // ★ 追加: Side 型の定義用

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
  Size get preferredSize => const Size.fromHeight(160); // AppBar + Status + MasterTimerの高さ

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rule = ref.watch(matchRuleProvider);
    final isApproved = match.status == 'approved';
    
    final isDark = Theme.of(context).brightness == Brightness.dark; // ★ 追加: isDark の定義
    final headerColor = Colors.indigo.shade900;

    // ★ Phase 8-1: iPadなどの大画面でヘッダーがオーバーフロー(Infinity)しないよう保護
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: kToolbarHeight, // ★ AppBarに明確な高さを与えて崩壊を防ぐ
            child: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : headerColor,
                ),
              ),
              title: Text(
                // ★ 修正: match.category が null の場合を考慮
                (match.category ?? '').isNotEmpty ? '${match.category} - ${match.matchType}' : match.matchType,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () => context.go('/home/${match.tournamentId}'),
              ),
              actions: [
                if (isApproved)
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Center(child: Text('確定済', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                  ),
              ],
            ),
          ),
          if (match.groupName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(match.groupName!, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPlayerName(context, Side.red, isDark),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('vs', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 16)),
                ),
                _buildPlayerName(context, Side.white, isDark),
              ],
            ),
          ),
          // ★ 修正: 未定義だった変数を削除し、既存の専用メソッド呼び出しに戻す
          if (rule.isRenseikai && rule.renseikaiType == '時間制' && match.groupName != null)
            _buildMasterTimerDisplay(context, ref, match.groupName!),
        ],
      ),
    );
  }

  Widget _buildPlayerName(BuildContext context, Side side, bool isDark) {
    final bool isActive = !isInputLocked && (side == Side.red ? match.timerIsRunning : match.timerIsRunning); 
    final String name = side == Side.red ? match.redName : match.whiteName;
    final bool isMissing = name.contains('欠員');

    final Color activeColor = side == Side.red ? Colors.red.shade600 : (isDark ? Colors.grey.shade100 : Colors.white);
    final Color inactiveColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade300;

    return Flexible(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        padding: EdgeInsets.symmetric(horizontal: isActive ? 24 : 16, vertical: isActive ? 8 : 6),
        decoration: BoxDecoration(
          color: isDark 
              ? (isActive ? activeColor.withValues(alpha: 0.2) : const Color(0xFF1C1C1E))
              : (isActive ? activeColor : inactiveColor),
          border: Border.all(
            color: isActive ? (isDark ? activeColor : Colors.white) : (isDark ? const Color(0xFF38383A) : Colors.indigo.shade400),
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(24),
          // ★ Phase 8-1: アニメーション時の「マイナスの影」計算エラーを防ぐため、空ではなく透明な影を指定
          boxShadow: isActive && !isDark
              ? [BoxShadow(color: activeColor.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2)]
              : const [BoxShadow(color: Colors.transparent, blurRadius: 0, spreadRadius: 0)],
        ),
        child: Text(
          isMissing ? '欠員' : name.split(' ').last,
          style: TextStyle(
            fontSize: isActive ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isMissing 
                ? Colors.grey 
                : (isActive ? (side == Side.red || isDark ? Colors.white : Colors.indigo.shade900) : (isDark ? Colors.grey.shade500 : Colors.indigo.shade300)),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
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