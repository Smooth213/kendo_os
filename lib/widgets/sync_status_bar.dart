import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/role_provider.dart';
import '../providers/sync_provider.dart';

class SyncStatusBar extends ConsumerWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(operationModeProvider);
    final activeRole = ref.watch(activeRoleProvider);
    final isOnline = ref.watch(isOnlineProvider);

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
        // ★ 修正：SafeAreaの上の隙間（時計など）に被らないよう、最小限の高さを確保
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
              
              // 2. 右側：同期の状態
              Row(
                children: [
                  Icon(
                    isOnline ? Icons.cloud_done : Icons.cloud_off,
                    color: Colors.white70,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOnline ? 'リアルタイム同期中' : 'オフライン動作中',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}