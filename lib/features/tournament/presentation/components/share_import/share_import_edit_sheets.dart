import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/category_selection_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/match_format_selection_bottom_sheet.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

/// 🥋 共有インポート用：チーム情報編集ボトムシート群
abstract final class ShareImportEditSheets {
  /// 試合形式選択ボトムシートを表示
  static Future<String?> showMatchTypeSheet({
    required BuildContext context,
    required String teamName,
    required String currentMatchType,
    required Color accentColor,
    required Color subTextColor,
  }) async {
    return MatchFormatSelectionBottomSheet.show(
      context: context,
      title: '「$teamName」の試合形式',
      initialMatchType: currentMatchType,
      accentColor: accentColor,
    );
  }

  /// カテゴリ（部門）選択ボトムシートを表示
  static Future<String?> showCategorySheet({
    required BuildContext context,
    required String teamName,
    required String currentCategory,
    required Color accentColor,
    required Color subTextColor,
  }) async {
    return CategorySelectionBottomSheet.show(
      context: context,
      title: '「$teamName」のカテゴリ（部門）',
      initialCategory: currentCategory,
      accentColor: accentColor,
    );
  }

  /// チーム名変更ボトムシートを表示
  static Future<String?> showTeamNameSheet({
    required BuildContext context,
    required String currentTeamName,
    required Color accentColor,
    required Color textColor,
    required Color subTextColor,
  }) async {
    final controller = TextEditingController(text: currentTeamName);
    try {
      return await showAppBottomSheet<String>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => AppBottomSheetContent(
          title: 'チーム名の変更',
          titleIcon: Icons.edit,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '新しいチーム名を入力してください',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: subTextColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: AppFontWeight.bold,
                    color: textColor,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'チーム名',
                    hintText: '例: 低学年A, 中学生男子',
                    prefixIcon: Icon(Icons.groups),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    onPressed: () {
                      final val = controller.text.trim();
                      if (val.isNotEmpty) Navigator.of(ctx).pop(val);
                    },
                    color: accentColor,
                    icon: Icons.check,
                    label: '変更を保存',
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      );
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    }
  }
}
