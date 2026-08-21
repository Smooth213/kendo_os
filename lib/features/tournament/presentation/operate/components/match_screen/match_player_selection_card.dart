import 'package:flutter/material.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
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

    Color cardColor;
    BorderSide borderSide;
    if (isSub) {
      cardColor = isDark
          ? const Color(0xFF009688).withValues(alpha: 0.2)
          : const Color(0xFF009688).withValues(alpha: 0.6);
      borderSide = const BorderSide(color: Color(0xFF009688));
    } else {
      cardColor = isDark
          ? const Color(0xFFFF9800).withValues(alpha: 0.15)
          : const Color(0xFFFF9800).withValues(alpha: 0.6);
      borderSide = const BorderSide(color: Color(0xFFFF9800));
    }

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
          backgroundColor: isSub
              ? const Color(0xFF009688)
              : const Color(0xFFFF9800),
          child: Text(
            player.name.substring(0, 1),
            style: TextStyle(
              color: isSub
                  ? (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF009688))
                  : (isDark
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFFFF9800)),
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.small,
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
            color: isSub ? const Color(0xFF009688) : const Color(0xFFFF9800),
            fontSize: AppFontSize.caption,
            fontWeight: currentPosition != null
                ? AppFontWeight.bold
                : AppFontWeight.regular,
          ),
        ),
        trailing: Icon(
          isSub ? Icons.check_circle_outline : Icons.swap_horiz,
          size: 18,
          color: isSub ? const Color(0xFF009688) : const Color(0xFFFF9800),
        ),
        onTap: isCurrentPosition ? null : onTap,
      ),
    );
  }
}
