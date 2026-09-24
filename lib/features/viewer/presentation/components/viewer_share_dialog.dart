import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/qr_share_dialog.dart';

/// 🥋 観客席用 大会共有リンクQRダイアログ
class ViewerShareDialog extends StatelessWidget {
  final String tournamentId;
  final String dojoId;

  const ViewerShareDialog({
    super.key,
    required this.tournamentId,
    required this.dojoId,
  });

  static void show(
    BuildContext context, {
    required String tournamentId,
    required String dojoId,
  }) {
    showAppDialog(
      context: context,
      builder: (ctx) =>
          ViewerShareDialog(tournamentId: tournamentId, dojoId: dojoId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isBunaiksen = tournamentId.startsWith('bunaiksen_');
    final String path = isBunaiksen ? 'bunaiksen-viewer-home' : 'viewer-home';
    final safeDojo = dojoId.isNotEmpty ? dojoId : 'default_org';
    final String shareUrl =
        'https://kendo-os-beta.web.app/$path/$tournamentId?role=viewer&dojoId=$safeDojo';

    return QrShareDialog(
      title: isBunaiksen ? '部内戦観戦リンク' : '大会観戦リンク',
      themeColor: AppKendoColors.teal,
      description: 'この大会の全試合・スコアを\n観客用に安全に共有できます。',
      shareUrl: shareUrl,
      subtitleBadge: '大会ID: $tournamentId',
      shareText:
          '【剣道リアルタイムViewer共有】このリンクから今日の試合結果・スコアをリアルタイムにその場で観戦・確認できます！\n'
          'アプリ名: 剣道リアルタイムViewer共有＋スコア記録 (kendo_os)\n'
          'リンク: $shareUrl',
      shareButtonLabel: 'LINEやSNSでURLを送る',
      copySuccessMessage: '観戦用URLをクリップボードにコピーしました',
    );
  }
}
