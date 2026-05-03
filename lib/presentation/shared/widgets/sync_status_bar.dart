import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../operate/providers/role_provider.dart';
import '../../operate/providers/sync_provider.dart';
import '../../operate/providers/match_command_provider.dart'; // ★ deadLetterQueueProvider を参照するために追加

class SyncStatusBar extends ConsumerWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // UI描画と同時にSyncEngineを強制的に起動・常駐させる
    ref.watch(syncEngineProvider);

    final mode = ref.watch(operationModeProvider);
    final activeRole = ref.watch(activeRoleProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final matchStatus = ref.watch(syncStatusProvider);
    final isGlobalSyncing = ref.watch(isSyncingStateProvider);
    // ★ 取得: デッドレターキュー（エラーデータ）の件数
    final deadLetterCount = ref.watch(deadLetterQueueProvider).length;

    Color barColor;
    switch (activeRole) {
      case Role.admin: barColor = Colors.indigo.shade800; break;
      case Role.scorer: barColor = Colors.teal.shade700; break;
      case Role.editor: barColor = Colors.purple.shade700; break;
      case Role.viewer: barColor = Colors.blueGrey.shade700; break;
    }

    // エラーがある場合はバー全体を赤みがかった警告色にする
    if (deadLetterCount > 0) {
      barColor = Colors.red.shade700;
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
              // 1. 左側：現在の状態
              Text(
                '【${mode.label}：${activeRole.label}】',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              
              // 2. 右側：同期ステータス
              Row(
                children: [
                  if (!isOnline) ...[
                    const Icon(Icons.cloud_off, color: Colors.white70, size: 12),
                    const SizedBox(width: 4),
                    const Text('オフライン動作中', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ] else ...[
                    // ① システム全体の同期状態
                    Icon(
                      Icons.sync, 
                      size: 12, 
                      color: isGlobalSyncing ? Colors.blue.shade200 : Colors.white54
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isGlobalSyncing ? '同期中' : '正常',
                      style: TextStyle(fontSize: 10, color: isGlobalSyncing ? Colors.blue.shade100 : Colors.white70),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // ② デッドレター（エラー）または通常の未送信状態
                    GestureDetector(
                      onTap: (deadLetterCount > 0 || matchStatus == SyncStatus.pending)
                          ? () => _showErrorQueueSheet(context, ref)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            if (deadLetterCount > 0) ...[
                              const Icon(Icons.warning_amber_rounded, color: Colors.yellowAccent, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '$deadLetterCount件の送信エラー',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.yellowAccent),
                              ),
                            ] else ...[
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

  Widget _buildMatchSyncIcon(SyncStatus status) {
    if (status == SyncStatus.syncing) {
      return const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue));
    }
    return Icon(
      status == SyncStatus.pending ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
      color: status == SyncStatus.pending ? Colors.orange.shade300 : Colors.greenAccent,
      size: 14,
    );
  }

  // ★ 追加: デッドレター（エラー）一覧を表示・操作するボトムシート
  void _showErrorQueueSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, sheetRef, _) {
            final deadLetters = sheetRef.watch(deadLetterQueueProvider);
            final pendingStatus = sheetRef.watch(syncStatusProvider);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('☁️ クラウド同期ステータス', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    if (deadLetters.isEmpty) ...[
                      // 通常の未送信データのみの場合（従来のリセット機能を提供）
                      const Text('現在、送信待ちのデータがキューに溜まっています。電波状況が回復すると自動的に送信されます。'),
                      const SizedBox(height: 16),
                      if (pendingStatus == SyncStatus.pending)
                        Center(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade100, foregroundColor: Colors.orange.shade900),
                            icon: const Icon(Icons.delete_sweep),
                            label: const Text('サーバーのデータを優先し、未送信を破棄する'),
                            onPressed: () async {
                              await sheetRef.read(syncEngineProvider).resolveConflictByKeepingServer();
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                        ),
                    ] else ...[
                      // デッドレター（送信エラー）がある場合
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('通信が3回失敗したため、以下の操作が退避されました。手動で再送か破棄を選んでください。', style: TextStyle(fontSize: 12))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // エラーデータのリスト表示
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: deadLetters.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final cmd = deadLetters[index];
                            final time = '${cmd.createdAt.hour.toString().padLeft(2, '0')}:${cmd.createdAt.minute.toString().padLeft(2, '0')}';
                            final typeStr = cmd.type == CommandType.addScore ? '得点追加' : (cmd.type == CommandType.undoLastEvent ? '取り消し' : 'その他操作');
                            
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('[$time] $typeStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('ID: ${cmd.payload['matchId'] ?? cmd.id}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => sheetRef.read(deadLetterQueueProvider.notifier).discardCommand(cmd),
                                    child: const Text('破棄', style: TextStyle(color: Colors.grey)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
                                    onPressed: () {
                                      sheetRef.read(deadLetterQueueProvider.notifier).retryCommand(cmd);
                                    },
                                    child: const Text('再送'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}