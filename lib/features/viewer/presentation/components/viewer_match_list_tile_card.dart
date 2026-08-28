import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_card_note_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_players_score_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_team_header_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/shared/presentation/utils/match_calculator_helper.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 観客画面専用の試合カードウィジェット（閲覧専用・Undoリアクティブ即時同期保証）
class ViewerMatchListTileCard extends ConsumerWidget {
  final MatchModel initialMatch;

  const ViewerMatchListTileCard({super.key, required this.initialMatch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🛡️ 観客席スマホのElementキャッシュをぶち破り、本部が Undo 実行した瞬間に0ミリ秒即時リビルド
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

    final MatchModel match = maybeMatch ?? initialMatch;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFinished = match.status == 'finished' || match.status == 'approved';
    final isPlaying = match.status == 'in_progress';
    final bool isIndividual =
        !match.isKachinuki &&
        (match.matchType == '個人戦' || match.matchType == '選手');

    String displayNote = match.note;
    if (!isIndividual &&
        match.groupName != null &&
        match.groupName!.isNotEmpty) {
      final regExp = RegExp(r'\[.*?\]');
      final tagMatches = regExp.allMatches(match.note);
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
        ? context.appColors.subTextColor
        : context.appColors.textColor;
    final Color noteC = isFinished
        ? (isDark ? const Color(0xFFFFFFFF) : context.appColors.subTextColor)
        : context.appColors.subTextColor;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.modernValue,
        vertical: AppSpacing.subValue,
      ),
      decoration: BoxDecoration(
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
        color: bg,
        borderRadius: AppRadius.medium,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.modernValue,
            vertical: AppSpacing.subValue,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔼 【1行目】: コントロール・ステータスライン（コントロール右寄せ）
              Row(
                children: [
                  const Spacer(),
                  // 観客専用スコア詳細ボタン
                  if ((isIndividual ||
                          match.note.contains('[順位決定戦]') ||
                          match.matchType == '代表戦') &&
                      match.groupName != null &&
                      match.groupName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: SizedBox(
                        height: 26,
                        child: OutlinedButton(
                          onPressed: () {
                            final encodedGroupName = Uri.encodeComponent(
                              match.groupName ?? '',
                            );
                            context.push('/viewer-team/$encodedGroupName');
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            side: BorderSide(
                              color: textC.withValues(alpha: 0.2),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.sub,
                            ),
                          ),
                          child: Text(
                            'スコア',
                            style: TextStyle(
                              fontSize: AppFontSize.badge,
                              fontWeight: AppFontWeight.bold,
                              color: textC,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // 状態バナー
                  MatchStatusBadge(
                    isPlaying: isPlaying,
                    isFinished: isFinished,
                    isDark: isDark,
                  ),
                ],
              ),
              MatchCardNoteRow(
                displayNote: displayNote,
                matchType: match.matchType,
                noteColor: noteC,
              ),
              const SizedBox(height: 10),
              // 🔽 【2行目〜3行目】: 掲示板式リアルタイムスコア＆対戦ライン
              Builder(
                builder: (context) {
                  final ownTeams =
                      ref.watch(customTeamNamesProvider).value ?? [];

                  String getTeamPart(String raw) =>
                      raw.contains(':') ? raw.split(':').first.trim() : '';
                  String getNamePart(String raw) => raw.contains(':')
                      ? raw.split(':').last.trim()
                      : raw.trim();

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
                  final ruleTeam = match.rule?.teamName.trim();
                  final isRedOwn =
                      (rTeam.isNotEmpty && ownTeams.contains(rTeam)) ||
                      match.redName.contains('自チーム') ||
                      (ruleTeam != null &&
                          ruleTeam.isNotEmpty &&
                          rTeam == ruleTeam);
                  final isWhiteOwn =
                      (wTeam.isNotEmpty && ownTeams.contains(wTeam)) ||
                      match.whiteName.contains('自チーム') ||
                      (ruleTeam != null &&
                          ruleTeam.isNotEmpty &&
                          wTeam == ruleTeam);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🏢 【2行目】: 左右チーム名独立表示ライン
                      MatchTeamHeaderRow(
                        redTeam: rTeam,
                        whiteTeam: wTeam,
                        isRedOwn: isRedOwn,
                        isWhiteOwn: isWhiteOwn,
                        textColor: context.appColors.subTextColor,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // 🥋 【3行目】: 選手名＆真実の中央時系列スコア
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
          onTap: () => context.push('/viewer/${match.id}'),
        ),
      ),
    );
  }
}
