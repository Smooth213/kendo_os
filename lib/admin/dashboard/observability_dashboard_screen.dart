import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/admin/providers/metrics_provider.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';

class ObservabilityDashboardScreen extends ConsumerWidget {
  const ObservabilityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppHeader(
          title: '運用ダッシュボード (Observability)',
          actions: const [
            // ★ 異常時なので「復旧ガイド（トラブルシューティング）」へ直行
            ManualHelpButton(
              manualPath: 'docs/manuals/recovery/failure_catalog.md',
            ),
            SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xl),
                child: Text(
                  'リアルタイムのシステム健康状態（メトリクス）を表示しています。異常値が検出された場合、自動でCRITICALアラートが発行されます。',
                  style: TextStyle(
                    fontSize: AppFontSize.bodySmall,
                    color: Colors.grey,
                  ),
                ),
              ),
              _buildMetricCard(
                '総イベント処理数',
                '${metrics['totalEvents']} 回',
                Icons.data_usage,
                Colors.blue,
                isDark,
              ),
              _buildMetricCard(
                'システムエラー率 (直近)',
                '${(metrics['errorRate'] * 100).toStringAsFixed(2)} %',
                Icons.error_outline,
                (metrics['errorRate'] > 0.01) ? Colors.red : Colors.green,
                isDark,
              ),
              _buildMetricCard(
                '同時書き込み競合率 (直近)',
                '${(metrics['conflictRate'] * 100).toStringAsFixed(2)} %',
                Icons.sync_problem,
                (metrics['conflictRate'] > 0.05) ? Colors.orange : Colors.green,
                isDark,
              ),
              _buildMetricCard(
                'Projection遅延 (直近)',
                '${metrics['lastLagMs']} ms',
                Icons.timer,
                (metrics['lastLagMs'] > 2000) ? Colors.red : Colors.green,
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Card(
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.roundValue),
        child: Row(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(width: AppSpacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSize.small,
                    color: Colors.grey,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppFontSize.display,
                    fontWeight: AppFontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
