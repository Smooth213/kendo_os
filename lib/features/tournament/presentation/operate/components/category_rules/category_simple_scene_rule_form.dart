import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_time_stepper_tile.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// マルチシーン（錬成・申合せ）における簡易ルール設定フォーム（純粋UIコンポーネント）
class CategorySimpleSceneRuleForm extends StatelessWidget {
  final String title;
  final double time;
  final bool isRunning;
  final bool hasHantei;
  final String renseikaiType;
  final int overallTime;
  final ValueChanged<double> onTimeChanged;
  final ValueChanged<bool> onRunningChanged;
  final ValueChanged<bool> onHanteiChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int> onOverallTimeChanged;

  const CategorySimpleSceneRuleForm({
    super.key,
    required this.title,
    required this.time,
    required this.isRunning,
    required this.hasHantei,
    required this.renseikaiType,
    required this.overallTime,
    required this.onTimeChanged,
    required this.onRunningChanged,
    required this.onHanteiChanged,
    required this.onTypeChanged,
    required this.onOverallTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.subhead,
              color: AppKendoColors.indigo,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          '錬成形式（試合方式）',
          style: TextStyle(
            fontWeight: AppFontWeight.semiBold,
            fontSize: AppFontSize.bodySmall,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: ['一試合制', '時間制'].map((type) {
            final isSelected = renseikaiType == type;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AppChoiceChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) onTypeChanged(type);
                },
              ),
            );
          }).toList(),
        ),
        if (renseikaiType == '時間制') ...[
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            initialValue: overallTime.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '全体の制限時間（分）',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(AppSpacing.md),
            ),
            onChanged: (val) {
              final i = int.tryParse(val) ?? 30;
              onOverallTimeChanged(i);
            },
          ),
        ],
        CategoryTimeStepperTile(
          title: '1試合の時間',
          value: time,
          minValue: 0.5,
          maxValue: 10.0,
          step: 0.5,
          onChanged: onTimeChanged,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('流し（タイマーを止めない）'),
          value: isRunning,
          onChanged: onRunningChanged,
        ),
      ],
    );
  }
}
