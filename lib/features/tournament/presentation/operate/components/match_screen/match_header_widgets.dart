import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_dialog_helper.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';

/// 試合画面のヘッダータイトルWidget
class MatchHeaderTitle extends StatelessWidget {
  final MatchModel match;

  const MatchHeaderTitle({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final titleText = (match.category != null && match.category!.isNotEmpty)
        ? '${match.category} - ${match.matchType}'
        : match.matchType;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titleText,
          style: const TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: AppFontWeight.bold,
            color: AppKendoColors.pureWhite,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${match.redName} vs ${match.whiteName}',
          style: TextStyle(
            fontSize: AppFontSize.small,
            color: AppKendoColors.pureWhite.withValues(alpha: 0.7),
            fontWeight: AppFontWeight.medium,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// 試合画面のヘッダーアクションWidgetリスト
class MatchHeaderActions extends ConsumerWidget {
  final MatchModel match;

  const MatchHeaderActions({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(
            Icons.swap_horiz_rounded,
            color: AppKendoColors.pureWhite,
          ),
          tooltip: '赤白スコア・取得技の左右入れ替え（誤入力救済）',
          onPressed: () async {
            final confirmed = await MatchDialogHelper.showConfirmDialog(
              context,
              '取得スコアの左右入れ替え',
              '赤と白の取得本数・打突技・反則履歴を左右入れ替えますか？\n（選手名はそのまま維持され、スコアの押し間違いを修正します）',
            );
            if (confirmed) {
              await ref.read(matchCommandProvider).swapRedAndWhite(match.id);
            }
          },
        ),
        const ManualHelpButton(
          manualPath: 'docs/manuals/quickstart/operator_1pager.md',
          color: AppKendoColors.pureWhite,
        ),
        IconButton(
          icon: const Icon(
            Icons.view_list_rounded,
            color: AppKendoColors.pureWhite,
          ),
          tooltip: '大会ホーム（試合一覧）へ戻る',
          onPressed: () {
            if (match.tournamentId != null &&
                match.tournamentId!.startsWith('bunaiksen_')) {
              context.go('/bunaiksen-home');
            } else {
              context.go('/home/${match.tournamentId}');
            }
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.settings_outlined,
            color: AppKendoColors.pureWhite,
          ),
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }
}
