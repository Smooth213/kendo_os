import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
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
    final candidateMatchTypes =
        TournamentTeamAutoRegisterService.candidateMatchTypes;

    return showAppBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        return AppBottomSheetContent(
          title: '「$teamName」の試合形式',
          titleIcon: Icons.sports_kabaddi,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '試合形式を選択してください：',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: subTextColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: candidateMatchTypes.map((type) {
                    final isSel = currentMatchType == type;
                    return AppChoiceChip(
                      label: Text(type),
                      selected: isSel,
                      selectedColor: accentColor.withValues(alpha: 0.2),
                      onSelected: (_) => Navigator.of(ctx).pop(type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
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
    final candidateCategories = [
      '小学生低学年の部',
      '小学生高学年の部',
      '小学生の部',
      '中学生の部',
      '中学生男子の部',
      '中学生女子の部',
      '高校生の部',
      '一般の部',
    ];

    return showAppBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        return AppBottomSheetContent(
          title: '「$teamName」のカテゴリ（部門）',
          titleIcon: Icons.category,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '所属する部門を選択してください：',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: subTextColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: candidateCategories.map((cat) {
                    final isSel = currentCategory == cat;
                    return AppChoiceChip(
                      label: Text(cat),
                      selected: isSel,
                      selectedColor: accentColor.withValues(alpha: 0.2),
                      onSelected: (_) => Navigator.of(ctx).pop(cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
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
    return showAppBottomSheet<String>(
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
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
