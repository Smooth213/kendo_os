import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/qr_share_dialog.dart';

/// Webアプリ版（アプリ本体）のQRコードダイアログ
class WebAppQrDialog extends StatelessWidget {
  static const String webAppUrl = 'https://kendo-os-beta.web.app';

  const WebAppQrDialog({super.key});

  static void show(BuildContext context) {
    showAppDialog(context: context, builder: (ctx) => const WebAppQrDialog());
  }

  @override
  Widget build(BuildContext context) {
    return QrShareDialog(
      title: 'Webアプリ版（kendo_os）',
      titleIcon: Icons.qr_code_2_rounded,
      themeColor: AppKendoColors.blue,
      description: 'カメラでQRコードを読み取ると、他のスマートフォン・タブレット・PCのブラウザからアプリ本体を開くことができます。',
      shareUrl: webAppUrl,
      shareText:
          '【剣道スコア記録・大会運営 kendo_os】\n'
          'Webアプリ版URL: $webAppUrl\n'
          '（ブラウザからアクセスして操作・ご利用いただけます）',
      shareButtonLabel: 'URLをシェア・共有',
      copySuccessMessage: 'WebアプリのURLをコピーしました',
    );
  }
}
