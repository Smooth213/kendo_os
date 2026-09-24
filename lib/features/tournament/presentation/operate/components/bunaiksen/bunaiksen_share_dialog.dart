import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/qr_share_dialog.dart';

/// 🥋 部内戦 観戦リンク共有ダイアログ
class BunaiksenShareDialog extends StatelessWidget {
  final String tournamentId;
  final String dateDisplay;
  final String dojoId;

  const BunaiksenShareDialog({
    super.key,
    required this.tournamentId,
    required this.dateDisplay,
    required this.dojoId,
  });

  static void show(
    BuildContext context, {
    required String tournamentId,
    required String dateDisplay,
    required String dojoId,
  }) {
    showAppDialog(
      context: context,
      builder: (ctx) => BunaiksenShareDialog(
        tournamentId: tournamentId,
        dateDisplay: dateDisplay,
        dojoId: dojoId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeDojo = dojoId.isNotEmpty ? dojoId : 'default_org';
    final String shareUrl =
        'https://kendo-os-beta.web.app/bunaiksen-viewer-home/$tournamentId?role=viewer&dojoId=$safeDojo';

    return QrShareDialog(
      title: '$dateDisplay 観戦リンク',
      themeColor: AppKendoColors.teal,
      description: 'この部内戦の全試合・スコアを\n観客用に安全に共有できます。',
      shareUrl: shareUrl,
      subtitleBadge: '部内戦ID: $tournamentId',
      shareText: '【部内戦 リアルタイム速報】\n$shareUrl\nスマホやタブレットでスコアをLIVE観戦できます。',
      shareSubject: '部内戦リアルタイム速報リンク',
      shareButtonLabel: 'LINEやSNSでURLを送る',
      copySuccessMessage: '観戦用URLをクリップボードにコピーしました',
    );
  }
}
