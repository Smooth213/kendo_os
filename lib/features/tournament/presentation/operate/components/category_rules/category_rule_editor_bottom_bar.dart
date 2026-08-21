import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

/// ルール編集画面 下部アクションバー（キャンセル / 保存）
class CategoryRuleEditorBottomBar extends StatelessWidget {
  final bool enableLiquidGlass;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const CategoryRuleEditorBottomBar({
    super.key,
    required this.enableLiquidGlass,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: enableLiquidGlass
            ? AppKendoColors.transparent
            : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF)),
        border: Border(
          top: BorderSide(
            color: enableLiquidGlass
                ? Colors.transparent
                : (isDark
                      ? const Color(0xFF38383A)
                      : context.appColors.separatorColor),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.modernValue,
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
              ),
              child: const Text(
                'キャンセル',
                style: TextStyle(fontWeight: AppFontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: GlassButton(
              onPressed: onSave,
              color: AppKendoColors.indigo,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.modernValue,
              ),
              label: '設定を保存',
              icon: Icons.save,
              expandContent: false,
            ),
          ),
        ],
      ),
    );
  }
}
