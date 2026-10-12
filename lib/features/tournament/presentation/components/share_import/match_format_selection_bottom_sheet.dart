import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_format_selector_view.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

/// 🥋 試合形式詳細選択ボトムシート（5大分類カスケード対応）
class MatchFormatSelectionBottomSheet extends StatefulWidget {
  final String title;
  final String initialMatchType;
  final Color? accentColor;

  const MatchFormatSelectionBottomSheet({
    super.key,
    required this.title,
    required this.initialMatchType,
    this.accentColor,
  });

  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String initialMatchType,
    Color? accentColor,
  }) {
    return showAppBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => MatchFormatSelectionBottomSheet(
        title: title,
        initialMatchType: initialMatchType,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<MatchFormatSelectionBottomSheet> createState() =>
      _MatchFormatSelectionBottomSheetState();
}

class _MatchFormatSelectionBottomSheetState
    extends State<MatchFormatSelectionBottomSheet> {
  late String _selectedMatchType;

  @override
  void initState() {
    super.initState();
    _selectedMatchType = widget.initialMatchType;
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? context.appColors.primaryAccent;
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return AppBottomSheetContent(
      title: widget.title,
      titleIcon: Icons.sports_kabaddi,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MatchFormatSelectorView(
              currentMatchType: _selectedMatchType,
              themeColors: themeColors,
              onMatchTypeChanged: (newType) {
                setState(() {
                  _selectedMatchType = newType;
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.mediumValue),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: accent, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '設定される試合形式',
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            color: subTextColor,
                          ),
                        ),
                        Text(
                          _selectedMatchType,
                          style: TextStyle(
                            fontSize: AppFontSize.headline,
                            fontWeight: AppFontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                onPressed: () {
                  Navigator.of(context).pop(_selectedMatchType);
                },
                color: accent,
                icon: Icons.check,
                label: 'この形式に設定',
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
