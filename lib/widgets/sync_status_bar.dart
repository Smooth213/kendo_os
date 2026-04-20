import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';

class SyncStatusBar extends ConsumerStatefulWidget {
  const SyncStatusBar({super.key});

  @override
  ConsumerState<SyncStatusBar> createState() => _SyncStatusBarState();
}

class _SyncStatusBarState extends ConsumerState<SyncStatusBar> {
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final isSyncing = ref.watch(isSyncingStateProvider); // ★ 追加：真の同期状態を監視
    final pendingCountAsync = ref.watch(pendingMatchesCountProvider);
    final pendingCount = pendingCountAsync.value ?? 0;

    // 完全に同期されていてオンラインの時は、画面の邪魔にならないよう非表示にする
    if (isOnline && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    // ★ Phase 8-1: 同期中ではないが、未送信データが残っている＝「競合」でスキップされた状態
    final isConflict = isOnline && !isSyncing && pendingCount > 0;

    Color bgColor;
    IconData icon;
    String text;

    if (!isOnline) {
      bgColor = Colors.red.shade700;
      icon = Icons.cloud_off;
      text = 'オフライン動作中 (未送信: $pendingCount件)';
      _isConfirming = false;
    } else if (isSyncing) {
      bgColor = Colors.orange.shade700;
      icon = Icons.cloud_sync;
      text = 'クラウドへ同期中... (残り$pendingCount件)';
      _isConfirming = false;
    } else if (isConflict) {
      if (_isConfirming) {
        bgColor = Colors.red.shade900;
        icon = Icons.delete_forever;
        text = 'タップして上書き実行 (手元の未送信を破棄)';
      } else {
        bgColor = Colors.amber.shade900;
        icon = Icons.warning_amber_rounded;
        text = '⚠️ 競合データあり: $pendingCount件 (タップで解決)';
      }
    } else {
      return const SizedBox.shrink();
    }

    return Material(
      color: bgColor,
      elevation: 2,
      // ★ Phase 8-1.5: 競合時はタップして解決できるようにする
      child: InkWell(
        onTap: isConflict ? () async {
          // Navigator が使えない階層のため、ダイアログを廃止し「ダブルタップ確認」を採用
          if (_isConfirming) {
            await ref.read(syncEngineProvider).resolveConflictByKeepingServer();
            if (mounted) setState(() => _isConfirming = false);
          } else {
            setState(() => _isConfirming = true);
            // 4秒間何もしなければ元の警告表示に戻る
            Future.delayed(const Duration(seconds: 4), () {
              if (mounted && _isConfirming) setState(() => _isConfirming = false);
            });
          }
        } : null,
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
      ),
    );
  }
}