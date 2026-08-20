import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

/// 🥋 大会公式記録 遠征・戦績集計サマリーカード
class OfficialRecordExpeditionSummaryCard extends StatefulWidget {
  final List<MatchModel> matches;
  final bool isDark;
  final Set<String> registeredTeamNames;
  final Set<String> registeredPlayerNames;

  const OfficialRecordExpeditionSummaryCard({
    super.key,
    required this.matches,
    required this.isDark,
    required this.registeredTeamNames,
    required this.registeredPlayerNames,
  });

  @override
  State<OfficialRecordExpeditionSummaryCard> createState() =>
      _OfficialRecordExpeditionSummaryCardState();
}

class _OfficialRecordExpeditionSummaryCardState
    extends State<OfficialRecordExpeditionSummaryCard> {
  String _selectedSummaryTeam = '全体';

  @override
  Widget build(BuildContext context) {
    if (widget.matches.isEmpty) return const SizedBox.shrink();

    final matches = widget.matches;
    final isDark = widget.isDark;
    final registeredTeamNames = widget.registeredTeamNames;
    final registeredPlayerNames = widget.registeredPlayerNames;

    // 1. 自チーム名の確定
    final List<String> teamsList;
    if (registeredTeamNames.isNotEmpty) {
      teamsList = registeredTeamNames.toList()..sort();
    } else {
      final teamsSet = <String>{};
      for (final m in matches) {
        if (m.redName.isNotEmpty) {
          final rTeam = m.redName.contains(':')
              ? m.redName.split(':').first.trim()
              : m.redName.trim();
          if (rTeam.isNotEmpty) teamsSet.add(rTeam);
        }
        if (m.whiteName.isNotEmpty) {
          final wTeam = m.whiteName.contains(':')
              ? m.whiteName.split(':').first.trim()
              : m.whiteName.trim();
          if (wTeam.isNotEmpty) teamsSet.add(wTeam);
        }
      }
      teamsList = teamsSet.toList()..sort();
    }

    // 自チーム判定ヘルパー
    bool isMyTeam(String teamName) {
      if (registeredTeamNames.isNotEmpty) {
        return registeredTeamNames.contains(teamName);
      }
      return teamsList.isNotEmpty && teamsList.first == teamName;
    }

    bool isMyPlayer(String playerName, String teamName) {
      if (registeredPlayerNames.isNotEmpty) {
        return registeredPlayerNames.contains(playerName);
      }
      return isMyTeam(teamName);
    }

    bool isMatchPlayed(MatchModel m) {
      return m.status == 'finished' || m.status == 'approved';
    }

    int renseikaiWin = 0, renseikaiLoss = 0, renseikaiDraw = 0;
    int honsenWin = 0, honsenLoss = 0, honsenDraw = 0;
    int moushiawaseWin = 0, moushiawaseLoss = 0, moushiawaseDraw = 0;

    // 技別集計（チーム全体）
    int teamMen = 0,
        teamKote = 0,
        teamDou = 0,
        teamTsuki = 0,
        teamHansoku = 0,
        teamOther = 0;
    int teamTotalScored = 0;
    int teamTotalConceded = 0;

    final Map<String, _DetailedPlayerStats> playerStatsMap = {};
    final List<_ExpeditionCardResult> cardResults = [];

    // 団体戦・勝ち抜き戦（groupNameごと）
    final Map<String, List<MatchModel>> groupMap = {};
    for (final m in matches) {
      final key = (m.groupName != null && m.groupName!.isNotEmpty)
          ? m.groupName!
          : m.id;
      groupMap.putIfAbsent(key, () => []).add(m);
    }

    for (final entry in groupMap.entries) {
      final bouts = entry.value;
      if (bouts.isEmpty) continue;

      final firstMatch = bouts.first;
      final bool isTeamMatch =
          bouts.length > 1 ||
          firstMatch.isKachinuki ||
          firstMatch.matchType.contains('団体') ||
          firstMatch.matchType == '先鋒' ||
          firstMatch.matchType == '次鋒' ||
          firstMatch.matchType == '中堅' ||
          firstMatch.matchType == '副将' ||
          firstMatch.matchType == '大将' ||
          firstMatch.matchType == '代表戦';

      if (isTeamMatch) {
        final allBoutsFinished = bouts.every(
          (b) => b.status == 'finished' || b.status == 'approved',
        );
        if (!firstMatch.isKachinuki && !allBoutsFinished) continue;
        if (firstMatch.isKachinuki && !isMatchPlayed(bouts.last)) continue;

        final rTeam = firstMatch.redName.contains(':')
            ? firstMatch.redName.split(':').first.trim()
            : firstMatch.redName.trim();
        final wTeam = firstMatch.whiteName.contains(':')
            ? firstMatch.whiteName.split(':').first.trim()
            : firstMatch.whiteName.trim();

        final bool rIsMine = isMyTeam(rTeam);
        final bool wIsMine = isMyTeam(wTeam);

        if (!rIsMine && !wIsMine) continue;

        final bool isTargetRed =
            (_selectedSummaryTeam == '全体' && rIsMine) ||
            (_selectedSummaryTeam == rTeam);
        final bool isTargetWhite =
            (_selectedSummaryTeam == '全体' && wIsMine) ||
            (_selectedSummaryTeam == wTeam);

        if (!isTargetRed && !isTargetWhite) continue;

        final playedBouts = bouts.where((b) => isMatchPlayed(b)).toList();
        if (playedBouts.isEmpty) continue;

        int myWins = 0;
        int oppWins = 0;
        int myPoints = 0;
        int oppPoints = 0;
        bool hasDaihyo = false;
        bool? daihyoIsMyWin;

        if (firstMatch.isKachinuki) {
          final lastMatch = bouts.last;
          if (isMatchPlayed(lastMatch)) {
            if (lastMatch.redRemaining.length >
                lastMatch.whiteRemaining.length) {
              if (isTargetRed) {
                myWins = 1;
              } else {
                oppWins = 1;
              }
            } else if (lastMatch.whiteRemaining.length >
                lastMatch.redRemaining.length) {
              if (isTargetWhite) {
                myWins = 1;
              } else {
                oppWins = 1;
              }
            }
          } else {
            for (final b in playedBouts) {
              if (isTargetRed) {
                if (b.redScore > b.whiteScore) {
                  myWins++;
                } else if (b.whiteScore > b.redScore) {
                  oppWins++;
                }
              } else {
                if (b.whiteScore > b.redScore) {
                  myWins++;
                } else if (b.redScore > b.whiteScore) {
                  oppWins++;
                }
              }
            }
          }
        } else {
          for (final b in playedBouts) {
            final int rScore = (b.redScore as num).toInt();
            final int wScore = (b.whiteScore as num).toInt();

            if (b.matchType == '代表戦') {
              hasDaihyo = true;
              if (rScore > wScore) {
                daihyoIsMyWin = isTargetRed;
              } else if (wScore > rScore) {
                daihyoIsMyWin = isTargetWhite;
              }
            } else {
              if (isTargetRed) {
                myPoints += rScore;
                oppPoints += wScore;
                if (rScore > wScore) {
                  myWins++;
                } else if (wScore > rScore) {
                  oppWins++;
                }
              } else {
                myPoints += wScore;
                oppPoints += rScore;
                if (wScore > rScore) {
                  myWins++;
                } else if (rScore > wScore) {
                  oppWins++;
                }
              }
            }

            final rPlayer = b.redName.contains(':')
                ? b.redName.split(':').last.trim()
                : b.redName.trim();
            final wPlayer = b.whiteName.contains(':')
                ? b.whiteName.split(':').last.trim()
                : b.whiteName.trim();

            if (isTargetRed &&
                rPlayer.isNotEmpty &&
                isMyPlayer(rPlayer, rTeam)) {
              final stats = playerStatsMap.putIfAbsent(
                rPlayer,
                () => _DetailedPlayerStats(),
              );
              if (rScore == wScore) {
                stats.draw++;
              } else if (rScore > wScore) {
                stats.win++;
              } else {
                stats.loss++;
              }
            }
            if (isTargetWhite &&
                wPlayer.isNotEmpty &&
                isMyPlayer(wPlayer, wTeam)) {
              final stats = playerStatsMap.putIfAbsent(
                wPlayer,
                () => _DetailedPlayerStats(),
              );
              if (wScore == rScore) {
                stats.draw++;
              } else if (wScore > rScore) {
                stats.win++;
              } else {
                stats.loss++;
              }
            }
          }
        }

        bool isWin = false;
        bool isDraw = false;
        String resultType = '引き分け';

        if (myWins > oppWins) {
          isWin = true;
          resultType = '勝数勝ち';
        } else if (oppWins > myWins) {
          isWin = false;
          resultType = '敗戦';
        } else {
          if (myPoints > oppPoints) {
            isWin = true;
            resultType = '本数差勝ち';
          } else if (oppPoints > myPoints) {
            isWin = false;
            resultType = '本数差負け';
          } else {
            if (hasDaihyo && daihyoIsMyWin != null) {
              if (daihyoIsMyWin == true) {
                isWin = true;
                resultType = '代表戦勝ち';
              } else {
                isWin = false;
                resultType = '代表戦負け';
              }
            } else {
              isDraw = true;
              resultType = '引き分け';
            }
          }
        }

        final opponentTeam = isTargetRed ? wTeam : rTeam;
        final scene = firstMatch.matchScene;

        final DateTime? matchTime =
            firstMatch.lastUpdatedAt ??
            firstMatch.timerStartedAt ??
            (firstMatch.events.isNotEmpty
                ? firstMatch.events.first.timestamp
                : null);
        final String timeStr = matchTime != null
            ? DateFormat('HH:mm').format(matchTime)
            : '';

        final String sceneLabel = scene == 'renseikai'
            ? '錬成会'
            : (scene == 'moushiawase'
                  ? '申し合わせ'
                  : (scene == 'honsen' ? '本戦' : '団体戦'));
        final String timeSceneLabel = timeStr.isNotEmpty
            ? '$timeStr $sceneLabel'
            : sceneLabel;

        final uuidRegex = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        );
        final rawGroupName = (firstMatch.groupName ?? '').trim();
        final isUuid =
            uuidRegex.hasMatch(rawGroupName) ||
            rawGroupName.length > 25 ||
            rawGroupName == '__default__' ||
            rawGroupName.contains(' vs ');

        final String cardTitle;
        if (!isUuid && rawGroupName.isNotEmpty && rawGroupName != '団体戦') {
          cardTitle = '$rawGroupName ($timeSceneLabel)';
        } else {
          cardTitle = timeSceneLabel;
        }

        cardResults.add(
          _ExpeditionCardResult(
            cardTitle: cardTitle,
            opponentTeamName: opponentTeam,
            myWins: myWins,
            oppWins: oppWins,
            myPoints: myPoints,
            oppPoints: oppPoints,
            resultType: resultType,
            isWin: isWin,
            isDraw: isDraw,
            scene: scene,
          ),
        );

        if (scene == 'renseikai') {
          if (isDraw) {
            renseikaiDraw++;
          } else if (isWin) {
            renseikaiWin++;
          } else {
            renseikaiLoss++;
          }
        } else if (scene == 'moushiawase') {
          if (isDraw) {
            moushiawaseDraw++;
          } else if (isWin) {
            moushiawaseWin++;
          } else {
            moushiawaseLoss++;
          }
        } else {
          if (isDraw) {
            honsenDraw++;
          } else if (isWin) {
            honsenWin++;
          } else {
            honsenLoss++;
          }
        }
      } else {
        for (final m in bouts) {
          if (!isMatchPlayed(m)) continue;

          final rTeam = m.redName.contains(':')
              ? m.redName.split(':').first.trim()
              : m.redName.trim();
          final wTeam = m.whiteName.contains(':')
              ? m.whiteName.split(':').first.trim()
              : m.whiteName.trim();
          final rPlayer = m.redName.contains(':')
              ? m.redName.split(':').last.trim()
              : m.redName.trim();
          final wPlayer = m.whiteName.contains(':')
              ? m.whiteName.split(':').last.trim()
              : m.whiteName.trim();

          final bool rIsMine = isMyTeam(rTeam) || isMyPlayer(rPlayer, rTeam);
          final bool wIsMine = isMyTeam(wTeam) || isMyPlayer(wPlayer, wTeam);
          if (!rIsMine && !wIsMine) continue;

          final bool isTargetRed =
              (_selectedSummaryTeam == '全体' && rIsMine) ||
              (_selectedSummaryTeam == rTeam);
          final bool isTargetWhite =
              (_selectedSummaryTeam == '全体' && wIsMine) ||
              (_selectedSummaryTeam == wTeam);
          if (!isTargetRed && !isTargetWhite) continue;

          final isDraw = m.redScore == m.whiteScore;

          if (isTargetRed && rPlayer.isNotEmpty && isMyPlayer(rPlayer, rTeam)) {
            final stats = playerStatsMap.putIfAbsent(
              rPlayer,
              () => _DetailedPlayerStats(),
            );
            if (isDraw) {
              stats.draw++;
            } else if (m.redScore > m.whiteScore) {
              stats.win++;
            } else {
              stats.loss++;
            }
          }
          if (isTargetWhite &&
              wPlayer.isNotEmpty &&
              isMyPlayer(wPlayer, wTeam)) {
            final stats = playerStatsMap.putIfAbsent(
              wPlayer,
              () => _DetailedPlayerStats(),
            );
            if (isDraw) {
              stats.draw++;
            } else if (m.whiteScore > m.redScore) {
              stats.win++;
            } else {
              stats.loss++;
            }
          }
        }
      }
    }

    for (final m in matches) {
      if (!isMatchPlayed(m)) continue;

      final rTeam = m.redName.contains(':')
          ? m.redName.split(':').first.trim()
          : m.redName.trim();
      final wTeam = m.whiteName.contains(':')
          ? m.whiteName.split(':').first.trim()
          : m.whiteName.trim();
      final rPlayer = m.redName.contains(':')
          ? m.redName.split(':').last.trim()
          : m.redName.trim();
      final wPlayer = m.whiteName.contains(':')
          ? m.whiteName.split(':').last.trim()
          : m.whiteName.trim();

      final bool rIsMine = isMyTeam(rTeam) || isMyPlayer(rPlayer, rTeam);
      final bool wIsMine = isMyTeam(wTeam) || isMyPlayer(wPlayer, wTeam);
      if (!rIsMine && !wIsMine) continue;

      final bool isTargetRed =
          (_selectedSummaryTeam == '全体' && rIsMine) ||
          (_selectedSummaryTeam == rTeam);
      final bool isTargetWhite =
          (_selectedSummaryTeam == '全体' && wIsMine) ||
          (_selectedSummaryTeam == wTeam);
      if (!isTargetRed && !isTargetWhite) continue;

      for (final ev in m.events) {
        if (ev.isCanceled) continue;
        if (!ev.isIppon) continue;

        final bool evIsMine =
            (ev.side == Side.red && isTargetRed) ||
            (ev.side == Side.white && isTargetWhite);
        final bool evIsOpp =
            (ev.side == Side.red && isTargetWhite) ||
            (ev.side == Side.white && isTargetRed);

        if (evIsMine) {
          teamTotalScored++;
          final String myPlayer = ev.side == Side.red ? rPlayer : wPlayer;
          final pStats = playerStatsMap.putIfAbsent(
            myPlayer,
            () => _DetailedPlayerStats(),
          );
          pStats.totalPoints++;

          if (ev.isHansoku) {
            teamHansoku++;
            pStats.hansoku++;
          } else {
            switch (ev.strikeType) {
              case StrikeType.men:
                teamMen++;
                pStats.men++;
                break;
              case StrikeType.kote:
                teamKote++;
                pStats.kote++;
                break;
              case StrikeType.dou:
                teamDou++;
                pStats.dou++;
                break;
              case StrikeType.tsuki:
                teamTsuki++;
                pStats.tsuki++;
                break;
              default:
                teamOther++;
                pStats.other++;
                break;
            }
          }
        } else if (evIsOpp) {
          teamTotalConceded++;
          final String myPlayer = ev.side == Side.red ? wPlayer : rPlayer;
          if (myPlayer.isNotEmpty) {
            final pStats = playerStatsMap.putIfAbsent(
              myPlayer,
              () => _DetailedPlayerStats(),
            );
            pStats.concededPoints++;
          }
        }
      }
    }

    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF),
        borderRadius: AppRadius.large,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.analytics_outlined,
                    color: AppKendoColors.indigo,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    '成績サマリー',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.bodyMedium,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      _showExpeditionDetailBottomSheet(
                        context: context,
                        isDark: isDark,
                        teamName: _selectedSummaryTeam,
                        teamMen: teamMen,
                        teamKote: teamKote,
                        teamDou: teamDou,
                        teamTsuki: teamTsuki,
                        teamHansoku: teamHansoku,
                        teamOther: teamOther,
                        totalScored: teamTotalScored,
                        totalConceded: teamTotalConceded,
                        cardResults: cardResults,
                      );
                    },
                    borderRadius: AppRadius.round,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF38383A)
                            : themeColors.softAccent,
                        borderRadius: AppRadius.round,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bar_chart,
                            size: 14,
                            color: isDark
                                ? const Color(0xFFFFFFFF)
                                : context.appColors.primaryAccent,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            '詳細分析 ›',
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFFFFFFF)
                                  : context.appColors.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (teamsList.length > 1) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.compact,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3F51B5).withValues(alpha: 0.3)
                            : const Color(0xFFEEF2FF),
                        borderRadius: AppRadius.round,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3F51B5)
                              : context.appColors.primaryAccent.withValues(
                                  alpha: 0.3,
                                ),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: teamsList.contains(_selectedSummaryTeam)
                              ? _selectedSummaryTeam
                              : '全体',
                          isDense: true,
                          dropdownColor: isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFFFFFFF),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: isDark
                                ? const Color(0xFFFFFFFF)
                                : context.appColors.primaryAccent,
                            size: 20,
                          ),
                          style: TextStyle(
                            fontWeight: AppFontWeight.bold,
                            fontSize: AppFontSize.bodySmall,
                            color: isDark
                                ? const Color(0xFFFFFFFF)
                                : context.appColors.primaryAccent,
                          ),
                          items: ['全体', ...teamsList].map((t) {
                            return DropdownMenuItem<String>(
                              value: t,
                              child: Text(
                                t == '全体' ? '全チーム合計' : t,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFFFFFFF)
                                      : context.appColors.textColor,
                                  fontWeight: AppFontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedSummaryTeam = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                '⚔️ 錬成会',
                renseikaiWin,
                renseikaiLoss,
                renseikaiDraw,
                const Color(0xFFD97706),
              ),
              _buildSummaryItem(
                '🏆 本戦',
                honsenWin,
                honsenLoss,
                honsenDraw,
                const Color(0xFF3F51B5),
              ),
              _buildSummaryItem(
                '🤝 申し合わせ',
                moushiawaseWin,
                moushiawaseLoss,
                moushiawaseDraw,
                const Color(0xFF009688),
              ),
            ],
          ),
          if (playerStatsMap.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '👤 選手別成績（タップでカルテ表示）',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.bodySmall,
                    color: AppKendoColors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: playerStatsMap.entries.map((entry) {
                final pName = entry.key;
                final st = entry.value;
                return InkWell(
                  onTap: () {
                    _showPlayerDetailBottomSheet(
                      context: context,
                      isDark: isDark,
                      playerName: pName,
                      stats: st,
                    );
                  },
                  borderRadius: AppRadius.medium,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF2F2F7),
                      borderRadius: AppRadius.medium,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFFFFFFF).withValues(alpha: 0.15)
                            : const Color(0xFF000000).withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pName: ${st.win}勝${st.loss}敗${st.draw > 0 ? "${st.draw}分" : ""}',
                          style: TextStyle(
                            fontSize: AppFontSize.small,
                            fontWeight: AppFontWeight.bold,
                            color: context.appColors.textColor,
                          ),
                        ),
                        if (st.totalPoints > 0) ...[
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            '(${st.totalPoints}本)',
                            style: const TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.bold,
                              color: AppKendoColors.indigo,
                            ),
                          ),
                        ],
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: AppKendoColors.grey.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showExpeditionDetailBottomSheet({
    required BuildContext context,
    required bool isDark,
    required String teamName,
    required int teamMen,
    required int teamKote,
    required int teamDou,
    required int teamTsuki,
    required int teamHansoku,
    required int teamOther,
    required int totalScored,
    required int totalConceded,
    required List<_ExpeditionCardResult> cardResults,
  }) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final totalStrikes =
            teamMen + teamKote + teamDou + teamTsuki + teamHansoku + teamOther;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insights,
                          color: AppKendoColors.indigo,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '成績 詳細分析 ($teamName)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppFontSize.title,
                              fontWeight: AppFontWeight.bold,
                              color: context.appColors.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.xl),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      '🎯 有効打突・取得技内訳',
                      style: TextStyle(
                        fontSize: AppFontSize.subhead,
                        fontWeight: AppFontWeight.bold,
                        color: context.appColors.textColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF9FAFB),
                        borderRadius: AppRadius.large,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFFFFFFF).withValues(alpha: 0.1)
                              : const Color(0xFF000000).withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStrikeStatBadge(
                                  '面 (メ)',
                                  teamMen,
                                  totalStrikes,
                                  AppKendoColors.teal,
                                ),
                              ),
                              Expanded(
                                child: _buildStrikeStatBadge(
                                  '小手 (コ)',
                                  teamKote,
                                  totalStrikes,
                                  AppKendoColors.indigo,
                                ),
                              ),
                              Expanded(
                                child: _buildStrikeStatBadge(
                                  '胴 (ド)',
                                  teamDou,
                                  totalStrikes,
                                  const Color(0xFFD97706),
                                ),
                              ),
                              Expanded(
                                child: _buildStrikeStatBadge(
                                  '突き (ツ)',
                                  teamTsuki,
                                  totalStrikes,
                                  const Color(0xFF8B5CF6),
                                ),
                              ),
                              Expanded(
                                child: _buildStrikeStatBadge(
                                  '反則 (反)',
                                  teamHansoku,
                                  totalStrikes,
                                  AppKendoColors.hansokuRed,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: [
                              Text(
                                '総取得本数: $totalScored本',
                                style: const TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: AppFontSize.caption,
                                  color: AppKendoColors.teal,
                                ),
                              ),
                              Text(
                                '総失本数: $totalConceded本',
                                style: const TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: AppFontSize.caption,
                                  color: AppKendoColors.hansokuRed,
                                ),
                              ),
                              Text(
                                '得失差: ${totalScored - totalConceded >= 0 ? "+${totalScored - totalConceded}" : "${totalScored - totalConceded}"}',
                                style: TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: AppFontSize.caption,
                                  color: (totalScored - totalConceded) >= 0
                                      ? AppKendoColors.teal
                                      : AppKendoColors.hansokuRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      '⚖️ 団体戦 対戦カード履歴 (全剣連基準)',
                      style: TextStyle(
                        fontSize: AppFontSize.subhead,
                        fontWeight: AppFontWeight.bold,
                        color: context.appColors.textColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (cardResults.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Center(
                          child: Text(
                            '団体戦の対戦履歴はありません',
                            style: TextStyle(color: AppKendoColors.grey),
                          ),
                        ),
                      )
                    else
                      ...cardResults.map((res) {
                        final Color badgeBg = res.isWin
                            ? AppKendoColors.teal.withValues(alpha: 0.15)
                            : (res.isDraw
                                  ? AppKendoColors.grey.withValues(alpha: 0.15)
                                  : AppKendoColors.hansokuRed.withValues(
                                      alpha: 0.15,
                                    ));
                        final Color badgeText = res.isWin
                            ? AppKendoColors.teal
                            : (res.isDraw
                                  ? AppKendoColors.grey
                                  : AppKendoColors.hansokuRed);

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFFFFFFF),
                            borderRadius: AppRadius.medium,
                            border: Border.all(
                              color: isDark
                                  ? const Color(
                                      0xFFFFFFFF,
                                    ).withValues(alpha: 0.1)
                                  : const Color(
                                      0xFF000000,
                                    ).withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      res.cardTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: AppFontSize.caption,
                                        color: AppKendoColors.grey,
                                        fontWeight: AppFontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'vs ${res.opponentTeamName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: AppFontSize.body,
                                        fontWeight: AppFontWeight.bold,
                                        color: context.appColors.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${res.myWins}(${res.myPoints}) - ${res.oppWins}(${res.oppPoints})',
                                    style: TextStyle(
                                      fontSize: AppFontSize.bodyMedium,
                                      fontWeight: AppFontWeight.bold,
                                      color: context.appColors.textColor,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xxs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: AppRadius.round,
                                    ),
                                    child: Text(
                                      res.resultType,
                                      style: TextStyle(
                                        fontSize: AppFontSize.caption,
                                        fontWeight: AppFontWeight.bold,
                                        color: badgeText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlayerDetailBottomSheet({
    required BuildContext context,
    required bool isDark,
    required String playerName,
    required _DetailedPlayerStats stats,
  }) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: false,
      builder: (ctx) {
        final totalMatches = stats.win + stats.loss + stats.draw;
        final winRate = totalMatches > 0
            ? (stats.win / totalMatches * 100).toStringAsFixed(1)
            : '0.0';
        final totalStrikes =
            stats.men +
            stats.kote +
            stats.dou +
            stats.tsuki +
            stats.hansoku +
            stats.other;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: AppKendoColors.indigo,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '$playerName 選手の個人カルテ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppFontSize.title,
                              fontWeight: AppFontWeight.bold,
                              color: context.appColors.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatPill(
                    '総試合数',
                    '$totalMatches 試合',
                    AppKendoColors.grey,
                  ),
                  _buildStatPill(
                    '勝敗',
                    '${stats.win}勝 ${stats.loss}敗 ${stats.draw > 0 ? "${stats.draw}分" : ""}',
                    AppKendoColors.indigo,
                  ),
                  _buildStatPill('勝率', '$winRate %', AppKendoColors.teal),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '🎯 取得技の内訳',
                style: TextStyle(
                  fontSize: AppFontSize.subhead,
                  fontWeight: AppFontWeight.bold,
                  color: context.appColors.textColor,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF9FAFB),
                  borderRadius: AppRadius.large,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.1)
                        : const Color(0xFF000000).withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStrikeStatBadge(
                        '面 (メ)',
                        stats.men,
                        totalStrikes,
                        AppKendoColors.teal,
                      ),
                    ),
                    Expanded(
                      child: _buildStrikeStatBadge(
                        '小手 (コ)',
                        stats.kote,
                        totalStrikes,
                        AppKendoColors.indigo,
                      ),
                    ),
                    Expanded(
                      child: _buildStrikeStatBadge(
                        '胴 (ド)',
                        stats.dou,
                        totalStrikes,
                        const Color(0xFFD97706),
                      ),
                    ),
                    Expanded(
                      child: _buildStrikeStatBadge(
                        '突き (ツ)',
                        stats.tsuki,
                        totalStrikes,
                        const Color(0xFF8B5CF6),
                      ),
                    ),
                    Expanded(
                      child: _buildStrikeStatBadge(
                        '反則 (反)',
                        stats.hansoku,
                        totalStrikes,
                        AppKendoColors.hansokuRed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStrikeStatBadge(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.caption,
            fontWeight: AppFontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count本',
          style: const TextStyle(
            fontSize: AppFontSize.bodyMedium,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        Text(
          '$pct%',
          style: const TextStyle(
            fontSize: AppFontSize.caption,
            color: AppKendoColors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppFontSize.caption,
            color: AppKendoColors.grey,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: AppFontSize.bodyMedium,
            fontWeight: AppFontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    String title,
    int win,
    int loss,
    int draw,
    Color color,
  ) {
    final total = win + loss + draw;
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: AppFontWeight.bold,
            fontSize: AppFontSize.bodySmall,
            color: color,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          total > 0 ? '$win勝 $loss敗 ${draw > 0 ? "$draw分" : ""}' : '未実施',
          style: const TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: AppFontWeight.semiBold,
          ),
        ),
        if (total > 0)
          Text(
            '（計$total試合）',
            style: const TextStyle(
              fontSize: AppFontSize.caption,
              color: AppKendoColors.grey,
            ),
          ),
      ],
    );
  }
}

class _DetailedPlayerStats {
  int win = 0;
  int loss = 0;
  int draw = 0;
  int men = 0;
  int kote = 0;
  int dou = 0;
  int tsuki = 0;
  int hansoku = 0;
  int other = 0;
  int totalPoints = 0;
  int concededPoints = 0;
}

class _ExpeditionCardResult {
  final String cardTitle;
  final String opponentTeamName;
  final int myWins;
  final int oppWins;
  final int myPoints;
  final int oppPoints;
  final String resultType;
  final bool isWin;
  final bool isDraw;
  final String scene;

  _ExpeditionCardResult({
    required this.cardTitle,
    required this.opponentTeamName,
    required this.myWins,
    required this.oppWins,
    required this.myPoints,
    required this.oppPoints,
    required this.resultType,
    required this.isWin,
    required this.isDraw,
    required this.scene,
  });
}
