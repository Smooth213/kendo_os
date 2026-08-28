import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_dialog_helper.dart';
import 'package:kendo_os/shared/presentation/screens/embedded_manual_screen.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 試合画面のヘッダータイトルWidget
class MatchHeaderTitle extends StatelessWidget {
  final MatchModel match;

  const MatchHeaderTitle({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final titleText = (match.category != null && match.category!.isNotEmpty)
        ? '${match.category} - ${match.matchType}'
        : match.matchType;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titleText,
            style: const TextStyle(
              fontSize: AppFontSize.bodyMedium,
              fontWeight: AppFontWeight.bold,
              color: AppKendoColors.pureWhite,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${match.redName} vs ${match.whiteName}',
            style: TextStyle(
              fontSize: AppFontSize.small,
              color: AppKendoColors.pureWhite.withValues(alpha: 0.85),
              fontWeight: AppFontWeight.medium,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 試合画面のヘッダーアクションWidgetリスト（iOS More メニュー集約版）
class MatchHeaderActions extends ConsumerWidget {
  final MatchModel match;

  const MatchHeaderActions({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_horiz_rounded,
        color: AppKendoColors.pureWhite,
        size: 26,
      ),
      tooltip: 'その他の操作・設定',
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
      color: themeColors.cardBackground,
      elevation: 6,
      onOpened: () => AppHaptics.selection(),
      onSelected: (value) async {
        AppHaptics.selection();
        switch (value) {
          case 'swap':
            final confirmed = await MatchDialogHelper.showConfirmDialog(
              context,
              '取得スコアの左右入れ替え',
              '赤と白の取得本数・打突技・反則履歴を左右入れ替えますか？\n（選手名はそのまま維持され、スコアの押し間違いを修正します）',
            );
            if (confirmed) {
              await ref.read(matchCommandProvider).swapRedAndWhite(match.id);
            }
            break;
          case 'retirement':
            MatchDialogHelper.showRetirementDialog(
              context: context,
              match: match,
              currentUserId: null,
              isDark: isDark,
            );
            break;
          case 'manual':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EmbeddedManualScreen(
                  initialFilePath: 'docs/manuals/quickstart/operator_1pager.md',
                ),
              ),
            );
            break;
          case 'home':
            if (match.tournamentId != null &&
                match.tournamentId!.startsWith('bunaiksen_')) {
              context.go('/bunaiksen-home');
            } else {
              context.go('/home/${match.tournamentId}');
            }
            break;
          case 'settings':
            context.push('/settings');
            break;
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          value: 'swap',
          child: Row(
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                color: themeColors.textColor,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'スコア左右入れ替え',
                style: TextStyle(
                  color: themeColors.textColor,
                  fontSize: AppFontSize.body,
                ),
              ),
            ],
          ),
        ),
        if (match.status != 'finished' && match.status != 'approved')
          PopupMenuItem<String>(
            value: 'retirement',
            child: Row(
              children: [
                Icon(
                  Icons.personal_injury_outlined,
                  color: themeColors.errorColor,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '途中棄権の記録',
                  style: TextStyle(
                    color: themeColors.errorColor,
                    fontSize: AppFontSize.body,
                  ),
                ),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'manual',
          child: Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                color: themeColors.textColor,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'マニュアル・ヘルプ',
                style: TextStyle(
                  color: themeColors.textColor,
                  fontSize: AppFontSize.body,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'home',
          child: Row(
            children: [
              Icon(
                Icons.view_list_rounded,
                color: themeColors.textColor,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '試合一覧へ戻る',
                style: TextStyle(
                  color: themeColors.textColor,
                  fontSize: AppFontSize.body,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: themeColors.textColor,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'アプリ設定',
                style: TextStyle(
                  color: themeColors.textColor,
                  fontSize: AppFontSize.body,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
