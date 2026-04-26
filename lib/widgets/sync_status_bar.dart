import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/role_provider.dart';
import '../providers/sync_provider.dart';

// ★ 追加: バーを「確認モード」に変形させるためのローカルスイッチ
final syncConfirmVisibleProvider = StateProvider<bool>((ref) => false);

class SyncStatusBar extends ConsumerWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ 修正: ここでwatchすることで、UI描画と同時にSyncEngineを強制的に起動・常駐させる
    // これによりエンジン内部の「ネットワーク監視機能」が即座に働き始めます
    ref.watch(syncEngineProvider);

    // ---------------------------------------------------------
    // ★ 修正: 確認モードの時の「優しい警告UI」とはみ出し防止
    // ---------------------------------------------------------
    final showConfirm = ref.watch(syncConfirmVisibleProvider);
    if (showConfirm) {
      return Material(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 4),
          // ★ 修正: 威圧感のない、少し落ち着いたオレンジ色に変更
          color: Colors.orange.shade700, 
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ★ 修正: はみ出しを防ぐために Expanded で囲み、テキストも少しスッキリさせる
                const Expanded(
                  child: Text(
                    '☁️ クラウドに合わせて未送信をリセットしますか？',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis, // 万が一はみ出しても「...」にしてエラーを防ぐ
                  ),
                ),
                const SizedBox(width: 8), // テキストとボタンの隙間
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // キャンセルボタン
                    GestureDetector(
                      onTap: () => ref.read(syncConfirmVisibleProvider.notifier).state = false,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        color: Colors.transparent,
                        child: const Text('キャンセル', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // リセット実行ボタン
                    GestureDetector(
                      onTap: () async {
                        await ref.read(syncEngineProvider).resolveConflictByKeepingServer();
                        ref.read(syncConfirmVisibleProvider.notifier).state = false;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        // ★ 修正: ボタンの文字色も背景のオレンジに合わせる
                        child: Text(
                          'リセット', 
                          style: TextStyle(color: Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ---------------------------------------------------------
    // 以下、通常のUI（青や紫の帯）
    // ---------------------------------------------------------
    final mode = ref.watch(operationModeProvider);
    final activeRole = ref.watch(activeRoleProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final matchStatus = ref.watch(syncStatusProvider);
    final isGlobalSyncing = ref.watch(isSyncingStateProvider);

    Color barColor;
    switch (activeRole) {
      case Role.admin: barColor = Colors.indigo.shade800; break;   // 大会・管理者（紺）
      case Role.scorer: barColor = Colors.teal.shade700; break;     // 大会・記録係（青緑）
      case Role.editor: barColor = Colors.purple.shade700; break;   // マスタ・編集者（紫）
      case Role.viewer: barColor = Colors.blueGrey.shade700; break; // 閲覧のみ（グレー）
    }

    return Material(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 4),
        color: barColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. 左側：現在の状態（現場の言葉）
              Text(
                '【${mode.label}：${activeRole.label}】',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              
              // 2. 右側：2つの同期ステータス
              Row(
                children: [
                  if (!isOnline) ...[
                    // オフライン時の表示
                    const Icon(Icons.cloud_off, color: Colors.white70, size: 12),
                    const SizedBox(width: 4),
                    const Text('オフライン動作中', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ] else ...[
                    // ① システム全体の同期状態（左側）
                    Icon(
                      Icons.sync, 
                      size: 12, 
                      color: isGlobalSyncing ? Colors.blue.shade200 : Colors.white54
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isGlobalSyncing ? 'システム同期中' : 'システム正常',
                      style: TextStyle(fontSize: 10, color: isGlobalSyncing ? Colors.blue.shade100 : Colors.white70),
                    ),
                    
                    const SizedBox(width: 12), // 2つのアイコンの隙間
                    
                    // ② 試合データの同期状態（右側）
                    // ★ 修正: タップすると「確認モード」のスイッチをONにする
                    GestureDetector(
                      onTap: matchStatus == SyncStatus.pending 
                          ? () => ref.read(syncConfirmVisibleProvider.notifier).state = true
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        color: Colors.transparent, // タップ領域を確保
                        child: Row(
                          children: [
                            _buildMatchSyncIcon(matchStatus),
                            const SizedBox(width: 4),
                            Text(
                              matchStatus == SyncStatus.pending ? '未送信あり' : '同期済み',
                              style: TextStyle(
                                fontSize: 10, 
                                fontWeight: FontWeight.bold,
                                color: matchStatus == SyncStatus.pending ? Colors.orange.shade300 : Colors.greenAccent
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 試合データの同期アイコン描画ヘルパー
  Widget _buildMatchSyncIcon(SyncStatus status) {
    if (status == SyncStatus.syncing) {
      return const SizedBox(
        width: 12, height: 12, 
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)
      );
    }
    return Icon(
      status == SyncStatus.pending ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
      color: status == SyncStatus.pending ? Colors.orange.shade300 : Colors.greenAccent,
      size: 14,
    );
  }
}