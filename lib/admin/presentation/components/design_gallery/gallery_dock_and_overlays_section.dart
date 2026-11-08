import 'package:flutter/material.dart';
import 'package:kendo_os/shared/presentation/widgets/app_card.dart';
import 'package:kendo_os/shared/presentation/widgets/app_glass_container.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 🚢 デザインカタログ: 常設ドック ＆ オーバーレイ（シート・ダイアログ・トースト）セクション
class GalleryDockAndOverlaysSection extends StatelessWidget {
  const GalleryDockAndOverlaysSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '1. 常設フローティングドック (Floating Dock アイランド)'),
        _buildFloatingDockSampleCard(context),
        const SizedBox(height: AppSpacing.md),
        _buildSectionHeader(context, '2. iOS 27 ボトムシート ＆ AppDialog (モーダル)'),
        _buildModalsCard(context),
        const SizedBox(height: AppSpacing.md),
        _buildSectionHeader(context, '3. トースト通知バナー (AppSnackBar ＆ Haptics)'),
        _buildToastsCard(context),
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

  /// 常設フローティングドックの見本
  Widget _buildFloatingDockSampleCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '画面下部に常駐する次世代フローティングアイランド (AppShadows.iosDock ＆ カプセル)',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              color: context.appColors.subTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: context.appColors.cardBackground,
                borderRadius: AppRadius.capsule,
                boxShadow: AppShadows.iosDock,
                border: Border.all(
                  color: context.appColors.hairlineBorder,
                  width: AppBorderWidth.hairline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDockIcon(
                    context,
                    icon: Icons.menu_book_rounded,
                    label: 'プログラム',
                    color: AppKendoColors.ipponGold,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildDockIcon(
                    context,
                    icon: Icons.edit_note_rounded,
                    label: 'メモ',
                    color: context.appColors.primaryAccent,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildDockIcon(
                    context,
                    icon: Icons.sports_kabaddi,
                    label: '部内戦',
                    color: AppKendoColors.purple,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildDockIcon(
                    context,
                    icon: Icons.settings_rounded,
                    label: '設定',
                    color: context.appColors.subTextColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockIcon(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Material(
      color: AppKendoColors.transparent,
      child: InkWell(
        borderRadius: AppRadius.capsule,
        onTap: () {
          AppHaptics.selection();
          AppSnackBar.showSuccess(context, 'ドック機能「$label」がタップされました');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppFontSize.micro,
                  fontWeight: AppFontWeight.bold,
                  color: context.appColors.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ボトムシート ＆ ダイアログ
  Widget _buildModalsCard(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                AppHaptics.light();
                showAppBottomSheet(
                  context: context,
                  builder: (sheetContext) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'iOS 27 ボトムシート',
                            style: TextStyle(
                              fontSize: AppFontSize.body,
                              fontWeight: AppFontWeight.bold,
                              color: context.appColors.textColor,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '36x5px カプセルグラブバー ＆ Squircle 連続角丸 ＆ ヘアライン境界',
                            style: TextStyle(
                              fontSize: AppFontSize.small,
                              color: context.appColors.subTextColor,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    );
                  },
                );
              },
              style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
              child: const Text('ボトムシート'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                AppHaptics.light();
                showAppDialog(
                  context: context,
                  builder: (dialogContext) {
                    return AppDialog(
                      title: 'iOS 27 ダイアログ',
                      content: const Text(
                        '0.5pxヘアライン境界とSquircle角丸で統一されたダイアログです。',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('閉じる'),
                        ),
                      ],
                    );
                  },
                );
              },
              style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
              child: const Text('ダイアログ'),
            ),
          ),
        ],
      ),
    );
  }

  /// トースト通知カード
  Widget _buildToastsCard(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                AppHaptics.success();
                AppSnackBar.showSuccess(context, '操作が正常に完了しました');
              },
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('成功トースト'),
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                backgroundColor: context.appColors.successColor,
                foregroundColor: AppKendoColors.pureWhite,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                AppHaptics.error();
                AppSnackBar.showError(context, '通信エラーが発生しました');
              },
              icon: const Icon(Icons.error, size: 16),
              label: const Text('エラートースト'),
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                backgroundColor: context.appColors.errorColor,
                foregroundColor: AppKendoColors.pureWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
