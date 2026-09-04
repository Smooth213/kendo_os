import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/application/services/thermal_power_governor.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

/// 🔋 【設定・安心感の可視化】サーマル冷却＆バッテリー稼働状況ミニバッジ
///
/// 体育館での猛暑稼働時、端末の発熱防止・省電力制御が自動で作動していることを
/// 運営者・保護者に控えめに可視化し、高い安心感を提供します。
class ThermalStatusBadge extends ConsumerWidget {
  final bool showLabel;
  final bool? isLightSurface;
  final bool isSwitchSize;

  const ThermalStatusBadge({
    super.key,
    this.showLabel = true,
    this.isLightSurface,
    this.isSwitchSize = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final governor = ref.watch(thermalPowerGovernorProvider);
    final mode = governor.mode;
    final isLight =
        isLightSurface ?? (Theme.of(context).brightness == Brightness.light);

    IconData iconData;
    String label;
    Color badgeColor;
    Color textColor;
    Color borderColor;

    switch (mode) {
      case ThermalPowerMode.normal:
        iconData = Icons.bolt_rounded;
        label = '高速';
        if (isLight) {
          badgeColor = const Color(0xFFE2E8F0); // 爽やかなライトスレートグレー
          textColor = const Color(0xFF334155); // 濃いスレートグレーで高いコントラスト
          borderColor = const Color(0xFFCBD5E1);
        } else {
          badgeColor = AppKendoColors.pureWhite.withValues(alpha: 0.2);
          textColor = AppKendoColors.pureWhite;
          borderColor = AppKendoColors.pureWhite.withValues(alpha: 0.4);
        }
        break;
      case ThermalPowerMode.ecoCooling:
        iconData = Icons.battery_charging_full_rounded; // 🔋 冷却
        label = '冷却';
        badgeColor = const Color(0xFF10B981); // エメラルドグリーン
        textColor = AppKendoColors.pureWhite;
        borderColor = const Color(0xFF059669);
        break;
      case ThermalPowerMode.ultraSave:
        iconData = Icons.energy_savings_leaf_rounded; // 🌿 省電力
        label = '省電力';
        badgeColor = const Color(0xFFF59E0B); // アンバーオレンジ
        textColor = AppKendoColors.pureWhite;
        borderColor = const Color(0xFFD97706);
        break;
    }

    final badgeRadius = isSwitchSize ? AppRadius.large : AppRadius.round;
    final iconSize = isSwitchSize ? AppFontSize.body : AppFontSize.caption;
    final fontSize = isSwitchSize
        ? (label.length >= 3 ? AppFontSize.caption : AppFontSize.small)
        : AppFontSize.nano;
    final padding = isSwitchSize
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.subValue,
            vertical: AppSpacing.xs,
          )
        : const EdgeInsets.symmetric(
            horizontal: AppSpacing.subValue,
            vertical: AppSpacing.xxs,
          );

    return Tooltip(
      message: 'サーマル冷却ステータス（タップして詳細表示）',
      child: InkWell(
        onTap: () => _showThermalInfoSheet(context, governor),
        borderRadius: badgeRadius,
        child: Container(
          width: isSwitchSize ? 64.0 : null,
          height: isSwitchSize ? 31.0 : null,
          alignment: Alignment.center,
          padding: padding,
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: badgeRadius,
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(iconData, size: iconSize, color: textColor),
                if (showLabel) ...[
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: fontSize,
                      fontWeight: AppFontWeight.bold,
                      letterSpacing: isSwitchSize ? -0.3 : -0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showThermalInfoSheet(
    BuildContext context,
    ThermalPowerGovernor governor,
  ) {
    showAppBottomSheet(
      context: context,
      builder: (ctx) {
        final mode = governor.mode;
        String modeTitle;
        String modeDesc;
        String savingText;
        IconData modeIcon;
        Color modeColor;

        switch (mode) {
          case ThermalPowerMode.normal:
            modeTitle = '通常高速モード (100ms)';
            modeDesc = '最高精度のレスポンスで快適に動作しています。';
            savingText = 'CPU負荷: 標準稼働';
            modeIcon = Icons.bolt_rounded;
            modeColor = const Color(0xFF3B82F6);
            break;
          case ThermalPowerMode.ecoCooling:
            modeTitle = 'エコサーマル冷却モード (500ms)';
            modeDesc = '端末の発熱（熱暴走）を防ぐため、ポーリング間隔を自動調整しています。';
            savingText = 'CPU負荷: 80% 削減中（端末冷却・発熱防止）';
            modeIcon = Icons.battery_charging_full_rounded;
            modeColor = const Color(0xFF10B981);
            break;
          case ThermalPowerMode.ultraSave:
            modeTitle = '極限省電力モード (1000ms)';
            modeDesc = 'バッテリー低下を検知し、大会終了まで稼働を最優先で延命しています。';
            savingText = 'CPU負荷: 90% 削減中（最大バッテリー延命）';
            modeIcon = Icons.energy_savings_leaf_rounded;
            modeColor = const Color(0xFFF59E0B);
            break;
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.roundValue,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: modeColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        modeIcon,
                        color: modeColor,
                        size: AppFontSize.display,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🛡️ サーマル冷却＆省電力ステータス',
                            style: TextStyle(
                              fontSize: AppFontSize.bodySmall,
                              color: context.appColors.subTextColor,
                              fontWeight: AppFontWeight.semiBold,
                            ),
                          ),
                          Text(
                            modeTitle,
                            style: TextStyle(
                              fontSize: AppFontSize.subhead,
                              fontWeight: AppFontWeight.bold,
                              color: modeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: modeColor.withValues(alpha: 0.08),
                    borderRadius: AppRadius.medium,
                    border: Border.all(color: modeColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: modeColor,
                        size: AppFontSize.headline,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          savingText,
                          style: TextStyle(
                            fontSize: AppFontSize.small,
                            fontWeight: AppFontWeight.bold,
                            color: modeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  modeDesc,
                  style: TextStyle(
                    fontSize: AppFontSize.bodySmall,
                    height: 1.4,
                    color: context.appColors.textColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      color: context.appColors.primaryAccent,
                      size: AppFontSize.subhead,
                    ),
                    const SizedBox(width: AppSpacing.subValue),
                    Expanded(
                      child: Text(
                        '【時間精度100%保証】タイマーは端末の内蔵絶対時計から計算しているため、省電力中でも残り秒数がズレることは一切ありません。',
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          color: context.appColors.subTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appColors.inputBackground,
                      foregroundColor: context.appColors.textColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.compact,
                      ),
                    ),
                    child: const Text(
                      '閉じる',
                      style: TextStyle(fontWeight: AppFontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
