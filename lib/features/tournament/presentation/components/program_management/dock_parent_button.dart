import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 ドックの種別バリアント（大会用 vs 部内戦用）
enum DockVariant {
  /// 通常戦・公式大会（正円 × 一本ゴールド枠 × トロフィー 🏆）
  tournament,

  /// 部内戦専用（角丸8角形八角鍔 × 白銀プラチナ枠 × 盾 🛡️）
  bunaiksen,
}

/// 🥋 ドックの親ボタン（金枠/白銀枠ハイライト・展開時✕マーク回転変形・未読バッジ内包）
class DockParentButton extends StatelessWidget {
  final bool isDark;
  final AppThemeColors themeColors;
  final int unreadCount;
  final bool isExpanded;
  final bool isDocked;
  final bool isEditMode;
  final double buttonSize;
  final double closeButtonSize;
  final String? timerBadge;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final DockVariant variant;

  const DockParentButton({
    super.key,
    required this.isDark,
    required this.themeColors,
    required this.unreadCount,
    required this.isExpanded,
    required this.isDocked,
    this.isEditMode = false,
    required this.buttonSize,
    required this.closeButtonSize,
    required this.onTap,
    this.timerBadge,
    this.onLongPress,
    this.variant = DockVariant.tournament,
  });

  @override
  Widget build(BuildContext context) {
    final currentSize = isExpanded ? closeButtonSize : buttonSize;
    final currentIconSize = isExpanded ? 24.0 : 28.0;
    final isBunaiksen = variant == DockVariant.bunaiksen;

    // 枠線カラーの決定
    final Color borderColor = isEditMode
        ? AppKendoColors.pureWhite
        : (isExpanded
              ? AppKendoColors.pureWhite.withValues(alpha: 0.8)
              : (isBunaiksen
                    ? (isDark
                          ? AppKendoColors.pureWhite.withValues(
                              alpha: isDocked ? 0.75 : 0.95,
                            )
                          : const Color(
                              0xFF94A3B8,
                            ).withValues(alpha: isDocked ? 0.75 : 0.95))
                    : AppKendoColors.ipponGold.withValues(
                        alpha: isDocked ? 0.6 : 0.95,
                      )));

    // 形状（部内戦かつ折りたたみ時は八角鍔・角丸8角形、大会時および展開時は正円）
    final OutlinedBorder currentShape = (isBunaiksen && !isExpanded)
        ? StarBorder.polygon(
            sides: 8,
            pointRounding: 0.25,
            side: BorderSide(color: borderColor, width: 2.2),
          )
        : CircleBorder(side: BorderSide(color: borderColor, width: 2.0));

    // グロー＆ドロップシャドウ（立体的な浮き上がり感の強化）の決定
    final List<BoxShadow> shadows = isEditMode
        ? [
            BoxShadow(
              color: AppKendoColors.pureBlack.withValues(
                alpha: isDark ? 0.45 : 0.22,
              ),
              blurRadius: 14,
              spreadRadius: 1,
              offset: const Offset(0, 7),
            ),
            BoxShadow(
              color: AppKendoColors.teal.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ]
        : (isExpanded
              ? [
                  BoxShadow(
                    color: AppKendoColors.pureBlack.withValues(
                      alpha: isDark ? 0.5 : 0.25,
                    ),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(0, 7),
                  ),
                  BoxShadow(
                    color: AppKendoColors.redAccent.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : (isBunaiksen
                    ? [
                        // 深いアンビエントシャドウ（空中にくっきり浮き上がらせる影）
                        BoxShadow(
                          color: AppKendoColors.pureBlack.withValues(
                            alpha: isDark ? 0.6 : 0.16,
                          ),
                          blurRadius: 16,
                          spreadRadius: 1,
                          offset: const Offset(0, 8),
                        ),
                        // 直下シャドウ（八角鍔のシャープな輪郭強調）
                        BoxShadow(
                          color: AppKendoColors.pureBlack.withValues(
                            alpha: isDark ? 0.4 : 0.1,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                        // 白銀プラチナハイライト（ダーク時グロー / ライト時はシルバー光彩）
                        BoxShadow(
                          color: isDark
                              ? AppKendoColors.pureWhite.withValues(
                                  alpha: isDocked ? 0.3 : 0.55,
                                )
                              : const Color(
                                  0xFFCBD5E1,
                                ).withValues(alpha: isDocked ? 0.3 : 0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : [
                        // 深いアンビエントシャドウ（大会ドックの浮き上がり影）
                        BoxShadow(
                          color: AppKendoColors.pureBlack.withValues(
                            alpha: isDark ? 0.55 : 0.18,
                          ),
                          blurRadius: 16,
                          spreadRadius: 1,
                          offset: const Offset(0, 8),
                        ),
                        // 直下シャドウ（円形輪郭の接地感）
                        BoxShadow(
                          color: AppKendoColors.pureBlack.withValues(
                            alpha: isDark ? 0.35 : 0.1,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                        // 一本ゴールドアクセントグロー
                        BoxShadow(
                          color: AppKendoColors.ipponGold.withValues(
                            alpha: isDocked ? 0.25 : 0.4,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]));

    // 背景グラデーションの決定
    final List<Color> gradientColors = isEditMode
        ? [AppKendoColors.teal, AppKendoColors.successGreen]
        : (isExpanded
              ? [AppKendoColors.deepOrange, AppKendoColors.redAccent]
              : (isDark
                    ? (isBunaiksen
                          ? const [Color(0xFF232B3E), Color(0xFF0F172A)]
                          : const [Color(0xFF1E293B), Color(0xFF0F172A)])
                    : [
                        themeColors.cardBackground,
                        themeColors.cardBackground.withValues(alpha: 0.95),
                      ]));

    // アイコンの決定
    final IconData iconData = isEditMode
        ? Icons.check_rounded
        : (isExpanded
              ? Icons.close_rounded
              : (isBunaiksen
                    ? Icons.shield_rounded
                    : Icons.emoji_events_rounded));

    // アイコンカラーの決定（部内戦ライトモード時はディープパープルで美しく調和）
    final Color iconColor = (isEditMode || isExpanded)
        ? AppKendoColors.pureWhite
        : (isBunaiksen
              ? (isDark ? AppKendoColors.pureWhite : themeColors.primaryAccent)
              : (isDark
                    ? AppKendoColors.ipponGold
                    : themeColors.primaryAccent));

    final Decoration currentDecoration = (isBunaiksen && !isExpanded)
        ? ShapeDecoration(
            shape: currentShape,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            shadows: shadows,
          )
        : BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            boxShadow: shadows,
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: currentSize,
          height: currentSize,
          decoration: currentDecoration,
          child: Material(
            color: AppKendoColors.transparent,
            shape: currentShape,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              customBorder: currentShape,
              child: Center(
                child: AnimatedRotation(
                  turns: isEditMode ? 0.0 : (isExpanded ? 0.25 : 0.0),
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: currentIconSize,
                  ),
                ),
              ),
            ),
          ),
        ),
        // タイマー動作中ミニピルバッジ (⏱️ 02:45)
        if (!isDocked && timerBadge != null && !isExpanded)
          Positioned(
            bottom: -8,
            left: -12,
            right: -12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs / 2,
              ),
              decoration: BoxDecoration(
                color: AppKendoColors.deepOrange,
                borderRadius: AppRadius.round,
                border: Border.all(color: AppKendoColors.pureWhite, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppKendoColors.black.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_rounded,
                    size: 10,
                    color: AppKendoColors.pureWhite,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    timerBadge!,
                    style: const TextStyle(
                      color: AppKendoColors.pureWhite,
                      fontSize: AppFontSize.micro,
                      fontWeight: AppFontWeight.bold,
                      fontFamily: 'monospace',
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // 未読アナウンスバッジ
        if (!isDocked && unreadCount > 0 && !isExpanded)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: AppKendoColors.redAccent,
                borderRadius: AppRadius.full,
                border: Border.all(color: AppKendoColors.pureWhite, width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: AppKendoColors.pureBlack.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: AppKendoColors.pureWhite,
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
