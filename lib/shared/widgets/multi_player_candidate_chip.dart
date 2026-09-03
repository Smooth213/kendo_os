import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 複数選手選択モーダル内の選手候補リストタイルWidget
class MultiPlayerCandidateTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isSelected;
  final Color accentColor;
  final IconData icon;
  final ValueChanged<bool?> onChanged;

  const MultiPlayerCandidateTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.isSelected,
    required this.accentColor,
    this.icon = Icons.person,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      activeColor: accentColor,
      value: isSelected,
      title: Text(name),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: AppFontSize.small,
          color: AppKendoColors.grey,
        ),
      ),
      secondary: CircleAvatar(
        backgroundColor: accentColor.withAlpha(26),
        child: Icon(icon, color: accentColor, size: 20),
      ),
      onChanged: onChanged,
    );
  }
}
