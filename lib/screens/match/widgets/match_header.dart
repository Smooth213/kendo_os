import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/provider/match_timer_provider.dart';
import '../../../presentation/provider/match_list_provider.dart'; 

class MatchHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String matchId; // ★ IDのみに変更
  final bool isInputLocked;

  const MatchHeader({
    super.key,
    required this.matchId,
    required this.isInputLocked,
  });

  @override
  Size get preferredSize => const Size.fromHeight(150);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ 試合の特定ステータスだけをピンポイント監視
    final matchStatus = ref.watch(matchListProvider.select((list) => 
      list.where((m) => m.id == matchId).firstOrNull?.status ?? 'waiting'
    ));
    final isApproved = matchStatus == 'approved';
    
    // 大会全体の状況判断も、ヘッダー自身が行う
    final isAllDone = ref.watch(matchListProvider.select((list) {
      final match = list.where((m) => m.id == matchId).firstOrNull;
      if (match == null || match.groupName == null) return false;
      return list.where((m) => m.groupName == match.groupName).every((m) => m.status == 'finished' || m.status == 'approved');
    }));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = Colors.indigo.shade900;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: isDark ? const Color(0xFF1C1C1E) : headerColor,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 8),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Consumer(builder: (context, ref, _) {
                      // 名前だけを監視
                      final names = ref.watch(matchListProvider.select((list) {
                        final m = list.where((m) => m.id == matchId).firstOrNull;
                        return '${m?.redName ?? ""} vs ${m?.whiteName ?? ""}';
                      }));
                      return Text(names, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16));
                    }),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              // ステータスバッジ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved ? Colors.green.shade700 : (isAllDone ? Colors.orange.shade700 : Colors.white24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isApproved ? '記録確定済み' : (isAllDone ? '全試合終了' : '試合進行中'),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        // マスタータイマー表示
        _MasterTimerBanner(matchId: matchId),
      ],
    );
  }
}

class _MasterTimerBanner extends ConsumerWidget {
  final String matchId;
  const _MasterTimerBanner({required this.matchId});

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 試合データから groupName を取得
    final groupName = ref.watch(matchListProvider.select((list) => 
      list.where((m) => m.id == matchId).firstOrNull?.groupName
    ));
    
    if (groupName == null || groupName.isEmpty) return const SizedBox.shrink();

    // ★ 修正: 正しいプロバイダから秒数を取得する
    final masterTime = ref.watch(renseikaiMasterTimerProvider(groupName));
    final isTimeUp = masterTime == 0;
    final displayTime = _formatTime(masterTime > 0 ? masterTime : 0);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isTimeUp 
        ? (isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50)
        : (isDark ? Colors.indigo.shade900.withValues(alpha: 0.3) : Colors.indigo.shade50);

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Text(
          isTimeUp ? '錬成会 終了時間！' : '全体の残り時間: $displayTime',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isTimeUp ? Colors.red : (isDark ? Colors.indigo.shade200 : Colors.indigo)),
        ),
      ),
    );
  }
}