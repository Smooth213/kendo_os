import 'package:flutter/material.dart';
import 'package:kendo_os/shared/presentation/widgets/app_card.dart';
import 'package:kendo_os/shared/presentation/widgets/app_glass_container.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🎨 デザインカタログ: カラーパレット ＆ タイポグラフィ セクション
class GalleryPaletteTypographySection extends StatelessWidget {
  const GalleryPaletteTypographySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '1. セマンティックカラーパレット (AppThemeColors)'),
        _buildPaletteGridCard(context),
        const SizedBox(height: AppSpacing.md),
        _buildSectionHeader(context, '2. タイポグラフィ階層 (AppFontSize スケール)'),
        _buildTypographyScaleCard(context),
        const SizedBox(height: AppSpacing.md),
        _buildSectionHeader(
          context,
          '3. iOS 27 極細0.5pxヘアライン境界 (Hairline Border)',
        ),
        _buildHairlineComparisonCard(context),
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

  /// セマンティックカラーグリッド
  Widget _buildPaletteGridCard(BuildContext context) {
    final colors = [
      (
        name: 'Primary Accent',
        color: context.appColors.primaryAccent,
        note: '主操作・ブランド',
      ),
      (
        name: 'Soft Accent',
        color: context.appColors.softAccent,
        note: '選択背景・ソフト',
      ),
      (name: 'Rose Pink', color: context.appColors.rosePink, note: '女性・ハイライト'),
      (
        name: 'Success Color',
        color: context.appColors.successColor,
        note: '完了・同期成功',
      ),
      (
        name: 'Warning Color',
        color: context.appColors.warningColor,
        note: '注意・オフライン',
      ),
      (
        name: 'Error Color',
        color: context.appColors.errorColor,
        note: 'エラー・反則',
      ),
      (
        name: 'Info Color',
        color: context.appColors.infoColor,
        note: '情報・アナウンス',
      ),
      (
        name: 'Text Color',
        color: context.appColors.textColor,
        note: '主本文・高コントラスト',
      ),
      (
        name: 'SubText Color',
        color: context.appColors.subTextColor,
        note: '補助文字・薄色',
      ),
      (
        name: 'Separator Color',
        color: context.appColors.separatorColor,
        note: '区切り線・通常枠',
      ),
    ];

    return AppGlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: colors.map((c) {
          return Container(
            width: 155,
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: context.appColors.cardBackground,
              borderRadius: AppRadius.medium,
              border: Border.all(
                color: context.appColors.hairlineBorder,
                width: AppBorderWidth.hairline,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.appColors.separatorColor.withValues(
                        alpha: 0.3,
                      ),
                      width: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          fontWeight: AppFontWeight.bold,
                          color: context.appColors.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        c.note,
                        style: TextStyle(
                          fontSize: AppFontSize.micro,
                          color: context.appColors.subTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// タイポグラフィ階層カード
  Widget _buildTypographyScaleCard(BuildContext context) {
    final styles = [
      (
        label: 'Scoreboard Timer (48px)',
        size: AppFontSize.scoreboardTimer,
        weight: AppFontWeight.black,
        sample: '03:45',
      ),
      (
        label: 'Display (24px)',
        size: AppFontSize.display,
        weight: AppFontWeight.black,
        sample: '全国高等学校剣道大会',
      ),
      (
        label: 'Headline (18px)',
        size: AppFontSize.headline,
        weight: AppFontWeight.bold,
        sample: '第1試合場 トーナメント表',
      ),
      (
        label: 'Title (17px)',
        size: AppFontSize.title,
        weight: AppFontWeight.bold,
        sample: '男子団体戦 決勝トーナメント',
      ),
      (
        label: 'Body (14px)',
        size: AppFontSize.body,
        weight: AppFontWeight.regular,
        sample: '標準本文テキスト。体育館の遠距離でも視認性を維持します。',
      ),
      (
        label: 'Small (12px)',
        size: AppFontSize.small,
        weight: AppFontWeight.semiBold,
        sample: '補助情報・メタデータ・所属連盟表記',
      ),
      (
        label: 'Caption (11px)',
        size: AppFontSize.caption,
        weight: AppFontWeight.regular,
        sample: '注釈・タイムスタンプ・説明文テキスト',
      ),
      (
        label: 'Micro (8px)',
        size: AppFontSize.micro,
        weight: AppFontWeight.bold,
        sample: 'バッジ内極小表示 (一本・反則・種別)',
      ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: styles.map((s) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.label,
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.bold,
                    color: context.appColors.primaryAccent,
                  ),
                ),
                Text(
                  s.sample,
                  style: TextStyle(
                    fontSize: s.size,
                    fontWeight: s.weight,
                    color: context.appColors.textColor,
                  ),
                ),
                Divider(
                  height: AppSpacing.sm,
                  color: context.appColors.separatorColor.withValues(
                    alpha: 0.3,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// ヘアライン境界線の実例比較
  Widget _buildHairlineComparisonCard(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.appColors.cardBackground,
                borderRadius: AppRadius.medium,
                border: Border.all(
                  color: context.appColors.hairlineBorder,
                  width: AppBorderWidth.hairline,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '0.5px ヘアライン境界',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: AppFontWeight.bold,
                      color: context.appColors.textColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '光の反射エッジを再現 (iOS 27 標準)',
                    style: TextStyle(
                      fontSize: AppFontSize.micro,
                      color: context.appColors.subTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.appColors.cardBackground,
                borderRadius: AppRadius.medium,
                border: Border.all(
                  color: context.appColors.separatorColor,
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '1.0px 通常境界',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: AppFontWeight.bold,
                      color: context.appColors.textColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '標準的なセパレーター枠線',
                    style: TextStyle(
                      fontSize: AppFontSize.micro,
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
}
