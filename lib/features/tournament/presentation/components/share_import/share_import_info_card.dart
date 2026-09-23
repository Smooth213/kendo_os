import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 🥋 共有インポート用：情報カード共通ウィジェット
class ShareImportInfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final List<Widget> children;

  const ShareImportInfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.largeValue),
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppFontSize.headline,
                  fontWeight: AppFontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }
}
