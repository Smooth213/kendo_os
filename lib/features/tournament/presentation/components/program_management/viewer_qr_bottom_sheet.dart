import 'dart:async';
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
class ViewerQrBottomSheet extends ConsumerStatefulWidget {
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
  ConsumerState<ViewerQrBottomSheet> createState() =>
      _ViewerQrBottomSheetState();
}

class _ViewerQrBottomSheetState extends ConsumerState<ViewerQrBottomSheet> {
  bool _isCopied = false;
  Timer? _copyResetTimer;

  @override
  void dispose() {
    _copyResetTimer?.cancel();
    super.dispose();
  }

  void _copyUrl(String shareUrl) {
    AppHaptics.success();
    Clipboard.setData(ClipboardData(text: shareUrl));
    _copyResetTimer?.cancel();
    setState(() => _isCopied = true);

    _copyResetTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });

    AppSnackBar.showSuccess(context, '観戦用URLをクリップボードにコピーしました');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final syncContext = ref.watch(currentSyncContextProvider);
    final dojoId = syncContext.organizationId;
    final isBunaiksen = widget.tournamentId.startsWith('bunaiksen_');
    final accentColor = isBunaiksen
        ? (isDark ? const Color(0xFFC084FC) : AppKendoColors.purple)
        : (isDark ? const Color(0xFF2DD4BF) : AppKendoColors.teal);

    final path = isBunaiksen ? 'bunaiksen-viewer-home' : 'viewer-home';
    final shareUrl =
        'https://kendo-os-beta.web.app/$path/${widget.tournamentId}?role=viewer&dojoId=$dojoId';

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
              title: isBunaiksen ? '部内戦 観戦用QR ＆ 速報共有' : '観戦用QRコード ＆ 速報共有',
              icon: Icons.qr_code_2_rounded,
              iconColor: accentColor,
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
                  Icon(
                    Icons.remove_red_eye_rounded,
                    color: accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      isBunaiksen
                          ? 'カメラで読み取ると、ログイン不要・編集権限なしの「部内戦 観戦専用ビュアー」が直接開きます。'
                          : 'カメラで読み取ると、ログイン不要・編集権限なしの「観戦専用ビュアー」が直接開きます。',
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
                      isBunaiksen
                          ? '部内戦ID: ${widget.tournamentId}'
                          : '大会ID: ${widget.tournamentId}',
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
            const SizedBox(height: AppSpacing.md),

            // URL表示 ＆ コピーフィールド（ダイアログと統一）
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: themeColors.inputBackground,
                borderRadius: AppRadius.medium,
                border: Border.all(
                  color: themeColors.separatorColor.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, size: 18, color: accentColor),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: SelectableText(
                      shareUrl,
                      style: TextStyle(
                        fontSize: AppFontSize.bodySmall,
                        fontWeight: AppFontWeight.semiBold,
                        color: themeColors.textColor,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isCopied
                          ? Icons.check_circle_rounded
                          : Icons.copy_rounded,
                      size: 18,
                      color: _isCopied ? accentColor : themeColors.textColor,
                    ),
                    tooltip: 'URLをコピー',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () => _copyUrl(shareUrl),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ワンタップ共有ボタン（LINE・SNS）
            ElevatedButton.icon(
              onPressed: () {
                AppHaptics.medium();
                SharePlus.instance.share(
                  ShareParams(
                    text: isBunaiksen
                        ? '【部内戦 リアルタイム速報】\n$shareUrl\nスマホやタブレットでスコアをLIVE観戦できます。'
                        : '【剣道リアルタイム観戦】今日の試合結果・速報をその場でリアルタイムに観戦できます！\n'
                              '▼ 観戦専用URL:\n$shareUrl',
                  ),
                );
              },
              icon: const Icon(
                Icons.ios_share,
                color: AppKendoColors.pureWhite,
                size: 18,
              ),
              label: const Text(
                'LINEやSNSで観戦URLを送る',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  color: AppKendoColors.pureWhite,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.medium,
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // 📋 コピー完了トースト通知バッジ（アニメーション表示）
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                );
              },
              child: _isCopied
                  ? Container(
                      key: const ValueKey('copied_toast_badge'),
                      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: AppRadius.medium,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppKendoColors.pureWhite,
                            size: 18,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            '観戦用URLをコピーしました！',
                            style: TextStyle(
                              color: AppKendoColors.pureWhite,
                              fontSize: AppFontSize.bodySmall,
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('copied_toast_none')),
            ),

            // URLコピーボタン
            OutlinedButton.icon(
              onPressed: () => _copyUrl(shareUrl),
              icon: Icon(
                _isCopied ? Icons.check_circle_rounded : Icons.copy_rounded,
                color: _isCopied ? accentColor : themeColors.textColor,
              ),
              label: Text(
                _isCopied ? 'コピーしました！' : '観戦URLをコピー',
                style: TextStyle(
                  color: _isCopied ? accentColor : themeColors.textColor,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                backgroundColor: _isCopied
                    ? accentColor.withValues(alpha: 0.12)
                    : null,
                side: BorderSide(
                  color: _isCopied ? accentColor : themeColors.separatorColor,
                  width: _isCopied ? 1.5 : 1.0,
                ),
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
