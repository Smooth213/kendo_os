import 'package:flutter/material.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/admin/providers/audit_provider.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';

// ★ Phase 5: Firestoreから監査ログをリアルタイム取得するProvider
final auditLogsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
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

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const AppHeader(
          title: 'システム監査ログ',
          actions: [
            // ★ ログを見ている＝異常を疑っているため「緊急復旧ガイド」へ
            ManualHelpButton(
              manualPath: 'docs/manuals/recovery/failure_catalog.md',
            ),
            SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppTextField(
                decoration: InputDecoration(
                  labelText: '試合IDで絞り込み (フィルタ)',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFFFFFFF),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.medium,
                    borderSide: BorderSide.none,
                  ),
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
                      : logs
                            .where(
                              (l) => (l['matchId'] as String? ?? '').contains(
                                _filterMatchId,
                              ),
                            )
                            .toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'ログが見つかりません',
                        style: TextStyle(color: AppKendoColors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemExtent: 76.0,
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
                      Color actionColor = AppKendoColors.blue;
                      if (action == 'undo' || action == 'rebuild') {
                        actionColor = AppKendoColors.orange;
                      }
                      if (action == 'manual_update' ||
                          action == 'force_claim') {
                        actionColor = AppKendoColors.red;
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs,
                        ),
                        color: context.appColors.cardBackground,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: actionColor.withValues(alpha: 0.2),
                            child: Icon(
                              Icons.memory,
                              color: actionColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            '$action',
                            style: TextStyle(
                              fontWeight: AppFontWeight.bold,
                              color: context.appColors.textColor,
                              fontSize: AppFontSize.body,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '詳細: $details',
                                style: TextStyle(
                                  color: context.appColors.subTextColor,
                                  fontSize: AppFontSize.bodySmall,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '試合ID: $matchId\n操作者: $userId',
                                style: const TextStyle(
                                  color: AppKendoColors.grey,
                                  fontSize: AppFontSize.caption,
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            timeStr,
                            style: const TextStyle(
                              color: AppKendoColors.grey,
                              fontSize: AppFontSize.caption,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: Text(
                    'エラー: $e',
                    style: const TextStyle(color: AppKendoColors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
