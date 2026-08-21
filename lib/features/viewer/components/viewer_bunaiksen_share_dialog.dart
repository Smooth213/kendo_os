import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// 部内戦観客用 リンク共有ダイアログ
class ViewerBunaiksenShareDialog {
  static void show(
    BuildContext context,
    WidgetRef ref, {
    required String tournamentId,
    required String dateDisplay,
  }) {
    final dojoId = ref.read(currentDojoIdProvider);
    final String shareUrl =
        'https://kendo-os-beta.web.app/bunaiksen-viewer-home/$tournamentId?role=viewer&dojoId=$dojoId';

    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
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
                    text:
                        '【剣道リアルタイムViewer共有】このリンクから今日の試合結果・スコアをリアルタイムにその場で観戦・確認できます！\n'
                        'アプリ名: 剣道リアルタイムViewer共有＋スコア記録 (kendo_os)\n'
                        'リンク: $shareUrl',
                  ),
                ),
                icon: const Icon(Icons.share),
                label: const Text('LINEやSNSでURLを送る'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF607D8B),
                  foregroundColor: AppKendoColors.pureWhite,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '閉じる',
              style: TextStyle(color: AppKendoColors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
