import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/shared/presentation/widgets/app_card.dart';
import 'package:kendo_os/shared/presentation/widgets/app_glass_container.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_scene_badge.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/thermal_status_badge.dart';

/// 🏷️ デザインカタログ: 試合シーン ＆ 進行ステータス セクション
class GallerySceneAndStatusSection extends StatelessWidget {
  const GallerySceneAndStatusSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '1. 4大試合シーンバッジ (KendoSceneBadge)'),
        _buildSceneBadgesCard(context, isDark),
        const SizedBox(height: AppSpacing.md),
        _buildSectionHeader(context, '2. 試合進行ステータスバッジ (MatchStatusBadge)'),
        _buildMatchStatusBadgesCard(context, isDark),
        const SizedBox(height: AppSpacing.md),
        _buildSectionHeader(
          context,
          '3. サーマル冷却 ＆ 省電力制御バッジ (ThermalStatusBadge)',
        ),
        _buildThermalBadgeCard(context),
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

  /// 4大シーンバッジカード（アウトライン型 ＆ 塗りつぶし型）
  Widget _buildSceneBadgesCard(BuildContext context, bool isDark) {
    const scenes = [
      (scene: KendoMatchScene.honsen, desc: '大会公式戦（インディゴ系）'),
      (scene: KendoMatchScene.renseikai, desc: '練習試合・錬成会（オレンジ系）'),
      (scene: KendoMatchScene.moushiawase, desc: '特別対戦・申合せ（ローズ系）'),
      (scene: KendoMatchScene.bunaiksen, desc: '道場部内戦（パープル系）'),
    ];

    return AppGlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: scenes.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                KendoSceneBadge(scene: item.scene, isDark: isDark),
                const SizedBox(width: AppSpacing.xs),
                KendoSceneBadge(
                  scene: item.scene,
                  isFilled: true,
                  isDark: isDark,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.desc,
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: context.appColors.subTextColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 試合進行ステータスバッジ
  Widget _buildMatchStatusBadgesCard(BuildContext context, bool isDark) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              MatchStatusBadge(
                isPlaying: true,
                isFinished: false,
                isDark: isDark,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '進行中（LIVE）- 赤点滅 ＆ カプセルPill',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: context.appColors.subTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              MatchStatusBadge(
                isPlaying: false,
                isFinished: false,
                isDark: isDark,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '待機中 - ニュートラルカプセル',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: context.appColors.subTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              MatchStatusBadge(
                isPlaying: false,
                isFinished: true,
                isDark: isDark,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '終了済み - 完了トーン',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: context.appColors.subTextColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// サーマル冷却バッジカード
  Widget _buildThermalBadgeCard(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const ThermalStatusBadge(isSwitchSize: true),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '端末サーマル適応制御バッジ',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: AppFontWeight.bold,
                    color: context.appColors.textColor,
                  ),
                ),
                Text(
                  '体育館での高熱・直射日光検知時に「高速 ⇔ 冷却中」を自動切替',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: context.appColors.subTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
