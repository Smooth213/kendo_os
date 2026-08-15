import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 試合終了後のアクション選択ダイアログ（純粋UIコンポーネント）
class MatchFinishedNavigationDialog extends StatelessWidget {
  final bool isRenseikai;
  final String? nextMatchId;
  final String? nextMatchType;
  final String? tournamentId;
  final bool hasGroupName;
  final bool isKachinuki;
  final bool isDark;
  final VoidCallback? onAddNextRenseikaiMatch;
  final VoidCallback? onGoToNextMatch;
  final VoidCallback onGoHome;
  final VoidCallback? onShowScoreboard;

  const MatchFinishedNavigationDialog({
    super.key,
    required this.isRenseikai,
    this.nextMatchId,
    this.nextMatchType,
    this.tournamentId,
    required this.hasGroupName,
    required this.isKachinuki,
    required this.isDark,
    this.onAddNextRenseikaiMatch,
    this.onGoToNextMatch,
    required this.onGoHome,
    this.onShowScoreboard,
  });

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: '対戦終了',
      content: const Text('対戦がすべて終了しました。\n次のアクションを選択してください。'),
      actions: [
        // ★ 錬成会・申し合わせ時の「次の対戦を設定」ボタン
        if (isRenseikai && onAddNextRenseikaiMatch != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddNextRenseikaiMatch,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(
                '⚔️ 次の申し合わせ・錬成試合を追加設定',
                style: TextStyle(fontWeight: AppFontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppKendoColors.ipponGold,
                foregroundColor: AppKendoColors.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        // 次の試合へ進むボタン
        if (nextMatchId != null && onGoToNextMatch != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onGoToNextMatch,
              icon: const Icon(Icons.play_arrow),
              label: Text(
                '次の試合へ進む (${nextMatchType ?? ""})',
                style: const TextStyle(fontWeight: AppFontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appColors.primaryAccent,
                foregroundColor: AppKendoColors.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        // ホームへ戻るボタン
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onGoHome,
            icon: const Icon(Icons.home),
            label: Text(
              (tournamentId != null && tournamentId!.startsWith('bunaiksen_'))
                  ? '部内戦ホームに戻る'
                  : '大会ホームへ戻る',
              style: const TextStyle(fontWeight: AppFontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              side: BorderSide(
                color: isDark
                    ? context.appColors.subTextColor
                    : const Color(0x8A000000),
              ),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
            ),
          ),
        ),
        // スコアボード確認ボタン
        if (hasGroupName && onShowScoreboard != null) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onShowScoreboard,
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text(
                'スコアボードを確認する',
                style: TextStyle(fontWeight: AppFontWeight.bold),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
