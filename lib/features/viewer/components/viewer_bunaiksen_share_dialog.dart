import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/widgets/qr_share_dialog.dart';

/// 部内戦観客用 リンク共有ダイアログ
class ViewerBunaiksenShareDialog {
  static void show(
    BuildContext context,
    WidgetRef ref, {
    required String tournamentId,
    required String dateDisplay,
  }) {
    final dojoId = ref.read(currentDojoIdProvider);
    final safeDojo = dojoId.isNotEmpty ? dojoId : 'default_org';
    final String shareUrl =
        'https://kendo-os-beta.web.app/bunaiksen-viewer-home/$tournamentId?role=viewer&dojoId=$safeDojo';

    QrShareDialog.show(
      context,
      title: '$dateDisplay 観戦リンク',
      themeColor: AppKendoColors.teal,
      description: 'この部内戦の全試合・スコアを\n観客用に安全に共有できます。',
      shareUrl: shareUrl,
      subtitleBadge: '部内戦ID: $tournamentId',
      shareText:
          '【剣道リアルタイムViewer共有】このリンクから今日の試合結果・スコアをリアルタイムにその場で観戦・確認できます！\n'
          'アプリ名: 剣道リアルタイムViewer共有＋スコア記録 (kendo_os)\n'
          'リンク: $shareUrl',
      shareButtonLabel: 'LINEやSNSでURLを送る',
      copySuccessMessage: '観戦用URLをクリップボードにコピーしました',
    );
  }
}
