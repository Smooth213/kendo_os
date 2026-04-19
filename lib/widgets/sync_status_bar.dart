import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';

class SyncStatusBar extends ConsumerWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final pendingCountAsync = ref.watch(pendingMatchesCountProvider);
    final pendingCount = pendingCountAsync.value ?? 0;

    // 完全に同期されていてオンラインの時は、画面の邪魔にならないよう非表示にする
    if (isOnline && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    final isSyncing = isOnline && pendingCount > 0;
    
    // オフライン時は赤、オンライン復帰時の同期中はオレンジに変化
    final bgColor = isSyncing ? Colors.orange.shade700 : Colors.red.shade700;
    final icon = isSyncing ? Icons.cloud_sync : Icons.cloud_off;
    final text = isSyncing ? 'クラウドへ同期中... (残り$pendingCount件)' : 'オフライン動作中 (未送信: $pendingCount件)';

    return Material(
      color: bgColor,
      elevation: 2,
      child: SafeArea(
        bottom: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}