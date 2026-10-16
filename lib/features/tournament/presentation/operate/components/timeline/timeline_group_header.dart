import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/band/presentation/components/band_share_button.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_dialog_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_league_status_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_summary_input_dialog.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_scene_badge.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// タイムライングループカードの1段目〜4段目（ステータス・対戦名・コート情報・アクション操作行）を担当するヘッダーWidget
class TimelineGroupHeader extends ConsumerWidget {
  final List<MatchModel> groupList;
  final String label;
  final bool allFinished;
  final bool hasInProgress;
  final bool isReadOnlyUI;
  final bool canManageTournamentUI;
  final bool isDark;
  final List<String> ownTeams;
  final Color titleColor;

  const TimelineGroupHeader({
    super.key,
    required this.groupList,
    required this.label,
    required this.allFinished,
    required this.hasInProgress,
    required this.isReadOnlyUI,
    required this.canManageTournamentUI,
    required this.isDark,
    required this.ownTeams,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstMatch = groupList.first;
    final rTeam = firstMatch.redName.contains(':')
        ? firstMatch.redName.split(':').first.trim()
        : firstMatch.redName;
    final wTeam = firstMatch.whiteName.contains(':')
        ? firstMatch.whiteName.split(':').first.trim()
        : firstMatch.whiteName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔽 【1段目】: 属性プレフィックス（左） ────── ステータスバッジ＆BANDボタン（右）
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) {
                final scene = KendoSceneHelper.detectScene(firstMatch);
                if (scene == KendoMatchScene.honsen) {
                  return const SizedBox.shrink();
                }
                return KendoSceneBadge(scene: scene);
              },
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                MatchStatusBadge(
                  isPlaying: hasInProgress,
                  isFinished: allFinished,
                  isDark: isDark,
                ),
                if (!label.contains('リーグ戦')) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  BandShareButton(matches: groupList),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),

