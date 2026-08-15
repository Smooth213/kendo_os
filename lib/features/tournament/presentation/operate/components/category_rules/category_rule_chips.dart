import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 大会ルール一覧におけるルール概要チップ表示コンポーネント（純粋UIパーツ）
class CategoryRuleChips extends StatelessWidget {
  final CategoryRuleSet ruleSet;
  final bool isDark;

  const CategoryRuleChips({
    super.key,
    required this.ruleSet,
    required this.isDark,
  });

  static String formatMinutes(double minutes) {
    if (minutes <= 0) return '0分';
    final mins = minutes.floor();
    final secs = ((minutes - mins) * 60).round();
    if (mins == 0) {
      return '$secs秒';
    }
    if (secs == 0) {
      return '$mins分';
    }
    return '$mins分$secs秒';
  }

  Widget _buildChip(String label, Color bg, Color text) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.small),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: AppFontSize.caption,
          fontWeight: AppFontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeChipBg = isDark
        ? const Color(0x33FFFFFF)
        : const Color(0x1F000000);
    final timeChipText = isDark
        ? AppKendoColors.pureWhite
        : AppKendoColors.pureBlack;

    if (ruleSet.isMultiScene) {
      final List<Widget> sceneChips = [];

      if (ruleSet.useRenseikaiRule) {
        sceneChips.add(
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildChip(
                '⚔️ 錬成会',
                AppKendoColors.ipponGold,
                AppKendoColors.pureBlack,
              ),
              _buildChip(
                formatMinutes(ruleSet.renseikaiRule.matchTimeMinutes),
                timeChipBg,
                timeChipText,
              ),
              if (ruleSet.renseikaiRule.isRunningTime)
                _buildChip(
                  '流し',
                  const Color(0xFF2196F3),
                  AppKendoColors.pureWhite,
                ),
              if (ruleSet.renseikaiRule.hasHantei)
                _buildChip(
                  '引分有',
                  AppKendoColors.successGreen,
                  AppKendoColors.pureWhite,
                ),
            ],
          ),
        );
      }

      if (ruleSet.useHonsenRule) {
        if (sceneChips.isNotEmpty) {
          sceneChips.add(const SizedBox(height: 2));
        }
        sceneChips.add(
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildChip(
                '🏆 本戦',
                const Color(0xFF3F51B5),
                AppKendoColors.pureWhite,
              ),
              _buildChip(
                formatMinutes(ruleSet.normalRule.matchTimeMinutes),
                timeChipBg,
                timeChipText,
              ),
              if (ruleSet.normalRule.isEnchoUnlimited ||
                  ruleSet.normalRule.enchoCount > 0)
                _buildChip(
                  '代表戦/延長有',
                  const Color(0xFF9C27B0),
                  AppKendoColors.pureWhite,
                ),
            ],
          ),
        );
      }

      if (ruleSet.useMoushiawaseRule) {
        if (sceneChips.isNotEmpty) {
          sceneChips.add(const SizedBox(height: 2));
        }
        sceneChips.add(
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildChip(
                '🤝 申し合わせ',
                const Color(0xFF009688),
                AppKendoColors.pureWhite,
              ),
              _buildChip(
                formatMinutes(ruleSet.moushiawaseRule.matchTimeMinutes),
                timeChipBg,
                timeChipText,
              ),
              if (ruleSet.moushiawaseRule.hasHantei)
                _buildChip(
                  '引分有',
                  AppKendoColors.successGreen,
                  AppKendoColors.pureWhite,
                ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xs),
          ...sceneChips,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildChip(
              '標準ルール',
              const Color(0xFF2196F3),
              AppKendoColors.pureWhite,
            ),
            _buildChip(
              formatMinutes(ruleSet.normalRule.matchTimeMinutes),
              timeChipBg,
              timeChipText,
            ),
            _buildChip(
              ruleSet.normalRule.enchoCount > 0
                  ? "延長${ruleSet.normalRule.enchoCount}回"
                  : (ruleSet.normalRule.isEnchoUnlimited ? "延長無制限" : "延長なし"),
              const Color(0xFF9C27B0),
              AppKendoColors.pureWhite,
            ),
            if (ruleSet.normalRule.hasHantei)
              _buildChip(
                '判定あり',
                AppKendoColors.successGreen,
                AppKendoColors.pureWhite,
              ),
          ],
        ),
        if (ruleSet.useAdvancedRule)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildChip(
                  '上位戦',
                  const Color(0xFFFF5722),
                  AppKendoColors.pureWhite,
                ),
                _buildChip(
                  formatMinutes(ruleSet.advancedRule.matchTimeMinutes),
                  timeChipBg,
                  timeChipText,
                ),
                _buildChip(
                  ruleSet.advancedRule.enchoCount > 0
                      ? "延長${ruleSet.advancedRule.enchoCount}回"
                      : (ruleSet.advancedRule.isEnchoUnlimited
                            ? "延長無制限"
                            : "延長なし"),
                  const Color(0xFF9C27B0),
                  AppKendoColors.pureWhite,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
