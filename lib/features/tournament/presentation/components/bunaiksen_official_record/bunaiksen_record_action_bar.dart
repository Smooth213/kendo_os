import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 部内戦公式記録画面のPDF印刷・画像シェアアクションバー
class BunaiksenRecordActionBar extends StatelessWidget {
  final Color cardColor;
  final bool isDark;
  final bool isExporting;
  final VoidCallback onPrintPdf;
  final VoidCallback onShareImage;

  const BunaiksenRecordActionBar({
    super.key,
    required this.cardColor,
    required this.isDark,
    required this.isExporting,
    required this.onPrintPdf,
    required this.onShareImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0x33000000),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              icon: Icons.print,
              label: 'PDF印刷',
              color: context.appColors.textColor,
              onTap: isExporting ? null : onPrintPdf,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildButton(
              icon: Icons.share,
              label: '画像シェア',
              color: const Color(0xFF06C755),
              onTap: isExporting ? null : onShareImage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
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
