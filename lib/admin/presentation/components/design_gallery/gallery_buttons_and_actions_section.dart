import 'package:flutter/material.dart';
import 'package:kendo_os/shared/presentation/widgets/app_card.dart';
import 'package:kendo_os/shared/presentation/widgets/app_glass_container.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

/// 🔘 デザインカタログ: ボタン ＆ アクション階層 セクション
class GalleryButtonsAndActionsSection extends StatelessWidget {
  const GalleryButtonsAndActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '1. ボタンの階層言語 (Hierarchy)'),
        _buildButtonHierarchyCard(context),
        const SizedBox(height: AppSpacing.md),
        _buildSectionHeader(context, '2. ボタンサイズ ＆ インラインアクション (Sizes)'),
        _buildButtonSizesCard(context),
        const SizedBox(height: AppSpacing.md),
        _buildSectionHeader(context, '3. iOS 27 浮遊カプセル型 FAB (Floating Button)'),
        _buildFloatingActionSampleCard(context),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.xs,
        top: AppSpacing.xs,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppFontSize.small,
          fontWeight: AppFontWeight.bold,
          color: context.appColors.subTextColor,
        ),
      ),
    );
  }

  /// ボタン階層カード（Primary / Secondary / Destructive / Disabled）
  Widget _buildButtonHierarchyCard(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          // Primary
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    AppHaptics.light();
                    AppSnackBar.showSuccess(context, 'Primary ボタンがタップされました');
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Primary アクション'),
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    backgroundColor: context.appColors.primaryAccent,
                    foregroundColor: context.appColors.onPrimaryAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Secondary
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppHaptics.light();
                    AppSnackBar.showSuccess(context, 'Secondary ボタンがタップされました');
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Secondary アウトライン'),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: BorderSide(color: context.appColors.primaryAccent),
                    foregroundColor: context.appColors.primaryAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Destructive & Disabled
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    AppHaptics.error();
                    AppSnackBar.showError(context, 'Destructive 操作が実行されました');
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('削除・破棄'),
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    backgroundColor: context.appColors.errorColor,
                    foregroundColor: AppKendoColors.pureWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: const Text('無効状態'),
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ボタンサイズバリエーションカード
  Widget _buildButtonSizesCard(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '高頻度操作・テーブル行・ダイアログに応じた3大サイズ仕様',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              color: context.appColors.subTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 大: 48px
              ElevatedButton(
                onPressed: () => AppHaptics.selection(),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  backgroundColor: context.appColors.primaryAccent,
                  foregroundColor: context.appColors.onPrimaryAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                ),
                child: const Text('大: 48px (標準)'),
              ),
              // 中: 36px
              OutlinedButton(
                onPressed: () => AppHaptics.selection(),
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  side: BorderSide(color: context.appColors.separatorColor),
                  foregroundColor: context.appColors.textColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                child: const Text('中: 36px (ダイアログ)'),
              ),
              // 小: 28px
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: context.appColors.inputBackground,
                  borderRadius: AppRadius.capsule,
                  border: Border.all(
                    color: context.appColors.separatorColor,
                    width: 0.5,
                  ),
                ),
                child: Material(
                  color: AppKendoColors.transparent,
                  child: InkWell(
                    borderRadius: AppRadius.capsule,
                    onTap: () => AppHaptics.selection(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: context.appColors.subTextColor,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            '小: 28px インライン',
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.bold,
                              color: context.appColors.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 浮遊カプセル型 FAB
  Widget _buildFloatingActionSampleCard(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: context.appColors.primaryAccent,
              borderRadius: AppRadius.capsule,
              boxShadow: AppShadows.iosFloating,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: context.appColors.onPrimaryAccent,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '新規試合を追加',
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: AppFontWeight.bold,
                    color: context.appColors.onPrimaryAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '浮遊シャドウ ＆ StadiumBorder で画面前面に配置される拡張FAB',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: context.appColors.subTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
