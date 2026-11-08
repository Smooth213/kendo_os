import 'package:flutter/material.dart';
import 'package:kendo_os/shared/presentation/widgets/app_card.dart';
import 'package:kendo_os/shared/presentation/widgets/app_glass_container.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 デザインカタログ: 剣道競技ドメイン ＆ スコアボード セクション
class GalleryKendoDomainSection extends StatelessWidget {
  const GalleryKendoDomainSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '1. 紅白対戦対比（Red vs White）'),
        _buildVersusCard(context),
        const SizedBox(height: AppSpacing.md),
        _buildSectionHeader(context, '2. 一本ゴールド ＆ 反則レッド ＆ 打突種別'),
        _buildStrikePointsCard(context),
        const SizedBox(height: AppSpacing.md),
        _buildSectionHeader(context, '3. 試合スコアボード見本（スコア枠 ＆ 勝者判定）'),
        _buildScoreboardSampleCard(context),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.xs,
        top: AppSpacing.xs,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppFontSize.small,
          fontWeight: AppFontWeight.bold,
          color: context.appColors.subTextColor,
        ),
      ),
    );
  }

  /// 紅白対戦対比カード（赤帯・白帯と選手名表示）
  Widget _buildVersusCard(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          // 赤選手側
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppKendoColors.akaDark.withValues(alpha: 0.15),
                borderRadius: AppRadius.medium,
                border: Border.all(
                  color: AppKendoColors.aka.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppKendoColors.aka,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Text(
                        '赤 (紅帯)',
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          fontWeight: AppFontWeight.bold,
                          color: AppKendoColors.aka,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '武蔵 剣士',
                    style: TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: AppFontWeight.bold,
                      color: context.appColors.textColor,
                    ),
                  ),
                  Text(
                    '東都剣道連盟',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: context.appColors.subTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              'VS',
              style: TextStyle(
                fontSize: AppFontSize.small,
                fontWeight: AppFontWeight.black,
                color: context.appColors.subTextColor,
              ),
            ),
          ),
          // 白選手側
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.appColors.cardBackground,
                borderRadius: AppRadius.medium,
                border: Border.all(
                  color: context.appColors.separatorColor,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppKendoColors.pureWhite,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.appColors.subTextColor,
                            width: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '白 (白帯)',
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          fontWeight: AppFontWeight.bold,
                          color: context.appColors.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '小次郎 剣士',
                    style: TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: AppFontWeight.bold,
                      color: context.appColors.textColor,
                    ),
                  ),
                  Text(
                    '西海剣道倶楽部',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: context.appColors.subTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 一本ゴールド ＆ 反則レッド ＆ 打突種別
  Widget _buildStrikePointsCard(BuildContext context) {
    final points = [
      (label: 'メ', name: '面 (Men)', color: AppKendoColors.ipponGold),
      (label: 'コ', name: '小手 (Kote)', color: AppKendoColors.ipponGold),
      (label: 'ド', name: '胴 (Do)', color: AppKendoColors.ipponGold),
      (label: 'ツ', name: '突 (Tsuki)', color: AppKendoColors.ipponGold),
      (label: '▲', name: '反則 (Foul)', color: AppKendoColors.hansokuRed),
    ];

    return AppGlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: points.map((p) {
          final isGold = p.color == AppKendoColors.ipponGold;
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isGold
                  ? AppKendoColors.ipponGold.withValues(alpha: 0.18)
                  : AppKendoColors.hansokuRed.withValues(alpha: 0.15),
              borderRadius: AppRadius.capsule,
              border: Border.all(
                color: isGold
                    ? AppKendoColors.ipponGold
                    : AppKendoColors.hansokuRed,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isGold
                        ? AppKendoColors.ipponGold
                        : AppKendoColors.hansokuRed,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    p.label,
                    style: const TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.black,
                      color: AppKendoColors.pureBlack,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  p.name,
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.bold,
                    color: context.appColors.textColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// スコアボード見本
  Widget _buildScoreboardSampleCard(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '第1試合場・決勝戦',
                style: TextStyle(
                  fontSize: AppFontSize.small,
                  fontWeight: AppFontWeight.semiBold,
                  color: context.appColors.subTextColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: context.appColors.inputBackground,
                  borderRadius: AppRadius.capsule,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: context.appColors.subTextColor,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      '03:45',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.bold,
                        color: context.appColors.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 赤スコア
              Column(
                children: [
                  const Text(
                    '武蔵 (赤)',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: AppFontWeight.bold,
                      color: AppKendoColors.aka,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      _buildScoreSlot(context, 'メ', true),
                      const SizedBox(width: AppSpacing.xs),
                      _buildScoreSlot(context, 'コ', true),
                    ],
                  ),
                ],
              ),
              // 勝敗中央
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppKendoColors.ipponGold.withValues(alpha: 0.2),
                      borderRadius: AppRadius.capsule,
                      border: Border.all(
                        color: AppKendoColors.ipponGold,
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      '二本勝ち',
                      style: TextStyle(
                        fontSize: AppFontSize.micro,
                        fontWeight: AppFontWeight.bold,
                        color: AppKendoColors.pureBlack,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '2 - 1',
                    style: TextStyle(
                      fontSize: AppFontSize.display,
                      fontWeight: AppFontWeight.black,
                      color: context.appColors.textColor,
                    ),
                  ),
                ],
              ),
              // 白スコア
              Column(
                children: [
                  Text(
                    '小次郎 (白)',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: AppFontWeight.bold,
                      color: context.appColors.textColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      _buildScoreSlot(context, 'ド', true),
                      const SizedBox(width: AppSpacing.xs),
                      _buildScoreSlot(context, '', false),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSlot(BuildContext context, String point, bool isAcquired) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isAcquired
            ? AppKendoColors.ipponGold
            : context.appColors.inputBackground,
        shape: BoxShape.circle,
        border: Border.all(
          color: isAcquired
              ? AppKendoColors.ipponGold
              : context.appColors.separatorColor,
          width: 1,
        ),
      ),
      child: Text(
        point,
        style: TextStyle(
          fontSize: AppFontSize.caption,
          fontWeight: AppFontWeight.black,
          color: isAcquired
              ? AppKendoColors.pureBlack
              : context.appColors.subTextColor,
        ),
      ),
    );
  }
}
