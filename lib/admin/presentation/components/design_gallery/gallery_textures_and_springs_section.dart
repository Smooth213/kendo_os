import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/widgets/app_card.dart';
import 'package:kendo_os/shared/presentation/widgets/app_glass_container.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';

/// 🎨 デザインカタログ: 基盤テクスチャ・物理スプリング・フロストガラス セクション
class GalleryTexturesAndSpringsSection extends ConsumerWidget {
  const GalleryTexturesAndSpringsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '1. 着せ替え基盤・モード制御'),
        _buildGlassControlCard(context, ref, settings.enableLiquidGlass),
        const SizedBox(height: AppSpacing.md),
        _buildSectionHeader(context, '2. iOS 27 フロストガラス (AppGlassContainer)'),
        _buildGlassPreviewCard(context, isDark),
        const SizedBox(height: AppSpacing.md),
        _buildSectionHeader(context, '3. 物理スプリングカード (AppCard)'),
        _buildSpringCardsSection(context),
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

  Widget _buildGlassControlCard(
    BuildContext context,
    WidgetRef ref,
    bool enableLiquidGlass,
  ) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: context.appColors.primaryAccent,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liquid Glass (フロストガラス)',
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: AppFontWeight.bold,
                    color: context.appColors.textColor,
                  ),
                ),
                Text(
                  enableLiquidGlass
                      ? 'ON: 薄層ブラー ＋ 0.5pxヘアライン境界'
                      : 'OFF: ソリッド高コントラスト（省電力・屋外モード）',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: context.appColors.subTextColor,
                  ),
                ),
              ],
            ),
          ),
          AppSwitch(
            value: enableLiquidGlass,
            onChanged: (val) {
              AppHaptics.selection();
              ref
                  .read(settingsProvider.notifier)
                  .updateSettings(
                    ref.read(settingsProvider).copyWith(enableLiquidGlass: val),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPreviewCard(BuildContext context, bool isDark) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: context.appColors.successColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '0.5px Hairline Squircle Border',
                style: TextStyle(
                  fontSize: AppFontSize.small,
                  fontWeight: AppFontWeight.semiBold,
                  color: context.appColors.textColor,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Loading例',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: context.appColors.subTextColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const AppLoadingIndicator.small(),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'RepaintBoundaryで高頻度再描画から完全保護された次世代ガラスコンテナ。背面の液状グラデーションやスクロールコンテンツを美しく透過・拡散します。',
            style: TextStyle(
              fontSize: AppFontSize.small,
              color: context.appColors.subTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpringCardsSection(BuildContext context) {
    return AppCard(
      onTap: () {
        AppHaptics.light();
        AppSnackBar.showSuccess(context, '0.98倍スプリングバウンス ＆ Light触覚が発火しました');
      },
      child: Row(
        children: [
          Icon(Icons.touch_app, color: context.appColors.primaryAccent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'タップしてスプリング体験 (AppCard)',
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: AppFontWeight.bold,
                    color: context.appColors.textColor,
                  ),
                ),
                Text(
                  '指を触れると0.98倍に縮小し、離すと物理スプリングで復元',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: context.appColors.subTextColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: context.appColors.subTextColor,
          ),
        ],
      ),
    );
  }
}
