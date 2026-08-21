import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// 錬成会・勝ち抜き戦設定セクション
class CategoryRuleRenseikaiSection extends StatelessWidget {
  final bool isRenseikai;
  final bool isKachinuki;
  final bool isNormal;
  final String categoryKey;

  final bool isRunningTime;
  final String renseikaiType;
  final int overallTime;
  final String kachinukiUnlimitedType;

  final ValueChanged<bool> onIsRunningTimeChanged;
  final ValueChanged<String> onRenseikaiTypeChanged;
  final ValueChanged<int> onOverallTimeChanged;
  final ValueChanged<String> onKachinukiUnlimitedTypeChanged;

  const CategoryRuleRenseikaiSection({
    super.key,
    required this.isRenseikai,
    required this.isKachinuki,
    required this.isNormal,
    required this.categoryKey,
    required this.isRunningTime,
    required this.renseikaiType,
    required this.overallTime,
    required this.kachinukiUnlimitedType,
    required this.onIsRunningTimeChanged,
    required this.onRenseikaiTypeChanged,
    required this.onOverallTimeChanged,
    required this.onKachinukiUnlimitedTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isRenseikai) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('ランニングタイム計測'),
            subtitle: const Text('ON: 試合中断時も時計を止めない / OFF: 都度停止'),
            value: isRunningTime,
            activeThumbColor: AppKendoColors.indigo,
            onChanged: onIsRunningTimeChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            '進行形式',
            style: TextStyle(
              fontWeight: AppFontWeight.semiBold,
              fontSize: AppFontSize.body,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['一試合制', '時間制'].map((type) {
              final isSelected = renseikaiType == type;
              return AppChoiceChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) onRenseikaiTypeChanged(type);
                },
              );
            }).toList(),
          ),
          if (renseikaiType == '時間制') ...[
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: ValueKey('renseikai_time_${isNormal}_$categoryKey'),
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
          const Divider(height: 32),
        ],
      );
    } else if (isKachinuki) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          const Text(
            '大将 VS 大将 のときの挙動',
            style: TextStyle(
              fontWeight: AppFontWeight.semiBold,
              fontSize: AppFontSize.body,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppChoiceChip(
                label: const Text('延長戦を行う (デフォルト)'),
                selected:
                    kachinukiUnlimitedType == '大将対大将' ||
                    kachinukiUnlimitedType == '無制限' ||
                    kachinukiUnlimitedType == '大将のみ',
                onSelected: (selected) {
                  if (selected) onKachinukiUnlimitedTypeChanged('大将対大将');
                },
              ),
              AppChoiceChip(
                label: const Text('引き分けとする'),
                selected:
                    kachinukiUnlimitedType == 'なし' ||
                    kachinukiUnlimitedType.isEmpty,
                onSelected: (selected) {
                  if (selected) onKachinukiUnlimitedTypeChanged('なし');
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            '大将対他のポジション（大将以外）の挙動',
            style: TextStyle(
              fontWeight: AppFontWeight.semiBold,
              fontSize: AppFontSize.body,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppChoiceChip(
                label: const Text('引き分けとする (デフォルト)'),
                selected:
                    kachinukiUnlimitedType == '大将対大将' ||
                    kachinukiUnlimitedType == 'なし' ||
                    kachinukiUnlimitedType.isEmpty ||
                    kachinukiUnlimitedType == '大将のみ',
                onSelected: (selected) {
                  if (selected) {
                    if (kachinukiUnlimitedType == 'なし' ||
                        kachinukiUnlimitedType.isEmpty) {
                      onKachinukiUnlimitedTypeChanged('なし');
                    } else {
                      onKachinukiUnlimitedTypeChanged('大将対大将');
                    }
                  }
                },
              ),
              AppChoiceChip(
                label: const Text('延長戦を行う'),
                selected: kachinukiUnlimitedType == '無制限',
                onSelected: (selected) {
                  if (selected) onKachinukiUnlimitedTypeChanged('無制限');
                },
              ),
            ],
          ),
          const Divider(height: 32),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
