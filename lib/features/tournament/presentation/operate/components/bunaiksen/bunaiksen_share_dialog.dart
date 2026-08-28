import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

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
    final String shareUrl =
        'https://kendo-os-beta.web.app/bunaiksen-viewer-home/$tournamentId?role=viewer&dojoId=$dojoId';

    return AppDialog(
      title: '$dateDisplay 観戦リンク',
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'この部内戦の全試合・スコアを\n観客用に安全に共有できます。',
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
                  text: '【部内戦 リアルタイム速報】\n$shareUrl\nスマホやタブレットでスコアをLIVE観戦できます。',
                  subject: '部内戦リアルタイム速報リンク',
                ),
              ),
              icon: const Icon(Icons.ios_share, size: 18),
              label: const Text('リンクをコピー・共有'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
