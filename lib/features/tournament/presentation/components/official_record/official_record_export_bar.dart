import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';

/// 公式記録出力の対象範囲（表示中の部 / すべての部）
enum OfficialRecordExportScope { current, all }

/// 公式記録画面におけるエクスポート（PDF/画像/CSV）アクションバー（純粋UIコンポーネント）
class OfficialRecordExportBar extends StatelessWidget {
  final bool isExporting;
  final String? exportingType;
  final VoidCallback? onPdfPressed;
  final VoidCallback? onImagePressed;
  final VoidCallback? onCsvPressed;
  final bool isDark;
  final OfficialRecordExportScope exportScope;
  final ValueChanged<OfficialRecordExportScope>? onScopeChanged;
  final bool hasMultipleCategories;
  final String? categoryName;

  const OfficialRecordExportBar({
    super.key,
    required this.isExporting,
    this.exportingType,
    this.onPdfPressed,
    this.onImagePressed,
    this.onCsvPressed,
    required this.isDark,
    this.exportScope = OfficialRecordExportScope.current,
    this.onScopeChanged,
    this.hasMultipleCategories = false,
    this.categoryName,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

  Widget _buildScopeSwitch(BuildContext context) {
    final isAll = exportScope == OfficialRecordExportScope.all;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: isExporting
                ? null
                : () => onScopeChanged?.call(
                    isAll
                        ? OfficialRecordExportScope.current
                        : OfficialRecordExportScope.all,
                  ),
            borderRadius: AppRadius.small,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '全カテゴリを一括出力',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: isAll
                          ? AppFontWeight.bold
                          : AppFontWeight.regular,
                      color: isAll
                          ? (isDark
                                ? AppKendoColors.pureWhite
                                : context.appColors.primaryAccent)
                          : context.appColors.subTextColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Transform.scale(
                    scale: 0.82,
                    child: AppSwitch(
                      value: isAll,
                      activeColor: AppKendoColors.green,
                      onChanged: isExporting
                          ? null
                          : (val) => onScopeChanged?.call(
                              val
                                  ? OfficialRecordExportScope.all
                                  : OfficialRecordExportScope.current,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAll = exportScope == OfficialRecordExportScope.all;
    final pdfLabel = isAll ? 'PDF（全）' : 'PDF';
    final imageLabel = isAll ? '画像（全）' : '画像';
    final csvLabel = isAll ? 'CSV（全）' : 'CSV';

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasMultipleCategories) _buildScopeSwitch(context),
          Row(
            children: [
              // 1. PDF出力
              _buildActionButton(
                icon: Icons.print,
                label: pdfLabel,
                color: context.appColors.errorColor,
                isCurrentlyRunning: isExporting && exportingType == 'pdf',
                onPressed: isExporting ? null : onPdfPressed,
              ),
              const SizedBox(width: AppSpacing.sm),
              // 2. 画像出力
              _buildActionButton(
                icon: Icons.ios_share,
                label: imageLabel,
                color: const Color(0xFF06C755),
                isCurrentlyRunning: isExporting && exportingType == 'image',
                onPressed: isExporting ? null : onImagePressed,
              ),
              const SizedBox(width: AppSpacing.sm),
              // 3. CSV出力
              _buildActionButton(
                icon: Icons.table_chart,
                label: csvLabel,
                color: context.appColors.primaryAccent,
                isCurrentlyRunning: isExporting && exportingType == 'csv',
                onPressed: isExporting ? null : onCsvPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
