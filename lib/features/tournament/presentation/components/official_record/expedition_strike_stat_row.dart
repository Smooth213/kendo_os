import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 遠征成績の打突技内訳（面・小手・胴・突き・反則）表示パーツ
class ExpeditionStrikeStatRow extends StatelessWidget {
  final int men;
  final int kote;
  final int dou;
  final int tsuki;
  final int hansoku;

  const ExpeditionStrikeStatRow({
    super.key,
    required this.men,
    required this.kote,
    required this.dou,
    required this.tsuki,
    required this.hansoku,
  });

  @override
  Widget build(BuildContext context) {
    final totalStrikes = men + kote + dou + tsuki + hansoku;

    return Row(
      children: [
        Expanded(
          child: _buildBadge('面 (メ)', men, totalStrikes, AppKendoColors.teal),
        ),
        Expanded(
          child: _buildBadge(
            '小手 (コ)',
            kote,
            totalStrikes,
            AppKendoColors.indigo,
          ),
        ),
        Expanded(
          child: _buildBadge(
            '胴 (ド)',
            dou,
            totalStrikes,
            const Color(0xFFD97706),
          ),
        ),
        Expanded(
          child: _buildBadge(
            '突き (ツ)',
            tsuki,
            totalStrikes,
            const Color(0xFF8B5CF6),
          ),
        ),
        Expanded(
          child: _buildBadge(
            '反則 (反)',
            hansoku,
            totalStrikes,
            AppKendoColors.hansokuRed,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, int count, int total, Color color) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.caption,
            fontWeight: AppFontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count本',
          style: const TextStyle(
            fontSize: AppFontSize.bodyMedium,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        Text(
          '$pct%',
          style: const TextStyle(
            fontSize: AppFontSize.caption,
            color: AppKendoColors.grey,
          ),
        ),
      ],
    );
  }
}
