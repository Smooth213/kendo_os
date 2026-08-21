import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'expedition_stats_models.dart';

/// 遠征・公式記録の成績集計エンジン
class ExpeditionStatsCalculator {
  static ExpeditionSummaryData calculate({
    required List<MatchModel> matches,
    required Set<String> registeredTeamNames,
    required Set<String> registeredPlayerNames,
    required String selectedSummaryTeam,
  }) {
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

    int teamMen = 0,
        teamKote = 0,
        teamDou = 0,
        teamTsuki = 0,
        teamHansoku = 0,
        teamOther = 0;
    int teamTotalScored = 0;
    int teamTotalConceded = 0;

    final Map<String, DetailedPlayerStats> playerStatsMap = {};
    final List<ExpeditionCardResult> cardResults = [];

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
            (selectedSummaryTeam == '全体' && rIsMine) ||
            (selectedSummaryTeam == rTeam);
        final bool isTargetWhite =
            (selectedSummaryTeam == '全体' && wIsMine) ||
            (selectedSummaryTeam == wTeam);

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
                () => DetailedPlayerStats(),
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
                () => DetailedPlayerStats(),
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
          ExpeditionCardResult(
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
              (selectedSummaryTeam == '全体' && rIsMine) ||
              (selectedSummaryTeam == rTeam);
          final bool isTargetWhite =
              (selectedSummaryTeam == '全体' && wIsMine) ||
              (selectedSummaryTeam == wTeam);
          if (!isTargetRed && !isTargetWhite) continue;

          final isDraw = m.redScore == m.whiteScore;

          if (isTargetRed && rPlayer.isNotEmpty && isMyPlayer(rPlayer, rTeam)) {
            final stats = playerStatsMap.putIfAbsent(
              rPlayer,
              () => DetailedPlayerStats(),
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
              () => DetailedPlayerStats(),
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
          (selectedSummaryTeam == '全体' && rIsMine) ||
          (selectedSummaryTeam == rTeam);
      final bool isTargetWhite =
          (selectedSummaryTeam == '全体' && wIsMine) ||
          (selectedSummaryTeam == wTeam);
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
            () => DetailedPlayerStats(),
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
              () => DetailedPlayerStats(),
            );
            pStats.concededPoints++;
          }
        }
      }
    }

    return ExpeditionSummaryData(
      teamsList: teamsList,
      renseikaiWin: renseikaiWin,
      renseikaiLoss: renseikaiLoss,
      renseikaiDraw: renseikaiDraw,
      honsenWin: honsenWin,
      honsenLoss: honsenLoss,
      honsenDraw: honsenDraw,
      moushiawaseWin: moushiawaseWin,
      moushiawaseLoss: moushiawaseLoss,
      moushiawaseDraw: moushiawaseDraw,
      teamMen: teamMen,
      teamKote: teamKote,
      teamDou: teamDou,
      teamTsuki: teamTsuki,
      teamHansoku: teamHansoku,
      teamOther: teamOther,
      teamTotalScored: teamTotalScored,
      teamTotalConceded: teamTotalConceded,
      playerStatsMap: playerStatsMap,
      cardResults: cardResults,
    );
  }
}
