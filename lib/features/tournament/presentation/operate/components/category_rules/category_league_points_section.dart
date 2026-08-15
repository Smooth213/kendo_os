import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// ルール設定画面におけるリーグ勝点配分設定セクション（純粋UIコンポーネント）
class CategoryLeaguePointsSection extends StatelessWidget {
  final String keyPrefix;
  final double winPoint;
  final double lossPoint;
  final double drawPoint;
  final ValueChanged<double> onWinChanged;
  final ValueChanged<double> onLossChanged;
  final ValueChanged<double> onDrawChanged;

  const CategoryLeaguePointsSection({
    super.key,
    required this.keyPrefix,
    required this.winPoint,
    required this.lossPoint,
    required this.drawPoint,
    required this.onWinChanged,
    required this.onLossChanged,
    required this.onDrawChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '勝ち点（リーグ戦の順位決定用）',
          style: TextStyle(
            fontWeight: AppFontWeight.bold,
            fontSize: AppFontSize.body,
            color: AppKendoColors.indigo,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('win_pt_$keyPrefix'),
                initialValue: winPoint.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '勝ち（点）',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(AppSpacing.md),
                ),
                onChanged: (val) {
                  final d = double.tryParse(val) ?? 0.0;
                  onWinChanged(d);
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                key: ValueKey('loss_pt_$keyPrefix'),
                initialValue: lossPoint.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '負け（点）',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(AppSpacing.md),
                ),
                onChanged: (val) {
                  final d = double.tryParse(val) ?? 0.0;
                  onLossChanged(d);
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                key: ValueKey('draw_pt_$keyPrefix'),
                initialValue: drawPoint.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '引き分け（点）',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(AppSpacing.md),
                ),
                onChanged: (val) {
                  final d = double.tryParse(val) ?? 0.0;
                  onDrawChanged(d);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
