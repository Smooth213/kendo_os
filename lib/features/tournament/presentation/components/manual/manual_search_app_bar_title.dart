import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🔍 マニュアル検索AppBarタイトルウィジェット（純粋UIコンポーネント）
class ManualSearchAppBarTitle extends StatelessWidget {
  final bool isSearching;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const ManualSearchAppBarTitle({
    super.key,
    required this.isSearching,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSearching) {
      return const Text(
        'ヘルプ・マニュアル',
        style: TextStyle(fontSize: AppFontSize.subhead),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? AppKendoColors.tealAccent
        : context.appColors.primaryAccent;
    final searchIconColor = isDark
        ? AppKendoColors.tealAccent
        : context.appColors.primaryAccent;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.compact),
      decoration: BoxDecoration(
        color: isDark
            ? context.appColors.cardBackground.withValues(alpha: 0.26)
            : context.appColors.textColor,
        borderRadius: AppRadius.medium,
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color:
                (isDark
                        ? context.appColors.cardBackground
                        : const Color(0x33000000))
                    .withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.search, color: searchIconColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppTextField(
              controller: searchController,
              autofocus: true,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFF000000),
                fontSize: AppFontSize.body,
                fontWeight: AppFontWeight.medium,
              ),
              decoration: InputDecoration(
                hintText: 'マニュアル内を検索...',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppKendoColors.white60
                      : AppKendoColors.black45,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }
}
