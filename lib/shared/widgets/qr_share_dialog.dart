import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// 🥋 統一QRコード共有ダイアログ
///
/// アプリ内のすべてのQRコード表示ダイアログ（大会観戦リンク、部内戦観戦リンク、Webアプリリンク等）で
/// 一貫したプレミアムなデザインと使い心地を提供します。
class QrShareDialog extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final Color themeColor;
  final String description;
  final String shareUrl;
  final String shareText;
  final String? shareSubject;
  final String? subtitleBadge;
  final String shareButtonLabel;
  final String copySuccessMessage;
  final VoidCallback? onClose;

  const QrShareDialog({
    super.key,
    required this.title,
    this.titleIcon = Icons.qr_code_2_rounded,
    this.themeColor = AppKendoColors.teal,
    required this.description,
    required this.shareUrl,
    required this.shareText,
    this.shareSubject,
    this.subtitleBadge,
    this.shareButtonLabel = 'LINEやSNSでURLを送る',
    this.copySuccessMessage = 'URLをクリップボードにコピーしました',
    this.onClose,
  });

  static void show(
    BuildContext context, {
    required String title,
    IconData titleIcon = Icons.qr_code_2_rounded,
    Color themeColor = AppKendoColors.teal,
    required String description,
    required String shareUrl,
    required String shareText,
    String? shareSubject,
    String? subtitleBadge,
    String shareButtonLabel = 'LINEやSNSでURLを送る',
    String copySuccessMessage = 'URLをクリップボードにコピーしました',
    VoidCallback? onClose,
  }) {
    showAppDialog(
      context: context,
      builder: (ctx) => QrShareDialog(
        title: title,
        titleIcon: titleIcon,
        themeColor: themeColor,
        description: description,
        shareUrl: shareUrl,
        shareText: shareText,
        shareSubject: shareSubject,
        subtitleBadge: subtitleBadge,
        shareButtonLabel: shareButtonLabel,
        copySuccessMessage: copySuccessMessage,
        onClose: onClose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return AppDialog(
      title: title,
      titleIcon: titleIcon,
      iconColor: themeColor,
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 説明テキスト
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  color: themeColors.subTextColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // QRコードカード
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppKendoColors.pureWhite,
                    borderRadius: AppRadius.large,
                    boxShadow: [
                      BoxShadow(
                        color: AppKendoColors.pureBlack.withValues(alpha: 0.08),
                        blurRadius: 12,
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
                        size: 180.0,
                        backgroundColor: AppKendoColors.pureWhite,
                      ),
                      if (subtitleBadge != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitleBadge!,
                          style: const TextStyle(
                            fontSize: AppFontSize.badge,
                            color: AppKendoColors.grey,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // URL表示 ＆ コピーフィールド
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
                    Icon(Icons.link, size: 18, color: themeColor),
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
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'URLをコピー',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () async {
                        AppHaptics.success();
                        await Clipboard.setData(ClipboardData(text: shareUrl));
                        if (context.mounted) {
                          AppSnackBar.showSuccess(context, copySuccessMessage);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // シェアボタン
              ElevatedButton.icon(
                onPressed: () {
                  AppHaptics.medium();
                  SharePlus.instance.share(
                    ShareParams(text: shareText, subject: shareSubject),
                  );
                },
                icon: const Icon(
                  Icons.ios_share,
                  size: 18,
                  color: AppKendoColors.pureWhite,
                ),
                label: Text(
                  shareButtonLabel,
                  style: const TextStyle(
                    fontWeight: AppFontWeight.bold,
                    color: AppKendoColors.pureWhite,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.medium,
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: onClose ?? () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
