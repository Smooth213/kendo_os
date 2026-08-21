import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_league_points_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_time_stepper_tile.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 個人戦・リーグ個人戦（延長・時間・判定・勝敗点数）設定セクション
class CategoryRuleIndividualSection extends StatelessWidget {
  final bool isLeague;
  final bool isNormal;
  final String categoryKey;
  final AppThemeColors themeColors;

  final bool hasExtension;
  final bool isEnchoUnlimited;
  final int enchoCount;
  final double enchoTime;
  final bool hasHantei;

  final double winPoint;
  final double lossPoint;
  final double drawPoint;

  final ValueChanged<bool> onHasExtensionChanged;
  final ValueChanged<bool> onIsEnchoUnlimitedChanged;
  final ValueChanged<int> onEnchoCountChanged;
  final ValueChanged<double> onEnchoTimeChanged;
  final ValueChanged<bool> onHasHanteiChanged;

  final ValueChanged<double> onWinPointChanged;
  final ValueChanged<double> onLossPointChanged;
  final ValueChanged<double> onDrawPointChanged;

  const CategoryRuleIndividualSection({
    super.key,
    required this.isLeague,
    required this.isNormal,
    required this.categoryKey,
    required this.themeColors,
    required this.hasExtension,
    required this.isEnchoUnlimited,
    required this.enchoCount,
    required this.enchoTime,
    required this.hasHantei,
    required this.winPoint,
    required this.lossPoint,
    required this.drawPoint,
    required this.onHasExtensionChanged,
    required this.onIsEnchoUnlimitedChanged,
    required this.onEnchoCountChanged,
    required this.onEnchoTimeChanged,
    required this.onHasHanteiChanged,
    required this.onWinPointChanged,
    required this.onLossPointChanged,
    required this.onDrawPointChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('延長戦を有効にする'),
          value: hasExtension,
          activeThumbColor: AppKendoColors.indigo,
          onChanged: onHasExtensionChanged,
        ),
        if (hasExtension) ...[
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.only(left: AppSpacing.lg),
            title: const Text('時間・回数無制限'),
            value: isEnchoUnlimited,
            activeThumbColor: AppKendoColors.indigo,
            onChanged: onIsEnchoUnlimitedChanged,
          ),
          if (!isEnchoUnlimited) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.sm,
                top: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('最大延長回数'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: enchoCount > 1
                            ? () => onEnchoCountChanged(enchoCount - 1)
                            : null,
                      ),
                      Text(
                        '$enchoCount回',
                        style: const TextStyle(fontWeight: AppFontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: enchoCount < 10
                            ? () => onEnchoCountChanged(enchoCount + 1)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          CategoryTimeStepperTile(
            title: '延長戦の時間',
            value: enchoTime,
            minValue: 0.5,
            maxValue: 10.0,
            step: 0.5,
            primaryColor: themeColors.primaryAccent,
            onChanged: onEnchoTimeChanged,
          ),
        ],
        if (!hasExtension || !isEnchoUnlimited) ...[
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('引き分け時の判定を有効にする'),
            value: hasHantei,
            activeThumbColor: AppKendoColors.indigo,
            onChanged: onHasHanteiChanged,
          ),
        ],
        if (isLeague) ...[
          const Divider(height: 32),
          CategoryLeaguePointsSection(
            keyPrefix: '${isNormal}_$categoryKey',
            winPoint: winPoint,
            lossPoint: lossPoint,
            drawPoint: drawPoint,
            onWinChanged: onWinPointChanged,
            onLossChanged: onLossPointChanged,
            onDrawChanged: onDrawPointChanged,
          ),
        ],
        const Divider(height: 32),
      ],
    );
  }
}
