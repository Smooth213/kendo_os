import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 試合カード右上に「進行中 / 終了 / 待機中」を表示する純粋UIバッジコンポーネント
class MatchStatusBadge extends StatelessWidget {
  final bool isPlaying;
  final bool isFinished;
  final bool isDark;

  const MatchStatusBadge({
    super.key,
    required this.isPlaying,
    required this.isFinished,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.subValue,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isPlaying
            ? context.appColors.infoColor
            : (isFinished
                  ? (context.appColors.separatorColor)
                  : (isDark
                        ? const Color(0xFF2C2C2E)
                        : context.appColors.separatorColor)),
        borderRadius: AppRadius.tiny,
      ),
      child: Text(
        isPlaying ? '進行中' : (isFinished ? '終了' : '待機中'),
        style: TextStyle(
          fontSize: AppFontSize.badge,
          fontWeight: AppFontWeight.bold,
          color: isPlaying
              ? AppKendoColors.pureWhite
              : (isFinished
                    ? (context.appColors.subTextColor)
                    : (isDark
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xDE000000))),
        ),
      ),
    );
  }
}
