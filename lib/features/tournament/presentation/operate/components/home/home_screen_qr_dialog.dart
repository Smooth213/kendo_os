import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// 大会観戦リンク共有QRコードダイアログ（純粋UIコンポーネント）
class HomeScreenQrDialog extends StatelessWidget {
  final String shareUrl;
  final VoidCallback? onClose;

  const HomeScreenQrDialog({super.key, required this.shareUrl, this.onClose});

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: '大会観戦リンク',
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '離れた場所にいる保護者や仲間も、\n試合状況をリアルタイムで安心して見守れます。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: AppFontSize.bodySmall),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              color: AppKendoColors.pureWhite,
              child: QrImageView(
                data: shareUrl,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: AppKendoColors.pureWhite,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                  text:
                      '【剣道リアルタイムViewer共有】このリンクから今日の試合結果・スコアをリアルタイムにその場で観戦・確認できます！\n'
                      'アプリ名: 剣道リアルタイムViewer共有＋スコア記録 (kendo_os)\n'
                      'リンク: $shareUrl',
                ),
              ),
              icon: const Icon(Icons.ios_share),
              label: const Text('LINEやSNSでURLを送る'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppKendoColors.indigo,
                foregroundColor: AppKendoColors.pureWhite,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onClose ?? () => Navigator.pop(context),
          child: const Text(
            '閉じる',
            style: TextStyle(color: AppKendoColors.grey),
          ),
        ),
      ],
    );
  }
}
