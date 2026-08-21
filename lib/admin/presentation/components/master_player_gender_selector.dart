import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 選手登録・編集用 性別選択ボタンコンポーネント
class MasterPlayerGenderSelector extends StatelessWidget {
  final String selectedGender;
  final ValueChanged<String> onGenderChanged;

  const MasterPlayerGenderSelector({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  Widget _buildGenderBtn({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required bool isSel,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final finalColor = isSel ? color : context.appColors.subTextColor;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSel
            ? color.withValues(alpha: isDark ? 0.2 : 0.1)
            : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF2F2F7)),
        side: BorderSide(
          color: isSel
              ? color
              : (isDark
                    ? const Color(0xFFFFFFFF)
                    : context.appColors.separatorColor),
          width: isSel ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: finalColor),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: TextStyle(
              fontSize: AppFontSize.body,
              fontWeight: AppFontWeight.bold,
              color: finalColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '性別',
          style: TextStyle(
            fontSize: AppFontSize.bodySmall,
            fontWeight: AppFontWeight.bold,
            color: isDark ? const Color(0xFFFFFFFF) : AppKendoColors.grey,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildGenderBtn(
                context: context,
                title: '男子',
                icon: Icons.man,
                color: AppKendoColors.blue,
                isSel: selectedGender == '男子',
                isDark: isDark,
                onTap: () => onGenderChanged('男子'),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _buildGenderBtn(
                context: context,
                title: '女子',
                icon: Icons.woman,
                color: AppKendoColors.pink,
                isSel: selectedGender == '女子',
                isDark: isDark,
                onTap: () => onGenderChanged('女子'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
