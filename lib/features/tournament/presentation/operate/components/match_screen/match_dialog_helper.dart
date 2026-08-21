import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_finished_navigation_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_hantei_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_player_name_edit_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_representative_modal_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_snapshot_history_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/renseikai_add_next_match_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 試合画面の各種モーダル・ダイアログ表示ヘルパー
class MatchDialogHelper {
  static void showSnapshotDialog(
    BuildContext context,
    WidgetRef ref,
    MatchModel match,
    List<ScoreEvent> validEvents,
    bool isDark,
  ) {
    showAppDialog(
      context: context,
      builder: (ctx) => MatchSnapshotHistoryDialog(
        validEvents: validEvents,
        isDark: isDark,
        onSelectRewind: (targetVersion, eventIndex) async {
          await ref.read(matchCommandProvider).undoLastEvent(match.id);
          if (context.mounted) {
            Navigator.pop(ctx);
          }
        },
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  static void showRuleInfoSheet(BuildContext context, MatchModel match) {
    showRuleInfoBottomSheet(context, match);
  }

  static void showNameEditBottomSheet({
    required BuildContext context,
    required MatchModel match,
    required String side,
  }) {
    MatchPlayerNameEditBottomSheet.show(context, match: match, side: side);
  }

  static void showRepresentativeModal({
    required BuildContext context,
    required MatchModel match,
    required String rTeam,
    required String wTeam,
    required List<String> redPlayers,
    required List<String> whitePlayers,
  }) {
    MatchRepresentativeModalBottomSheet.show(
      context,
      match: match,
      rTeam: rTeam,
      wTeam: wTeam,
      redPlayers: redPlayers,
      whitePlayers: whitePlayers,
    );
  }

  static void showNextMatchDialog(BuildContext context, MatchModel match) {
    RenseikaiAddNextMatchBottomSheet.show(context, currentMatch: match);
  }

  static Future<bool> showConfirmDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    final result = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: title,
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static void showMatchFinishedDialog({
    required BuildContext context,
    required MatchModel match,
    required MatchModel? nextMatch,
    required List<MatchModel> teamMatches,
    required bool isDark,
  }) {
    final hasGroupName = match.groupName != null && match.groupName!.isNotEmpty;
    final isKachinuki = match.isKachinuki;
    final isRenseikai =
        (match.rule?.isRenseikai ?? false) ||
        match.matchType == '錬成会' ||
        match.matchScene == 'renseikai' ||
        match.matchScene == 'moushiawase';

    showAppDialog(
      context: context,
      builder: (ctx) => MatchFinishedNavigationDialog(
        isRenseikai: isRenseikai,
        nextMatchId: nextMatch?.id,
        nextMatchType: nextMatch?.matchType,
        tournamentId: match.tournamentId,
        hasGroupName: hasGroupName,
        isKachinuki: isKachinuki,
        isDark: isDark,
        onAddNextRenseikaiMatch: () {
          Navigator.pop(ctx);
          RenseikaiAddNextMatchBottomSheet.show(context, currentMatch: match);
        },
        onGoToNextMatch: nextMatch != null
            ? () {
                Navigator.pop(ctx);
                context.pushReplacement('/match/${nextMatch.id}');
              }
            : null,
        onGoHome: () {
          Navigator.pop(ctx);
          if (match.tournamentId != null &&
              match.tournamentId!.startsWith('bunaiksen_')) {
            context.go('/bunaiksen-home');
          } else {
            context.go('/home/${match.tournamentId}');
          }
        },
        onShowScoreboard: hasGroupName
            ? () {
                Navigator.pop(ctx);
                if (isKachinuki) {
                  context.push('/kachinuki-scoreboard/${match.groupName}');
                } else {
                  context.push('/team-scoreboard/${match.groupName}');
                }
              }
            : null,
      ),
    );
  }

  static Future<String?> showHanteiDialog({
    required BuildContext context,
    required MatchModel match,
    required bool isDark,
  }) {
    return showAppDialog<String>(
      context: context,
      builder: (ctx) => MatchHanteiDialog(
        redName: match.redName,
        whiteName: match.whiteName,
        isDark: isDark,
        onSelected: (result) => Navigator.pop(ctx, result),
      ),
    );
  }
}
