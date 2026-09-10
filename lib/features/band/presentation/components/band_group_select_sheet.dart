import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/band/domain/entities/band_group_model.dart';
import 'package:kendo_os/features/band/presentation/components/band_group_edit_dialog.dart';
import 'package:kendo_os/features/band/presentation/providers/band_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

/// 🥋 対戦カードコピー後のBANDグループ選択ボトムシート
class BandGroupSelectSheet extends ConsumerWidget {
  final String formattedText;

  const BandGroupSelectSheet({super.key, required this.formattedText});

  static Future<void> show(
    BuildContext context, {
    required String formattedText,
  }) {
    AppHaptics.medium();
    return showAppBottomSheet(
      context: context,
      builder: (_) => BandGroupSelectSheet(formattedText: formattedText),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final groupsAsync = ref.watch(bandGroupsStreamProvider);

    return AppBottomSheetContent(
      title: 'BANDでLIVE配信・共有',
      titleIcon: Icons.cell_tower,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. コピー完了バナー
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF00C73C).withValues(alpha: 0.12),
              borderRadius: AppRadius.medium,
              border: Border.all(
                color: const Color(0xFF00C73C).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF00C73C),
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '対戦カードをコピーしました！\n配信先のBANDグループを選択してください。',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                      color: themeColors.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. グループ一覧
          groupsAsync.when(
            data: (groups) {
              if (groups.isEmpty) {
                return _buildEmptyState(context, themeColors);
              }
              return _buildGroupList(context, groups, themeColors, isDark);
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'グループ一覧の読み込みに失敗しました: $e',
                style: TextStyle(color: themeColors.errorColor),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.xs),

          // 3. アクション行（テキストのみコピー / 追加）
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    AppHaptics.light();
                    Navigator.of(context).pop();
                    AppSnackBar.show(context, '対戦カードをクリップボードに保持しました');
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('コピーのみで閉じる'),
                  style: TextButton.styleFrom(
                    foregroundColor: themeColors.subTextColor,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  AppHaptics.selection();
                  BandGroupEditDialog.show(context);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Bandを追加'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00C73C),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppKendoColors.pureBlack.withValues(alpha: 0.05),
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        children: [
          Icon(
            Icons.group_off_outlined,
            size: 36,
            color: themeColors.subTextColor,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            '登録済みのBANDグループがありません',
            style: TextStyle(fontWeight: AppFontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'グループを登録しておくと、ワンタップでそのBandへジャンプできます。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFontSize.caption,
              color: themeColors.subTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  BandLauncherHelper.launchBandUrl('https://band.us');
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('BANDアプリを開く'),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () => BandGroupEditDialog.show(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00C73C),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('グループを登録'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList(
    BuildContext context,
    List<BandGroupModel> groups,
    AppThemeColors themeColors,
    bool isDark,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groups.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final group = groups[index];
        return Material(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
          borderRadius: AppRadius.medium,
          child: InkWell(
            borderRadius: AppRadius.medium,
            onTap: () {
              AppHaptics.selection();
              Navigator.of(context).pop();
              BandLauncherHelper.launchBandUrl(group.url);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.small,
                    child: Image.asset(
                      'assets/images/band_icon.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: AppFontSize.body,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                        if (group.url.isNotEmpty)
                          Text(
                            group.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppFontSize.nano,
                              color: themeColors.subTextColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: themeColors.subTextColor,
                    ),
                    tooltip: '編集',
                    onPressed: () =>
                        BandGroupEditDialog.show(context, initialGroup: group),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: themeColors.subTextColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
