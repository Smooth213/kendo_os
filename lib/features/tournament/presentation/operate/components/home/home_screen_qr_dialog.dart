import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/widgets/qr_share_dialog.dart';

/// 大会観戦リンク共有QRコードダイアログ（純粋UIコンポーネント）
class HomeScreenQrDialog extends StatelessWidget {
  final String shareUrl;
  final VoidCallback? onClose;

  const HomeScreenQrDialog({super.key, required this.shareUrl, this.onClose});

  @override
  Widget build(BuildContext context) {
    return QrShareDialog(
      title: '大会観戦リンク',
      themeColor: AppKendoColors.teal,
      description: '離れた場所にいる保護者や仲間も、\n試合状況をリアルタイムで安心して見守れます。',
      shareUrl: shareUrl,
      shareText:
          '【剣道リアルタイムViewer共有】このリンクから今日の試合結果・スコアをリアルタイムにその場で観戦・確認できます！\n'
          'アプリ名: 剣道リアルタイムViewer共有＋スコア記録 (kendo_os)\n'
          'リンク: $shareUrl',
      shareButtonLabel: 'LINEやSNSでURLを送る',
      copySuccessMessage: '観戦用URLをクリップボードにコピーしました',
      onClose: onClose,
    );
  }
}
