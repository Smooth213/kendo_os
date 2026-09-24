import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/band/presentation/components/band_group_edit_dialog.dart';
import 'package:kendo_os/features/band/presentation/providers/band_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

/// 🥋 設定画面に組み込むBAND連携管理タイル
class BandSettingsTile extends ConsumerWidget {
  const BandSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(bandGroupsStreamProvider);
    final count = groupsAsync.value?.length ?? 0;

    return ListTile(
      leading: ClipRRect(
        borderRadius: AppRadius.medium,
        child: Image.asset(
          'assets/images/band_icon.png',
          width: 38,
          height: 38,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(
        'BAND連携・LIVE配信設定',
        style: TextStyle(
          color: context.appColors.textColor,
          fontSize: AppFontSize.bodyMedium,
          fontWeight: AppFontWeight.medium,
        ),
      ),
      subtitle: Text(
        count > 0
            ? '$count件のグループが登録されています（※要BANDアプリ）'
            : '未登録（タップしてグループを追加 ※要BANDアプリ）',
        style: const TextStyle(fontSize: AppFontSize.caption),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () => BandSettingsManagementSheet.show(context),
    );
  }
}

/// 🥋 BANDグループ一括管理ボトムシート
class BandSettingsManagementSheet extends ConsumerWidget {
  const BandSettingsManagementSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showAppBottomSheet(
      context: context,
      builder: (_) => const BandSettingsManagementSheet(),
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
      title: 'BANDグループ管理',
      titleIcon: Icons.cell_tower,
      titleTrailing: IconButton(
        icon: const Icon(Icons.add_circle, color: Color(0xFF00C73C), size: 28),
        tooltip: '新しいBandを追加',
        onPressed: () => BandGroupEditDialog.show(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF00C73C).withValues(alpha: 0.1),
              borderRadius: AppRadius.small,
              border: Border.all(
                color: const Color(0xFF00C73C).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Color(0xFF00C73C),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'ワンタップ直接起動には各端末に「BANDアプリ」のインストールが必要です。',
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
          const SizedBox(height: AppSpacing.sm),
          Text(
            '道場ID配下で保存され、同じ道場の全メンバーの端末に自動同期されます。学年別・所属別（低学年・高学年など）のグループURLを登録してください。',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              color: themeColors.subTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          groupsAsync.when(
            data: (groups) {
              if (groups.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.group_add,
                          size: 48,
                          color: themeColors.subTextColor,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          '登録済みのBANDグループはありません',
                          style: TextStyle(fontWeight: AppFontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: () => BandGroupEditDialog.show(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00C73C),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('最初のBandグループを追加'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: AppRadius.small,
                      child: Image.asset(
                        'assets/images/band_icon.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      group.name,
                      style: const TextStyle(fontWeight: AppFontWeight.bold),
                    ),
                    subtitle: Text(
                      group.url.isNotEmpty ? group.url : 'URL未登録',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        color: themeColors.subTextColor,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: '編集',
                          onPressed: () => BandGroupEditDialog.show(
                            context,
                            initialGroup: group,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text(
              'エラー: $e',
              style: TextStyle(color: themeColors.errorColor),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
