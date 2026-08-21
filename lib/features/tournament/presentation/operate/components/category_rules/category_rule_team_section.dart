import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_league_points_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_time_stepper_tile.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// 団体戦・リーグ団体戦（代表戦・時間・延長・判定）設定セクション
class CategoryRuleTeamSection extends StatelessWidget {
  final bool isLeague;
  final bool isNormal;
  final String categoryKey;
  final AppThemeColors themeColors;

  final bool hasLeagueDaihyo;
  final bool isDaihyoIpponShobu;
  final double daihyoMatchTime;
  final bool daihyoHasExtension;
  final double daihyoEnchoTime;
  final int daihyoEnchoCount;
  final bool daihyoHasHantei;

  final double winPoint;
  final double lossPoint;
  final double drawPoint;

  final ValueChanged<bool> onHasLeagueDaihyoChanged;
  final ValueChanged<bool> onIsDaihyoIpponShobuChanged;
  final ValueChanged<double> onDaihyoMatchTimeChanged;
  final ValueChanged<bool> onDaihyoHasExtensionChanged;
  final ValueChanged<double> onDaihyoEnchoTimeChanged;
  final ValueChanged<int> onDaihyoEnchoCountChanged;
  final ValueChanged<bool> onDaihyoHasHanteiChanged;

  final ValueChanged<double> onWinPointChanged;
  final ValueChanged<double> onLossPointChanged;
  final ValueChanged<double> onDrawPointChanged;
  final String Function(double) formatMinutes;

  const CategoryRuleTeamSection({
    super.key,
    required this.isLeague,
    required this.isNormal,
    required this.categoryKey,
    required this.themeColors,
    required this.hasLeagueDaihyo,
    required this.isDaihyoIpponShobu,
    required this.daihyoMatchTime,
    required this.daihyoHasExtension,
    required this.daihyoEnchoTime,
    required this.daihyoEnchoCount,
    required this.daihyoHasHantei,
    required this.winPoint,
    required this.lossPoint,
    required this.drawPoint,
    required this.onHasLeagueDaihyoChanged,
    required this.onIsDaihyoIpponShobuChanged,
    required this.onDaihyoMatchTimeChanged,
    required this.onDaihyoHasExtensionChanged,
    required this.onDaihyoEnchoTimeChanged,
    required this.onDaihyoEnchoCountChanged,
    required this.onDaihyoHasHanteiChanged,
    required this.onWinPointChanged,
    required this.onLossPointChanged,
    required this.onDrawPointChanged,
    required this.formatMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('代表戦あり（団体戦用）'),
          subtitle: const Text('チーム合計が引き分けの時、代表者同士で決定戦を行います。'),
          value: hasLeagueDaihyo,
          activeThumbColor: AppKendoColors.indigo,
          onChanged: onHasLeagueDaihyoChanged,
        ),
        if (hasLeagueDaihyo) ...[
          const SizedBox(height: AppSpacing.md),
          const Text(
            '代表戦の本数',
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
                label: const Text('１本勝負 (デフォルト)'),
                selected: isDaihyoIpponShobu,
                onSelected: (selected) {
                  if (selected) onIsDaihyoIpponShobuChanged(true);
                },
              ),
              AppChoiceChip(
                label: const Text('３本勝負'),
                selected: !isDaihyoIpponShobu,
                onSelected: (selected) {
                  if (selected) onIsDaihyoIpponShobuChanged(false);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            '代表戦の試合時間',
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
                label: const Text('時間制限なし (デフォルト)'),
                selected: daihyoMatchTime == 0.0,
                onSelected: (selected) {
                  if (selected) onDaihyoMatchTimeChanged(0.0);
                },
              ),
              ...[1.5, 2.0, 2.5, 3.0, 4.0, 5.0].map((t) {
                final isSelected = daihyoMatchTime == t;
                return AppChoiceChip(
                  label: Text(formatMinutes(t)),
                  selected: isSelected,
                  onSelected: (s) {
                    if (s) onDaihyoMatchTimeChanged(t);
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('代表戦の延長を有効にする'),
            value: daihyoHasExtension,
            activeThumbColor: AppKendoColors.indigo,
            onChanged: onDaihyoHasExtensionChanged,
          ),
          if (daihyoHasExtension) ...[
            CategoryTimeStepperTile(
              title: '代表戦延長の時間',
              value: daihyoEnchoTime,
              minValue: 0.5,
              maxValue: 10.0,
              step: 0.5,
              primaryColor: themeColors.primaryAccent,
              onChanged: onDaihyoEnchoTimeChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Padding(
              padding: EdgeInsets.only(left: AppSpacing.lg),
              child: Text(
                '代表戦延長の回数',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.bodySmall,
                  color: AppKendoColors.grey,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                top: AppSpacing.xs,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppChoiceChip(
                    label: const Text('無制限 (デフォルト)'),
                    selected: daihyoEnchoCount == -2,
                    onSelected: (selected) {
                      if (selected) onDaihyoEnchoCountChanged(-2);
                    },
                  ),
                  ...[1, 2, 3, 5].map((c) {
                    final isSelected = daihyoEnchoCount == c;
                    return AppChoiceChip(
                      label: Text('$c回'),
                      selected: isSelected,
                      onSelected: (s) {
                        if (s) onDaihyoEnchoCountChanged(c);
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('代表戦の判定を有効にする'),
            subtitle: const Text('時間切れで決着がつかない場合に判定を行います。'),
            value: daihyoHasHantei,
            activeThumbColor: AppKendoColors.indigo,
            onChanged: onDaihyoHasHanteiChanged,
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
