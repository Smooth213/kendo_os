import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 設定画面のテスト用インタラクティブエリア（画面下部固定）
class SettingsTestActionPanel extends StatefulWidget {
  final SettingsModel settings;
  final bool enableLiquidGlass;
  final AppThemeColors themeColors;

  const SettingsTestActionPanel({
    super.key,
    required this.settings,
    required this.enableLiquidGlass,
    required this.themeColors,
  });

  @override
  State<SettingsTestActionPanel> createState() =>
      _SettingsTestActionPanelState();
}

class _SettingsTestActionPanelState extends State<SettingsTestActionPanel> {
  String _testMessage = '下のボタンをタップしてテスト';
  static const Color accentPink = Color(0xFFE06287);

  @override
  Widget build(BuildContext context) {
    final Color dynamicTextColor = context.appColors.textColor;

    return SafeArea(
      top: false,
      child: Container(
        margin: widget.enableLiquidGlass
            ? const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              )
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: widget.themeColors.cardBackground,
          borderRadius: widget.enableLiquidGlass
              ? AppRadius.xlarge
              : BorderRadius.zero,
          border: widget.enableLiquidGlass
              ? Border.all(color: widget.themeColors.separatorColor, width: 1.5)
              : null,
          boxShadow: widget.enableLiquidGlass
              ? [
                  BoxShadow(
                    color: AppKendoColors.pureBlack.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppKendoColors.pureBlack.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: widget.enableLiquidGlass
              ? AppRadius.xlarge
              : BorderRadius.zero,
          child: BackdropFilter(
            filter: widget.enableLiquidGlass
                ? ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0)
                : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _testMessage,
                    style: TextStyle(
                      color: dynamicTextColor,
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.bodySmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GestureDetector(
                    onTap: () {
                      if (widget.settings.haptic) {
                        HapticFeedback.lightImpact();
                      }
                      if (widget.settings.confirmBehavior == 'long') {
                        setState(() => _testMessage = '⚠️ 長押ししてください');
                      } else if (widget.settings.confirmBehavior == 'double') {
                        setState(() => _testMessage = '⚠️ ダブルタップしてください');
                      } else {
                        setState(() => _testMessage = '✅ 確定しました (通常タップ)');
                        if (widget.settings.haptic) {
                          HapticFeedback.mediumImpact();
                        }
                      }
                    },
                    onDoubleTap: () {
                      if (widget.settings.confirmBehavior == 'double') {
                        setState(() => _testMessage = '✅ 確定しました (ダブルタップ)');
                        if (widget.settings.haptic) {
                          HapticFeedback.heavyImpact();
                        }
                      }
                    },
                    onLongPress: () {
                      if (widget.settings.confirmBehavior == 'long') {
                        setState(() => _testMessage = '✅ 確定しました (長押し)');
                        if (widget.settings.haptic) {
                          HapticFeedback.heavyImpact();
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: accentPink,
                        borderRadius: AppRadius.large,
                        boxShadow: [
                          BoxShadow(
                            color: accentPink.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'テスト用：試合終了ボタン',
                          style: TextStyle(
                            color: AppKendoColors.pureWhite,
                            fontSize: AppFontSize.subhead,
                            fontWeight: AppFontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
