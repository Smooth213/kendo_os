import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

/// 試合画面下部のアクションボタン（シングル/ダブルタップ/長押し対応ボタン）
class MatchActionButtonRow extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String confirmBehavior;
  final VoidCallback? onAction;
  final bool isViewOnly;
  final Color backgroundColor;
  final String promptMessage;

  const MatchActionButtonRow({
    super.key,
    required this.label,
    this.icon,
    required this.confirmBehavior,
    required this.onAction,
    required this.isViewOnly,
    required this.backgroundColor,
    required this.promptMessage,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: AppKendoColors.pureWhite,
      padding: const EdgeInsets.symmetric(vertical: 0),
      minimumSize: const Size(double.infinity, 38),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      elevation: 0,
    );

    final textWidget = Text(
      label,
      style: const TextStyle(
        fontSize: AppFontSize.subhead,
        fontWeight: AppFontWeight.bold,
      ),
    );

    final buttonChild = icon != null
        ? ElevatedButton.icon(
            onPressed: confirmBehavior == 'single'
                ? onAction
                : (isViewOnly
                      ? null
                      : () => AppSnackBar.show(context, promptMessage)),
            onLongPress: confirmBehavior == 'long' ? onAction : null,
            icon: Icon(icon, color: AppKendoColors.pureWhite, size: 20),
            label: textWidget,
            style: style,
          )
        : ElevatedButton(
            onPressed: confirmBehavior == 'single'
                ? onAction
                : (isViewOnly
                      ? null
                      : () => AppSnackBar.show(context, promptMessage)),
            onLongPress: confirmBehavior == 'long' ? onAction : null,
            style: style,
            child: textWidget,
          );

    return GestureDetector(
      onDoubleTap: confirmBehavior == 'double' ? onAction : null,
      child: buttonChild,
    );
  }
}
