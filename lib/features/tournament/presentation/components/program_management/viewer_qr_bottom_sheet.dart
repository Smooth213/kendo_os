import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// 🥋 観戦専用ビュアーのQRコード表示＆速報共有ボトムシート
class ViewerQrBottomSheet extends ConsumerWidget {
  final String tournamentId;
  final bool isViewerMode;

  const ViewerQrBottomSheet({
    super.key,
    required this.tournamentId,
    this.isViewerMode = false,
  });

  static void show(
    BuildContext context, {
    required String tournamentId,
    bool isViewerMode = false,
  }) {
    FloatingDockSheetManager.show(
      context: context,
      builder: (_) => ViewerQrBottomSheet(
        tournamentId: tournamentId,
        isViewerMode: isViewerMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final syncContext = ref.watch(currentSyncContextProvider);
    final dojoId = syncContext.organizationId;
    final isBunaiksen = tournamentId.startsWith('bunaiksen_');

    final path = isBunaiksen ? 'bunaiksen-viewer-home' : 'viewer-home';
    final shareUrl =
        'https://kendo-os-beta.web.app/$path/$tournamentId?role=viewer&dojoId=$dojoId';

    return DockDraggableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          children: [
            DockBottomSheetHeader(
              title: '観戦用QRコード ＆ 速報共有',
              icon: Icons.qr_code_2_rounded,
              iconColor: AppKendoColors.teal,
            ),
            const SizedBox(height: AppSpacing.sm),

            // 説明カード
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: themeColors.cardBackground,
                borderRadius: AppRadius.medium,
                border: Border.all(
                  color: themeColors.separatorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.remove_red_eye_rounded,
                    color: AppKendoColors.teal,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'カメラで読み取ると、ログイン不要・編集権限なしの「観戦専用ビュアー」が直接開きます。',
                      style: TextStyle(
                        fontSize: AppFontSize.bodySmall,
                        color: themeColors.subTextColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 大画面白地QRコード
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppKendoColors.pureWhite,
                  borderRadius: AppRadius.large,
                  boxShadow: [
                    BoxShadow(
                      color: AppKendoColors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: shareUrl,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: AppKendoColors.pureWhite,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '大会ID: $tournamentId',
                      style: const TextStyle(
                        fontSize: AppFontSize.badge,
                        color: AppKendoColors.grey,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ワンタップ共有ボタン（LINE・SNS）
            ElevatedButton.icon(
              onPressed: () {
                AppHaptics.medium();
                SharePlus.instance.share(
                  ShareParams(
                    text:
                        '【剣道リアルタイム観戦】今日の試合結果・速報をその場でリアルタイムに観戦できます！\n'
                        '▼ 観戦専用URL:\n$shareUrl',
                  ),
                );
              },
              icon: const Icon(
                Icons.ios_share,
                color: AppKendoColors.pureWhite,
              ),
              label: const Text(
                'LINEやSNSで観戦URLを送る',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  color: AppKendoColors.pureWhite,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppKendoColors.teal,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.medium,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // URLコピーボタン
            OutlinedButton.icon(
              onPressed: () {
                AppHaptics.selection();
                Clipboard.setData(ClipboardData(text: shareUrl));
                AppSnackBar.showSuccess(context, '観戦用URLをクリップボードにコピーしました');
              },
              icon: Icon(Icons.copy_rounded, color: themeColors.textColor),
              label: Text(
                '観戦URLをコピー',
                style: TextStyle(
                  color: themeColors.textColor,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                side: BorderSide(color: themeColors.separatorColor),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.medium,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }
}
