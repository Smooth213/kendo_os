import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../presentation/provider/audit_provider.dart';

// ★ Phase 5: Firestoreから監査ログをリアルタイム取得するProvider
final auditLogsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(auditFirestoreProvider);
  return firestore
      .collection('audit_logs')
      .orderBy('timestamp', descending: true)
      .limit(100) // 最新の100件を表示
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String _filterMatchId = '';

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(auditLogsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('システム監査ログ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: '試合IDで絞り込み (フィルタ)',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _filterMatchId = val.trim()),
            ),
          ),
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                // 試合IDでフィルタリング
                final filtered = _filterMatchId.isEmpty 
                    ? logs 
                    : logs.where((l) => (l['matchId'] as String? ?? '').contains(_filterMatchId)).toList();
                
                if (filtered.isEmpty) {
                  return const Center(child: Text('ログが見つかりません', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final log = filtered[index];
                    final action = log['action'] ?? 'Unknown';
                    final details = log['details'] ?? '';
                    final userId = log['userId'] ?? 'Unknown';
                    final matchId = log['matchId'] ?? 'Unknown';
                    
                    DateTime? date;
                    if (log['timestamp'] != null) {
                      if (log['timestamp'] is Timestamp) {
                        date = (log['timestamp'] as Timestamp).toDate();
                      } else if (log['timestamp'] is String) {
                        date = DateTime.tryParse(log['timestamp']);
                      }
                    }
                    
                    final timeStr = date != null 
                        ? '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}'
                        : '不明な日時';

                    // アクションの重要度によってアイコンの色を変える
                    Color actionColor = Colors.blue;
                    if (action == 'undo' || action == 'rebuild') actionColor = Colors.orange;
                    if (action == 'manual_update' || action == 'force_claim') actionColor = Colors.red;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: actionColor.withValues(alpha: 0.2),
                          child: Icon(Icons.memory, color: actionColor, size: 20),
                        ),
                        title: Text('$action', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('詳細: $details', style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black87, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('試合ID: $matchId\n操作者: $userId', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                        trailing: Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('エラー: $e', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }
}