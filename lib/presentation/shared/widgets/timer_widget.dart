import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import '../../operate/providers/match_timer_provider.dart';
import '../../operate/providers/match_list_provider.dart'; // ★ 追加: matchListProvider

class TimerWidget extends ConsumerWidget {
  final String matchId;
  final bool isInputLocked;

  const TimerWidget({
    super.key,
    required this.matchId,
    required this.isInputLocked,
  });

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _showTimerEditDialog(BuildContext context, WidgetRef ref, MatchModel match) {
    int m = (match.remainingSeconds / 60).floor();
    int s = match.remainingSeconds % 60;
    
    // iOS Native カラー
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100;
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;

    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: bgColor,
      title: Text('時間修正', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Row(children: [
        Expanded(child: TextFormField(
          initialValue: '$m', 
          keyboardType: TextInputType.number, 
          textAlign: TextAlign.center, 
          style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true, fillColor: inputBgColor,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.indigo.shade400, width: 2)),
          ), 
          onChanged: (v) => m = int.tryParse(v) ?? 0
        )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
        ),
        Expanded(child: TextFormField(
          initialValue: '$s', 
          keyboardType: TextInputType.number, 
          textAlign: TextAlign.center, 
          style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true, fillColor: inputBgColor,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.indigo.shade400, width: 2)),
          ), 
          onChanged: (v) => s = int.tryParse(v) ?? 0
        )),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () {
            // ★ 修正: matchTimerProvider を使用
            ref.read(matchTimerProvider).updateRemainingSeconds(matchId, (m * 60) + s);
            Navigator.pop(ctx);
          },
          style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.indigo.shade600 : Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('更新', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFinished = ref.watch(matchListProvider.select((list) {
      final m = list.where((m) => m.id == matchId).firstOrNull;
      return m?.status == 'finished' || m?.status == 'approved';
    }));

    if (isFinished) return const SizedBox.shrink();
    
    // ★ 修正：SizedBoxでの固定高さ(140px)を完全に撤廃し、自然にピッタリ収まるようにします
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // 少しだけ外側に余白を持たせる
      child: _buildTimerContent(context, ref),
    );
  }

  // ★ タイマーの中身をヘルパー関数として分離
  Widget _buildTimerContent(BuildContext context, WidgetRef ref) {
    final isRunning = ref.watch(matchListProvider.select((list) => 
      list.where((m) => m.id == matchId).firstOrNull?.timerIsRunning ?? false
    ));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timerBgColor = isRunning 
        ? (isDark ? Colors.red.shade900.withValues(alpha: 0.4) : Colors.red.shade50)
        : (isDark ? const Color(0xFF1C1C1E) : Colors.white);
    final timerBorderColor = isRunning 
        ? (isDark ? Colors.red.shade400 : Colors.red.shade500)
        : (isDark ? const Color(0xFF38383A) : Colors.indigo.shade200);
    final timerTextColor = isRunning 
        ? (isDark ? Colors.red.shade300 : Colors.red.shade900) 
        : (isDark ? Colors.white : Colors.black87);

    return GestureDetector(
      behavior: HitTestBehavior.opaque, // ★ 修正：透明な余白部分のタップ漏れを完全に防ぐ魔法のコード
      // ★ 修正: matchTimerProvider を使用
      onTap: isInputLocked ? null : () => ref.read(matchTimerProvider).toggleTimer(matchId),
      onLongPress: isInputLocked ? null : () {
        final match = ref.read(matchListProvider).firstWhere((m) => m.id == matchId);
        _showTimerEditDialog(context, ref, match);
      },
      child: Container(
        // ★ 修正：内部の余白を適切に設定し、引き伸ばしを防止
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        decoration: BoxDecoration(
          color: timerBgColor,
          borderRadius: BorderRadius.circular(32), // ★ 縦幅がスリムになるため、角丸も美しく微調整
          border: Border.all(color: timerBorderColor, width: isRunning ? 4 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isRunning ? Icons.pause_circle : Icons.play_circle, color: isRunning ? (isDark ? Colors.red.shade400 : Colors.red.shade600) : (isDark ? Colors.indigo.shade300 : Colors.indigo.shade500), size: 32),
            const SizedBox(width: 12),
            // ★ Step 3-3: Firestoreの match.remainingSeconds ではなく、
            // 1秒ごとに更新される liveRemainingSecondsProvider を watch する。
            // これにより、この Text Widget だけが1秒ごとに更新されるようになる。
            Consumer(
              builder: (context, ref, child) {
                final seconds = ref.watch(liveRemainingSecondsProvider(matchId));
                return Text(
                  _formatTime(seconds), 
                  style: TextStyle(
                    fontSize: 52, 
                    fontWeight: FontWeight.w900, 
                    fontFamily: 'Courier',
                    height: 1.1, 
                    color: timerTextColor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}