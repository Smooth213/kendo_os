import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_export_bar.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';

/// 部内戦公式記録画面のPDF印刷・画像シェアアクションバー
class BunaiksenRecordActionBar extends StatelessWidget {
  final Color cardColor;
  final bool isDark;
  final bool isExporting;
  final VoidCallback onPrintPdf;
  final VoidCallback onShareImage;
  final bool hasMultipleCategories;
  final OfficialRecordExportScope exportScope;
  final ValueChanged<OfficialRecordExportScope>? onScopeChanged;

  const BunaiksenRecordActionBar({
    super.key,
    required this.cardColor,
    required this.isDark,
    required this.isExporting,
    required this.onPrintPdf,
    required this.onShareImage,
    this.hasMultipleCategories = false,
    this.exportScope = OfficialRecordExportScope.current,
    this.onScopeChanged,
  });

  Widget _buildScopeSwitch(BuildContext context) {
    final isAll = exportScope == OfficialRecordExportScope.all;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                    '全試合形式一括出力',
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasMultipleCategories) _buildScopeSwitch(context),
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  icon: Icons.print,
                  label: 'PDF印刷',
                  color: context.appColors.errorColor,
                  onTap: isExporting ? null : onPrintPdf,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildButton(
                  icon: Icons.ios_share,
                  label: '画像シェア',
                  color: const Color(0xFF06C755),
                  onTap: isExporting ? null : onShareImage,
                ),
              ),
            ],
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
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        elevation: 0,
      ),
    );
  }
}
