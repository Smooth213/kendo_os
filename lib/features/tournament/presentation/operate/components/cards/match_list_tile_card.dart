import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_card_action_buttons.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_card_header_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_card_note_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_players_score_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_team_header_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart'
    show customTeamNamesProvider;
import 'package:kendo_os/shared/presentation/utils/match_calculator_helper.dart';

import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 試合一覧の1試合分を表示するカードウィジェット
class MatchListTileCard extends ConsumerWidget {
  final MatchModel initialMatch;
  final bool isDeletable;
  final void Function(BuildContext context, WidgetRef ref, MatchModel match)?
  onSummaryPressed;

  const MatchListTileCard({
    super.key,
    required this.initialMatch,
    this.isDeletable = true,
    this.onSummaryPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🛡️ 自身の内部でグローバルな変化を強固に常時 watch 監視
    MatchModel? maybeMatch = ref.watch(
      matchListProvider.select(
        (list) => list.where((m) => m.id == initialMatch.id).firstOrNull,
      ),
    );

    if (maybeMatch == null &&
        kIsWeb &&
        (initialMatch.tournamentId != null &&
            initialMatch.tournamentId!.isNotEmpty)) {
      maybeMatch = ref.watch(
        matchListByTournamentProvider(initialMatch.tournamentId!).select(
          (res) => res.value?.where((m) => m.id == initialMatch.id).firstOrNull,
        ),
      );
    }

    final match = maybeMatch ?? initialMatch;
    final permissions = ref.watch(permissionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFinished = match.status == 'finished' || match.status == 'approved';
    final isPlaying = match.status == 'in_progress';
    final bool isIndividual =
        !match.isKachinuki &&
        (match.matchType == '個人戦' || match.matchType == '選手');

    String displayNote = match.note;
    if (displayNote.contains('[SUMMARY]')) {
      displayNote = displayNote.replaceAll('[SUMMARY]', '').trim();
    }

    if (!isIndividual &&
        match.groupName != null &&
        match.groupName!.isNotEmpty) {
      final regExp = RegExp(r'\[.*?\]');
      final tagMatches = regExp.allMatches(displayNote);
      if (tagMatches.isNotEmpty) {
        displayNote = tagMatches.map((m) => m.group(0)).join(' ');
      } else {
        displayNote = '';
      }
    }

    final Color bg = isFinished
        ? (isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7))
        : (isDark ? const Color(0xFF1E1E20) : const Color(0xFFFFFFFF));
    final Color textC = isFinished
        ? (context.appColors.subTextColor)
        : (context.appColors.textColor);
    final Color noteC = context.appColors.subTextColor;

    final tile = Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.modernValue,
        vertical: AppSpacing.subValue,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0x33000000),
          width: 1.2,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: AppKendoColors.blue.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          key: Key('viewer_match_card_${match.id}'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.modernValue,
            vertical: AppSpacing.subValue,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔼 【1行目】: 運営ステータス＆ボタン一元集約（コントロール右寄せ）
              MatchCardHeaderRow(
                actionButtons: MatchCardActionButtons(
                  showSummaryButton:
                      !permissions.isReadOnly &&
                      !isFinished &&
                      !isPlaying &&
                      !(ref.watch(customTeamNamesProvider).value ?? [])
                          .contains(match.redName.split(':').first.trim()) &&
                      !match.redName.contains('自チーム') &&
                      !(ref.watch(customTeamNamesProvider).value ?? [])
                          .contains(match.whiteName.split(':').first.trim()) &&
                      !match.whiteName.contains('自チーム') &&
                      isIndividual,
                  showInfoButton: isIndividual,
                  showScoreButton:
                      isIndividual ||
                      match.note.contains('[順位決定戦]') ||
                      match.matchType == '代表戦',
                  textColor: textC,
                  subTextColor: context.appColors.subTextColor,
                  onSummaryPressed: () {
                    if (onSummaryPressed != null) {
                      onSummaryPressed!(context, ref, match);
                    }
                  },
                  onInfoPressed: () => showRuleInfoBottomSheet(context, match),
                  onScorePressed: () {
                    final target =
                        (match.groupName != null && match.groupName!.isNotEmpty)
                        ? match.groupName!
                        : match.id;
                    final encodedTarget = Uri.encodeComponent(target);
                    final tId = match.tournamentId ?? '';
                    context.push(
                      '/team-scoreboard/$encodedTarget?tournamentId=$tId',
                    );
                  },
                ),
                statusBadge: MatchStatusBadge(
                  isPlaying: isPlaying,
                  isFinished: isFinished,
                  isDark: isDark,
                ),
              ),
              MatchCardNoteRow(
                displayNote: displayNote,
                matchType: match.matchType,
                noteColor: noteC,
              ),
              const SizedBox(height: 10),
              // 🔽 【要塞型・全3行レイアウト大刷新】: チーム名を選手名の上に配置し、スコア圧迫による文字切れを100%防止
              Builder(
                builder: (context) {
                  final ownTeams =
                      ref.watch(customTeamNamesProvider).value ?? [];

                  String getTeamPart(String raw) {
                    if (raw.contains(':')) return raw.split(':').first.trim();
                    if (!isIndividual) {
                      return raw.trim();
                    }
                    return '';
                  }

                  String getNamePart(String raw) {
                    if (raw.contains(':')) return raw.split(':').last.trim();
                    if (!isIndividual) {
                      return match.matchType;
                    }
                    return raw.trim();
                  }

                  final rTeam = getTeamPart(match.redName);
                  final rName = getNamePart(match.redName);
                  final wTeam = getTeamPart(match.whiteName);
                  final wName = getNamePart(match.whiteName);

                  final ptsMap = MatchCalculatorHelper.extractPointsFromModel(
                    match,
                  );
                  final redPoints = ptsMap['red'] ?? [];
                  final whitePoints = ptsMap['white'] ?? [];
                  final bool isDraw =
                      isFinished && match.redScore == match.whiteScore;

                  final isRedOwn =
                      ownTeams.contains(rTeam) ||
                      match.redName.contains('自チーム');
                  final isWhiteOwn =
                      ownTeams.contains(wTeam) ||
                      match.whiteName.contains('自チーム');

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🏢 【2行目】: 左右チーム名独立表示ライン
                      MatchTeamHeaderRow(
                        redTeam: rTeam,
                        whiteTeam: wTeam,
                        textColor: isDark
                            ? const Color(0xFFFFFFFF)
                            : const Color(0x8A000000),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // 🥋 【3行目】: ピュア選手名＆中央掲示板式リアルタイムスコアライン
                      MatchPlayersScoreRow(
                        redName: rName,
                        whiteName: wName,
                        isRedOwn: isRedOwn,
                        isWhiteOwn: isWhiteOwn,
                        redPoints: redPoints,
                        whitePoints: whitePoints,
                        isDraw: isDraw,
                        textColor: context.appColors.textColor,
                        subTextColor: context.appColors.subTextColor,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          onTap: () {
            final tId = match.tournamentId ?? '';
            if (permissions.isReadOnly) {
              context.push('/viewer/${match.id}?tournamentId=$tId');
            } else {
              context.push('/match/${match.id}?tournamentId=$tId');
            }
          },
        ),
      ),
    );

    final canEdit = !permissions.isReadOnly;
    final canDelete =
        (permissions.canDeleteData || permissions.canManageTournament) &&
        isDeletable;

    if (!canEdit && !canDelete) return tile;

    return Slidable(
      key: ValueKey(match.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (canEdit)
            SlidableAction(
              onPressed: (context) {
                showAppBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) {
                    return MatchEditSheet(
                      matches: [match],
                      tournamentId: match.tournamentId,
                      themeColors: AppThemeColors.ofMode(
                        isDark: Theme.of(context).brightness == Brightness.dark,
                        mode: 'operate',
                      ),
                    );
                  },
                );
              },
              backgroundColor: AppKendoColors.blueAccent,
              foregroundColor: AppKendoColors.pureWhite,
              icon: Icons.edit,
              label: '編集',
            ),
          if (canDelete)
            SlidableAction(
              onPressed: (context) async {
                final confirm = await showAppDialog<bool>(
                  context: context,
                  builder: (ctx) => AppDialog(
                    backgroundColor: isDark
                        ? const Color(0xFF1C1C1E)
                        : context.appColors.inputBackground,
                    titleWidget: Text(
                      '試合の削除',
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        color: context.appColors.textColor,
                      ),
                    ),
                    content: Text(
                      '削除しますか？\n(取り消せません)',
                      style: TextStyle(color: context.appColors.textColor),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          '削除',
                          style: TextStyle(
                            color: AppKendoColors.red,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(matchCommandProvider).deleteMatch(match.id);
                }
              },
              backgroundColor: AppKendoColors.redAccent,
              foregroundColor: AppKendoColors.pureWhite,
              icon: Icons.delete,
              label: '削除',
            ),
        ],
      ),
      child: tile,
    );
  }
}
