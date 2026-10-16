import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 選手選択モーダル内の選手候補カードWidget（添付ファイル2準拠）
class MultiPlayerCandidateTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isSelected;
  final Color accentColor;
  final ValueChanged<bool?> onChanged;

  const MultiPlayerCandidateTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.isSelected,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initialLetter = name.isNotEmpty ? name.substring(0, 1) : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        side: isSelected
            ? BorderSide(color: accentColor, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accentColor.withValues(alpha: 0.2),
          child: Text(
            initialLetter,
            style: TextStyle(
              color: accentColor,
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.body,
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: AppFontWeight.bold,
            color: context.appColors.textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: accentColor, fontSize: AppFontSize.small),
        ),
        trailing: Icon(
          isSelected ? Icons.check_circle : Icons.touch_app,
          color: accentColor,
        ),
        onTap: () => onChanged(!isSelected),
      ),
    );
  }
}
