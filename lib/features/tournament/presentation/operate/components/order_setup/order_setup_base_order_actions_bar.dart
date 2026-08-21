import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 基本オーダーの「登録」および「呼出」アクションバー
class OrderSetupBaseOrderActionsBar extends StatelessWidget {
  final AppThemeColors themeColors;
  final bool isDark;
  final bool canLoadBaseOrder;
  final VoidCallback onSaveBaseOrder;
  final VoidCallback onLoadBaseOrder;

  const OrderSetupBaseOrderActionsBar({
    super.key,
    required this.themeColors,
    required this.isDark,
    required this.canLoadBaseOrder,
    required this.onSaveBaseOrder,
    required this.onLoadBaseOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onSaveBaseOrder,
              icon: const Icon(Icons.save_alt, size: 16),
              label: const Text(
                '基本オーダーに登録',
                style: TextStyle(fontSize: AppFontSize.small),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark
                    ? AppKendoColors.pureWhite
                    : themeColors.primaryAccent,
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF64B5F6)
                      : themeColors.primaryAccent,
                  width: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canLoadBaseOrder ? onLoadBaseOrder : null,
              icon: const Icon(Icons.download, size: 16),
              label: const Text(
                '基本オーダーを呼出',
                style: TextStyle(fontSize: AppFontSize.small),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0),
                foregroundColor: isDark
                    ? AppKendoColors.pureWhite
                    : const Color(0xFF0F172A),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
