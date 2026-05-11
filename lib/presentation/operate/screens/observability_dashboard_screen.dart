import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/metrics_provider.dart';
import '../../shared/widgets/manual_help_button.dart';

class ObservabilityDashboardScreen extends ConsumerWidget {
  const ObservabilityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('運用ダッシュボード (Observability)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: const [
          // ★ 異常時なので「復旧ガイド（トラブルシューティング）」へ直行
          ManualHelpButton(manualPath: 'docs/manuals/recovery/failure_catalog.md'),
          SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 24.0),
              child: Text(
                'リアルタイムのシステム健康状態（メトリクス）を表示しています。異常値が検出された場合、自動でCRITICALアラートが発行されます。',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            _buildMetricCard(
              '総イベント処理数', 
              '${metrics['totalEvents']} 回', 
              Icons.data_usage, 
              Colors.blue, 
              isDark
            ),
            _buildMetricCard(
              'システムエラー率 (直近)', 
              '${(metrics['errorRate'] * 100).toStringAsFixed(2)} %', 
              Icons.error_outline, 
              (metrics['errorRate'] > 0.01) ? Colors.red : Colors.green, 
              isDark
            ),
            _buildMetricCard(
              '同時書き込み競合率 (直近)', 
              '${(metrics['conflictRate'] * 100).toStringAsFixed(2)} %', 
              Icons.sync_problem, 
              (metrics['conflictRate'] > 0.05) ? Colors.orange : Colors.green, 
              isDark
            ),
            _buildMetricCard(
              'Projection遅延 (直近)', 
              '${metrics['lastLagMs']} ms', 
              Icons.timer, 
              (metrics['lastLagMs'] > 2000) ? Colors.red : Colors.green, 
              isDark
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Card(
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}