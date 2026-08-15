import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 公式記録・観戦記録画面におけるエクスポート・共有用アクションボタン（純粋UIコンポーネント）
class OfficialRecordActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const OfficialRecordActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: AppFontWeight.bold,
          fontSize: AppFontSize.bodySmall,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppKendoColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        elevation: 0,
      ),
    );
  }
}
