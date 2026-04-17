import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart'; // ★ 追加: デバッグコマンド発動時の振動（HapticFeedback）用
import '../../../../models/match_model.dart';
import '../../../../providers/match_rule_provider.dart';
import '../../../../providers/match_command_provider.dart';
import '../../../../providers/match_provider.dart';
import '../../../../providers/match_timer_provider.dart';

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
    final rMiss = match.redName.contains('欠員');
    final wMiss = match.whiteName.contains('欠員');
    
    // ★ 修正: ダークモードでもライトモードと同じ引き締まったインディゴブルーに統一
    final headerColor = Colors.indigo.shade900;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. AppBar 部分
        AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () {
              if (isAllDone && !isTie) {
                context.push('/home/${match.tournamentId}');
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: GestureDetector( // ★ Phase 2: タイトル長押しでデータ完全修復コマンド発動
            onLongPress: isInputLocked ? null : () {
              HapticFeedback.heavyImpact(); // 強めの振動で裏コマンド発動を通知
              ref.read(matchActionProvider).rebuildMatch(match);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✨ データをイベント履歴から完全修復しました', style: TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.teal,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              '${match.matchType}：${match.redName} vs ${_reverseWhiteName(match.whiteName)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1),
            ),
          ),
          backgroundColor: headerColor,
          elevation: 0,
          actions: [
            // ★ 修正：透明度を最適化（0.25）し、極細ボーダーと組み合わせて最高の上品さを出す
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: TextButton.icon(
                onPressed: () => context.pushReplacement('/home/${match.tournamentId}'),
                icon: const Icon(Icons.format_list_bulleted, color: Colors.white, size: 16),
                label: const Text(
                  '大会ホーム', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.25), // ★ 0.2と0.35の間のベストな透け感
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 0.5), // 輪郭の線は少し残す
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.undo, size: 24, color: Colors.white70),
              tooltip: '1つ前の操作を取り消す',
              // ★ 修正: matchCommandProvider を使用
              onPressed: isInputLocked ? null : () => ref.read(matchCommandProvider).undoLastEvent(match.id),
            ),
            // ★ Step 4-4: データ修復（同期）ボタン
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) async {
                if (value == 'sync') {
                  await ref.read(matchCommandProvider).rebuildMatchSnapshot(match.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('スコアを歴史データと同期しました'))
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'sync',
                  child: Row(
                    children: [
                      Icon(Icons.sync, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('スコア強制同期'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),

        // 2. ★ Step 6-3: 進行ステータスバッジ（アニメーション＆フラッシュ演出）
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            padding: EdgeInsets.symmetric(
              horizontal: (match.status == 'finished' || isApproved) ? 24 : 16, 
              vertical: (match.status == 'finished' || isApproved) ? 8 : 6
            ),
            decoration: BoxDecoration(
              // 試合終了時は「発光」しているような鮮やかな色へ変化させる
              color: isApproved 
                  ? Colors.teal.shade700 
                  : (match.status == 'finished' || rMiss || wMiss 
                      ? Colors.orange.shade700 // 終了直後は注意を引くオレンジ
                      : Colors.indigo.shade50),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isApproved ? Colors.teal.shade200 : (match.status == 'finished' || rMiss || wMiss ? Colors.orange.shade200 : Colors.indigo.shade400),
                width: (match.status == 'finished' || isApproved) ? 2 : 1,
              ),
              // ★ 終了時に外側に光が漏れるシャドウエフェクト（フラッシュ）
              boxShadow: (match.status == 'finished' || isApproved) ? [
                BoxShadow(
                  color: (isApproved ? Colors.teal : Colors.orange).withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ] : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isApproved ? Icons.verified : (match.status == 'finished' || rMiss || wMiss ? Icons.stars : Icons.sports_martial_arts),
                  size: (match.status == 'finished' || isApproved) ? 18 : 16,
                  color: (match.status == 'finished' || isApproved) ? Colors.white : Colors.indigo.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  isApproved ? '公式記録(確定済み)' : ((rMiss && wMiss) ? '両者欠員（引き分け）' : (rMiss || wMiss ? '不戦勝（試合終了）' : (match.status == 'finished' ? '試合終了・未確定' : '試合進行中'))),
                  style: TextStyle(
                    fontWeight: FontWeight.w900, // より太く
                    color: (match.status == 'finished' || isApproved) ? Colors.white : Colors.indigo.shade800,
                    fontSize: (match.status == 'finished' || isApproved) ? 15 : 14,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. 錬成会マスタータイマー (必要な場合のみ)
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

  String _reverseWhiteName(String whiteName) {
    if (!whiteName.contains(':')) return whiteName;
    final parts = whiteName.split(':');
    if (parts.length != 2) return whiteName;
    return '${parts[1].trim()} : ${parts[0].trim()}';
  }
}