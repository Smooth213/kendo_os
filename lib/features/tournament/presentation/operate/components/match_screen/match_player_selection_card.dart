import 'package:flutter/material.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 選手名変更ボトムシート内の選手選択カード
class MatchPlayerSelectionCard extends StatelessWidget {
  final PlayerModel player;
  final bool isSub;
  final bool isCurrentPosition;
  final String? currentPosition;
  final VoidCallback? onTap;

  const MatchPlayerSelectionCard({
    super.key,
    required this.player,
    required this.isSub,
    required this.isCurrentPosition,
    this.currentPosition,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;

    final Color badgeColor = isSub
        ? const Color(0xFF009688)
        : const Color(0xFFFF9800);

    final Color cardColor = isDark
        ? badgeColor.withValues(alpha: 0.18)
        : badgeColor.withValues(alpha: 0.12);

    final BorderSide borderSide = BorderSide(
      color: isDark
          ? badgeColor.withValues(alpha: 0.5)
          : badgeColor.withValues(alpha: 0.6),
      width: 1.2,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.subValue),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.compact,
        side: borderSide,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 0,
        ),
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: badgeColor,
          child: Text(
            player.name.isNotEmpty ? player.name.substring(0, 1) : '?',
            style: const TextStyle(
              color: AppKendoColors.pureWhite, // ★ クッキリ白文字で視認性100%確保
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.bodySmall,
            ),
          ),
        ),
        title: Text(
          player.name,
          style: TextStyle(
            fontWeight: AppFontWeight.bold,
            color: textColor,
            fontSize: AppFontSize.body,
          ),
        ),
        subtitle: Text(
          currentPosition != null
              ? (isCurrentPosition ? 'このポジション' : '$currentPositionで出場中')
              : '${player.gradeName} / ${player.gender}',
          style: TextStyle(
            color: isDark
                ? badgeColor.withValues(alpha: 0.9)
                : (isSub ? const Color(0xFF00796B) : const Color(0xFFE65100)),
            fontSize: AppFontSize.caption,
            fontWeight: currentPosition != null
                ? AppFontWeight.bold
                : AppFontWeight.regular,
          ),
        ),
        trailing: Icon(
          isSub ? Icons.check_circle_outline : Icons.swap_horiz_rounded,
          size: 22,
          color: isDark
              ? badgeColor
              : (isSub ? const Color(0xFF00796B) : const Color(0xFFE65100)),
        ),
        onTap: isCurrentPosition ? null : onTap,
      ),
    );
  }
}