        // 🔽 【2段目】: 対戦カード名 / リーグ参加チーム名一覧（横幅全開・太字、自チームハイライト）
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            children: [
              Expanded(
                child: label.contains('リーグ戦')
                    ? Builder(
                        builder: (context) {
                          final isIndiv =
                              label.contains('個人戦') || label.contains('選手');
                          final participants = <String>[];
                          for (final m in groupList) {
                            final p1 = isIndiv
                                ? (m.redName.contains(':')
                                      ? m.redName.split(':').last.trim()
                                      : m.redName.trim())
                                : (m.redName.contains(':')
                                      ? m.redName.split(':').first.trim()
                                      : m.redName.trim());
                            final p2 = isIndiv
                                ? (m.whiteName.contains(':')
                                      ? m.whiteName.split(':').last.trim()
                                      : m.whiteName.trim())
                                : (m.whiteName.contains(':')
                                      ? m.whiteName.split(':').first.trim()
                                      : m.whiteName.trim());
                            if (p1.isNotEmpty && !participants.contains(p1)) {
                              participants.add(p1);
                            }
                            if (p2.isNotEmpty && !participants.contains(p2)) {
                              participants.add(p2);
                            }
                          }

                          return _LeagueParticipantsText(
                            participants: participants,
                            ownTeams: ownTeams,
                            ruleTeam: firstMatch.rule?.teamName,
                            isDark: isDark,
                            titleColor: titleColor,
                          );
                        },
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$rTeam vs $wTeam',
                          style: TextStyle(
                            fontSize: AppFontSize.subhead,
                            fontWeight: AppFontWeight.bold,
                            color: titleColor,
                          ),
                          maxLines: 1,
                        ),
                      ),
              ),
            ],
          ),
        ),

        // 🔽 【3段目】: コート情報・リーグ名・メモ
        Builder(
          builder: (context) {
            String noteText = firstMatch.note;
            if (label.contains('リーグ戦')) {
              final clean = firstMatch.note.replaceAll('[リーグ戦]', '').trim();
              final leagueMatch = RegExp(r'([^\s,，、]+リーグ)').firstMatch(clean);
              final courtMatch = RegExp(
                r'(第\d+試合場|第\d+コート|[^\s,，、]+コート|[^\s,，、]+試合場)',
              ).firstMatch(clean);
              if (leagueMatch != null) {
                final leagueName = leagueMatch.group(1)!;
                final courtName = courtMatch?.group(1);
                noteText = courtName != null
                    ? '$courtName · $leagueName'
                    : leagueName;
              } else if (clean.isNotEmpty) {
                noteText = clean;
              }
            }
            if (noteText.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  noteText,
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: context.appColors.subTextColor,
                    fontWeight: AppFontWeight.medium,
                  ),
                  maxLines: 1,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xxs),

        // 🔽 【4段目】: リーグ戦用進行サマリー帯ボックス または アクションボタン行
        if (label.contains('リーグ戦'))
          TimelineLeagueStatusSection(
            groupList: groupList,
            allFinished: allFinished,
            hasInProgress: hasInProgress,
            isDark: isDark,
            ownTeams: ownTeams,
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Row(
              children: [
                if (!allFinished)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: InkWell(
                      onTap: () => showRuleInfoBottomSheet(context, firstMatch),
                      borderRadius: AppRadius.medium,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Icon(
                          Icons.info_outline,
                          color: context.appColors.subTextColor,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                if (!isReadOnlyUI &&
                    !allFinished &&
                    firstMatch.groupName != null &&
                    firstMatch.groupName!.isNotEmpty) ...[
                  SizedBox(
                    height: 26,
                    width: 26,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.swap_vert,
                        size: 18,
                        color: context.appColors.infoColor,
                      ),
                      onPressed: () =>
                          TimelineDialogHelper.showOrderReorderSheet(
                            context,
                            ref,
                            groupList,
                          ),
                      tooltip: 'オーダー編集',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                const Spacer(),
                if (!isReadOnlyUI &&
                    !allFinished &&
                    !label.contains('個人戦') &&
                    !label.contains('勝ち抜き戦') &&
                    !ownTeams.contains(
                      firstMatch.redName.split(':').first.trim(),
                    ) &&
                    !ownTeams.contains(
                      firstMatch.whiteName.split(':').first.trim(),
                    )) ...[
                  SizedBox(
                    height: 26,
                    child: OutlinedButton.icon(
                      onPressed: () => TimelineSummaryInputDialog.show(
                        context,
                        ref,
                        groupList,
                      ),
                      icon: Icon(
                        Icons.flash_on,
                        size: 12,
                        color: context.appColors.warningColor,
                      ),
                      label: Text(
                        '簡易入力',
                        style: TextStyle(
                          fontSize: AppFontSize.nano,
                          fontWeight: AppFontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.subValue,
                        ),
                        side: BorderSide(
                          color: titleColor.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.sub,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                SizedBox(
                  height: 26,
                  child: OutlinedButton(
                    onPressed: () {
                      final target =
                          (firstMatch.groupName != null &&
                              firstMatch.groupName!.isNotEmpty)
                          ? firstMatch.groupName!
                          : firstMatch.id;
                      final encodedTarget = Uri.encodeComponent(target);
                      final tId = firstMatch.tournamentId ?? '';
                      context.push(
                        firstMatch.isKachinuki
                            ? '/kachinuki-scoreboard/$encodedTarget?tournamentId=$tId'
                            : '/team-scoreboard/$encodedTarget?tournamentId=$tId',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      side: BorderSide(
                        color: titleColor.withValues(alpha: 0.2),
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
                        color: context.appColors.primaryAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// リーグ戦参加チーム一覧を最大2行でレスポンシブに描画し、溢れた場合は「+◯チーム」と表示するWidget
class _LeagueParticipantsText extends StatelessWidget {
  final List<String> participants;
  final List<String> ownTeams;
  final String? ruleTeam;
  final bool isDark;
  final Color titleColor;

  const _LeagueParticipantsText({
    required this.participants,
    required this.ownTeams,
    required this.ruleTeam,
    required this.isDark,
    required this.titleColor,
  });

  bool _isOwn(String p) =>
      ownTeams.contains(p) ||
      (ruleTeam != null && ruleTeam!.isNotEmpty && p == ruleTeam);

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) return const SizedBox.shrink();

    // 自チームを先頭に優先配置（自チームが「+◯チーム」の中に隠れないように保証）
    final sorted = List<String>.from(participants);
    final ownIdx = sorted.indexWhere(_isOwn);
    if (ownIdx > 0) {
      final own = sorted.removeAt(ownIdx);
      sorted.insert(0, own);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        TextSpan buildSpan(List<String> teams, {int extraCount = 0}) {
          return TextSpan(
            children: [
              for (int i = 0; i < teams.length; i++) ...[
                if (i > 0)
                  TextSpan(
                    text: ' · ',
                    style: TextStyle(
                      fontSize: AppFontSize.subhead,
                      fontWeight: AppFontWeight.regular,
                      color: context.appColors.subTextColor,
                    ),
                  ),
                TextSpan(
                  text: teams[i],
                  style: TextStyle(
                    fontSize: AppFontSize.subhead,
                    fontWeight: _isOwn(teams[i])
                        ? AppFontWeight.black
                        : AppFontWeight.bold,
                    color: _isOwn(teams[i])
                        ? (isDark
                              ? const Color(0xFFFFB300)
                              : const Color(0xFFD97706))
                        : titleColor,
                  ),
                ),
              ],
              if (extraCount > 0) ...[
                TextSpan(
                  text: ' +$extraCountチーム',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.bold,
                    color: isDark
                        ? const Color(0xFF9E9E9E)
                        : context.appColors.subTextColor,
                  ),
                ),
              ],
            ],
          );
        }

        bool fits(TextSpan span) {
          final tp = TextPainter(
            text: span,
            textDirection: TextDirection.ltr,
            maxLines: 2,
            textScaler: MediaQuery.textScalerOf(context),
          );
          tp.layout(maxWidth: maxWidth);
          // テスト環境等でグリフ未ロード（tp.width <= 0）の場合の安全フォールバック
          if (tp.width <= 0) {
            final plainText = span.toPlainText();
            double estWidth = 0;
            for (final char in plainText.runes) {
              estWidth += (char > 128)
                  ? AppFontSize.subhead
                  : AppFontSize.subhead * 0.55;
            }
            return estWidth <= maxWidth * 2.0;
          }
          return !tp.didExceedMaxLines;
        }

        // 1. 全チームが2行に収まるか
        final allSpan = buildSpan(sorted);
        if (fits(allSpan)) {
          return Text.rich(
            allSpan,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
        }

        // 2. 収まらない場合、後ろのチームから減らし「+◯チーム」を付けて2行に収まる限界を探索
        for (int k = sorted.length - 1; k >= 1; k--) {
          final candidate = buildSpan(
            sorted.take(k).toList(),
            extraCount: sorted.length - k,
          );
          if (fits(candidate) || k == 1) {
            return Text.rich(
              candidate,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            );
          }
        }

        return Text.rich(allSpan, maxLines: 2, overflow: TextOverflow.ellipsis);
      },
    );
  }
}
