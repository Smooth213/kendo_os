import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 公式記録画面におけるエクスポート（PDF/画像/CSV）アクションバー（純粋UIコンポーネント）
class OfficialRecordExportBar extends StatelessWidget {
  final bool isExporting;
  final String? exportingType;
  final VoidCallback? onPdfPressed;
  final VoidCallback? onImagePressed;
  final VoidCallback? onCsvPressed;
  final bool isDark;

  const OfficialRecordExportBar({
    super.key,
    required this.isExporting,
    this.exportingType,
    this.onPdfPressed,
    this.onImagePressed,
    this.onCsvPressed,
    required this.isDark,
  });

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isCurrentlyRunning,
    required VoidCallback? onPressed,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isCurrentlyRunning
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppKendoColors.pureWhite,
                ),
              )
            : Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: AppFontWeight.bold,
            fontSize: AppFontSize.small,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppKendoColors.pureWhite,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E)
            : context.appColors.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0x33000000),
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. PDF出力
          _buildActionButton(
            icon: Icons.print,
            label: 'PDF',
            color: context.appColors.errorColor,
            isCurrentlyRunning: isExporting && exportingType == 'pdf',
            onPressed: isExporting ? null : onPdfPressed,
          ),
          const SizedBox(width: AppSpacing.sm),
          // 2. 画像出力
          _buildActionButton(
            icon: Icons.ios_share,
            label: '画像',
            color: const Color(0xFF06C755),
            isCurrentlyRunning: isExporting && exportingType == 'image',
            onPressed: isExporting ? null : onImagePressed,
          ),
          const SizedBox(width: AppSpacing.sm),
          // 3. CSV出力
          _buildActionButton(
            icon: Icons.table_chart,
            label: 'CSV',
            color: context.appColors.primaryAccent,
            isCurrentlyRunning: isExporting && exportingType == 'csv',
            onPressed: isExporting ? null : onCsvPressed,
          ),
        ],
      ),
    );
  }
}
