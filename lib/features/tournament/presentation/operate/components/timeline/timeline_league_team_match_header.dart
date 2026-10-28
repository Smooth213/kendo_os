import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/band/presentation/components/band_share_button.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_dialog_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_group_score_summary.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_scene_badge.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// タイムラインのリーグ戦チーム対抗戦ヘッダー（通常の団体戦と同じ5段構造）
class TimelineLeagueTeamMatchHeader extends ConsumerWidget {
  final List<MatchModel> bouts;
  final bool isReadOnlyUI;
  final bool boutsAllFinished;
  final bool boutsInProgress;
  final String t1;
  final String t2;
  final List<String> ownTeams;
  final Color mTitleColor;
  final bool isDark;
  final void Function(
    BuildContext context,
    WidgetRef ref,
    List<MatchModel> bouts,
  )
  onShowSummaryInputDialog;

  const TimelineLeagueTeamMatchHeader({
    super.key,
    required this.bouts,
    required this.isReadOnlyUI,
    required this.boutsAllFinished,
    required this.boutsInProgress,
    required this.t1,
    required this.t2,
    required this.ownTeams,
    required this.mTitleColor,
    required this.isDark,
    required this.onShowSummaryInputDialog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstBout = bouts.firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔽 【1段目】: 属性プレフィックス・ポジション数 ────── ステータスバッジ＆BANDボタン
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (firstBout != null)
              Builder(
                builder: (context) {
                  final scene = KendoSceneHelper.detectScene(firstBout);
                  if (scene == KendoMatchScene.honsen) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: KendoSceneBadge(scene: scene),
                  );
                },
              ),
            Text(
              '${bouts.length}ポジション',
              style: const TextStyle(
                fontSize: AppFontSize.caption,
                color: AppKendoColors.grey,
                fontWeight: AppFontWeight.bold,
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                MatchStatusBadge(
                  isPlaying: boutsInProgress,
                  isFinished: boutsAllFinished,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xxs),
                BandShareButton(matches: bouts),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),

        // 🔽 【2段目】: 対戦カード名（横幅全開・太字 subhead）
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$t1 vs $t2',
                    style: TextStyle(
                      fontSize: AppFontSize.subhead,
                      fontWeight: AppFontWeight.bold,
                      color: mTitleColor,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 🔽 【3段目】: コート情報・進行・メモ（存在時のみ）
        if (firstBout?.note.isNotEmpty == true) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                firstBout!.note,
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  color: context.appColors.subTextColor,
                  fontWeight: AppFontWeight.medium,
                ),
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
        ],

        // 🔽 【4段目】: アクションボタン行（(i) ルール / ⇅ オーダー / [⚡ 簡易入力] / [スコア]）
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxs),
          child: Row(
            children: [
              if (!boutsAllFinished && firstBout != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: InkWell(
                    onTap: () => showRuleInfoBottomSheet(context, firstBout),
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
              if (!isReadOnlyUI && !boutsAllFinished && bouts.isNotEmpty) ...[
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
                    onPressed: () => TimelineDialogHelper.showOrderReorderSheet(
                      context,
                      ref,
                      bouts,
                    ),
                    tooltip: 'オーダー編集',
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              const Spacer(),
              if (!isReadOnlyUI &&
                  !boutsAllFinished &&
                  firstBout != null &&
                  !(ownTeams.contains(t1) ||
                      firstBout.redName.contains('自チーム')) &&
                  !(ownTeams.contains(t2) ||
                      firstBout.whiteName.contains('自チーム'))) ...[
                SizedBox(
                  height: 26,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        onShowSummaryInputDialog(context, ref, bouts),
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
                        color: mTitleColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.subValue,
                      ),
                      side: BorderSide(
                        color: mTitleColor.withValues(alpha: 0.2),
                      ),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              if (firstBout != null)
                SizedBox(
                  height: 26,
                  child: OutlinedButton(
                    onPressed: () {
                      final target =
                          (firstBout.groupName != null &&
                              firstBout.groupName!.isNotEmpty)
                          ? firstBout.groupName!
                          : firstBout.id;
                      final encodedTarget = Uri.encodeComponent(target);
                      final tId = firstBout.tournamentId ?? '';
                      context.push(
                        '/team-scoreboard/$encodedTarget?tournamentId=$tId',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      side: BorderSide(
                        color: mTitleColor.withValues(alpha: 0.2),
                      ),
                      shape: const StadiumBorder(),
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
        const SizedBox(height: AppSpacing.sm),

        // 🔽 【5段目】: チーム対戦スコアサマリー（ピル型背景 0(0) - 0(0)）
        TimelineGroupScoreSummary(
          groupList: bouts,
          rTeam: t1,
          wTeam: t2,
          ownTeams: ownTeams,
          titleColor: mTitleColor,
          isDark: isDark,
        ),
      ],
    );
  }
}
