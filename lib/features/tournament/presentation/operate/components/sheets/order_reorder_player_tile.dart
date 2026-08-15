import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// オーダー並び替えシート内で1選手（ポジション枠または控え枠）を描画する純粋UIコンポーネント
class OrderReorderPlayerTile extends StatelessWidget {
  final String label;
  final String playerName;
  final bool isPosition;
  final bool isDark;

  const OrderReorderPlayerTile({
    super.key,
    required this.label,
    required this.playerName,
    required this.isPosition,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      color: isPosition
          ? (isDark ? const Color(0xFF2C2C2E) : context.appColors.infoColor)
          : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isPosition
                ? const Color(0xFF2196F3)
                : const Color(0x8A000000),
            borderRadius: AppRadius.tiny,
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppKendoColors.pureWhite,
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
            ),
          ),
        ),
        title: Text(
          playerName,
          style: TextStyle(
            fontWeight: isPosition ? AppFontWeight.bold : AppFontWeight.regular,
          ),
        ),
        trailing: const Icon(Icons.drag_handle),
      ),
    );
  }
}
