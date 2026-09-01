import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_scene_badge.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

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

  /// 先頭のシーン・種別タグ用（淡いチント背景 ＋ 枠線 ＋ テーマ文字）
  Widget _buildSceneTag({required String label, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2.5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: AppRadius.sub,
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.45 : 0.35),
          width: 1.0,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppFontSize.nano,
          fontWeight: AppFontWeight.bold,
        ),
      ),
    );
  }

  /// 詳細ルール用（上品なニュートラルグレー統一トーン）
  Widget _buildDetailBadge({
    required BuildContext context,
    required String label,
  }) {
    final bg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    final border = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);
    final text = context.appColors.textColor;

    return Container(
      margin: const EdgeInsets.only(right: 6, top: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2.5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.sub,
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: AppFontSize.nano,
          fontWeight: AppFontWeight.medium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Single Source of Truth: KendoSceneHelperから色を取得
    final honsenColor = KendoSceneHelper.getColor(
      KendoMatchScene.honsen,
      isDark: isDark,
    );
    final renseikaiColor = KendoSceneHelper.getColor(
      KendoMatchScene.renseikai,
      isDark: isDark,
    );
    final moushiawaseColor = KendoSceneHelper.getColor(
      KendoMatchScene.moushiawase,
      isDark: isDark,
    );

    if (ruleSet.isMultiScene) {
      final List<Widget> sceneChips = [];

      // 1. ⚔️ 錬成
      if (ruleSet.useRenseikaiRule) {
        sceneChips.add(
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildSceneTag(
                label: KendoSceneHelper.getIconLabel(KendoMatchScene.renseikai),
                color: renseikaiColor,
              ),
              _buildDetailBadge(
                context: context,
                label:
                    '⏱️ ${formatMinutes(ruleSet.renseikaiRule.matchTimeMinutes)}',
              ),
              if (ruleSet.renseikaiRule.isRunningTime)
                _buildDetailBadge(context: context, label: '🔄 通し'),
              if (ruleSet.renseikaiRule.hasHantei)
                _buildDetailBadge(context: context, label: '⚖️ 引分有'),
            ],
          ),
        );
      }

      // 2. 🏆 本戦
      if (ruleSet.useHonsenRule) {
        if (sceneChips.isNotEmpty) {
          sceneChips.add(const SizedBox(height: 2));
        }
        sceneChips.add(
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildSceneTag(
                label: KendoSceneHelper.getIconLabel(KendoMatchScene.honsen),
                color: honsenColor,
              ),
              _buildDetailBadge(
                context: context,
                label:
                    '⏱️ ${formatMinutes(ruleSet.normalRule.matchTimeMinutes)}',
              ),
              if (ruleSet.normalRule.hasRepresentativeMatch)
                _buildDetailBadge(context: context, label: '🥋 代表戦有'),
              if (ruleSet.normalRule.isEnchoUnlimited ||
                  ruleSet.normalRule.enchoCount > 0)
                _buildDetailBadge(
                  context: context,
                  label: ruleSet.normalRule.isEnchoUnlimited
                      ? '⏳ 延長無制限'
                      : '⏳ 延長${ruleSet.normalRule.enchoCount}回',
                ),
              if (ruleSet.normalRule.hasHantei)
                _buildDetailBadge(context: context, label: '⚖️ 判定有'),
            ],
          ),
        );
      }

      // 3. 🤝 申合せ
      if (ruleSet.useMoushiawaseRule) {
        if (sceneChips.isNotEmpty) {
          sceneChips.add(const SizedBox(height: 2));
        }
        sceneChips.add(
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildSceneTag(
                label: KendoSceneHelper.getIconLabel(
                  KendoMatchScene.moushiawase,
                ),
                color: moushiawaseColor,
              ),
              _buildDetailBadge(
                context: context,
                label:
                    '⏱️ ${formatMinutes(ruleSet.moushiawaseRule.matchTimeMinutes)}',
              ),
              if (ruleSet.moushiawaseRule.isRunningTime)
                _buildDetailBadge(context: context, label: '🔄 通し'),
              if (ruleSet.moushiawaseRule.hasHantei)
                _buildDetailBadge(context: context, label: '⚖️ 引分有'),
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

    // 単一シーンの場合
    final bool isIndividual = ruleSet.matchType.contains('個人');
    final String typeLabel = isIndividual
        ? '🥋 個人戦'
        : (ruleSet.matchType.contains('錬成') ? '⚔️ 錬成' : '👥 団体戦');
    final Color typeColor = isIndividual
        ? const Color(0xFF00838F) // 落ち着いたシアンインディゴ
        : (ruleSet.matchType.contains('錬成') ? renseikaiColor : honsenColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildSceneTag(label: typeLabel, color: typeColor),
            _buildDetailBadge(
              context: context,
              label: '⏱️ ${formatMinutes(ruleSet.normalRule.matchTimeMinutes)}',
            ),
            if (ruleSet.normalRule.isIpponShobu)
              _buildDetailBadge(context: context, label: '⚡ 1本勝負'),
            if (ruleSet.normalRule.isRunningTime)
              _buildDetailBadge(context: context, label: '🔄 通し'),
            if (ruleSet.normalRule.hasRepresentativeMatch && !isIndividual)
              _buildDetailBadge(context: context, label: '🥋 代表戦有'),
            if (ruleSet.normalRule.isEnchoUnlimited ||
                ruleSet.normalRule.enchoCount > 0)
              _buildDetailBadge(
                context: context,
                label: ruleSet.normalRule.isEnchoUnlimited
                    ? '⏳ 延長無制限'
                    : '⏳ 延長${ruleSet.normalRule.enchoCount}回',
              ),
            if (ruleSet.normalRule.hasHantei)
              _buildDetailBadge(context: context, label: '⚖️ 判定有'),
          ],
        ),
        if (ruleSet.useAdvancedRule)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildSceneTag(label: '🔥 上位戦', color: honsenColor),
                _buildDetailBadge(
                  context: context,
                  label:
                      '⏱️ ${formatMinutes(ruleSet.advancedRule.matchTimeMinutes)}',
                ),
                if (ruleSet.advancedRule.isEnchoUnlimited ||
                    ruleSet.advancedRule.enchoCount > 0)
                  _buildDetailBadge(
                    context: context,
                    label: ruleSet.advancedRule.isEnchoUnlimited
                        ? '⏳ 延長無制限'
                        : '⏳ 延長${ruleSet.advancedRule.enchoCount}回',
                  ),
                if (ruleSet.advancedRule.hasHantei)
                  _buildDetailBadge(context: context, label: '⚖️ 判定有'),
              ],
            ),
          ),
      ],
    );
  }
}
