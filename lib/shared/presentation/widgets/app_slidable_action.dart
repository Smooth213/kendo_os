import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 🥋 最新 iOS メモアプリ風 浮遊カプセル型スワイプアクションボタン（Floating Capsule Action）
class AppSlidableAction extends StatelessWidget {
  final SlidableActionCallback? onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final int flex;
  final bool autoClose;
  final EdgeInsetsGeometry padding;

  const AppSlidableAction({
    super.key,
    this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    this.foregroundColor = AppKendoColors.pureWhite,
    this.flex = 1,
    this.autoClose = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.subValue,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return CustomSlidableAction(
      onPressed: onPressed,
      autoClose: autoClose,
      flex: flex,
      backgroundColor: AppKendoColors.transparent,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: padding,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.round,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: foregroundColor),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  color: foregroundColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
