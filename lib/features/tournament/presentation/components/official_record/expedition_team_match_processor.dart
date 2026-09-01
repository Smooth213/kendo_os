import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_scene_badge.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';

/// 遠征成績の団体戦・勝ち抜き戦・個人戦集計プロセッサ
class ExpeditionTeamMatchProcessor {
  static void processTeamMatches({
    required Map<String, List<MatchModel>> groupMap,
    required String selectedSummaryTeam,
    required bool Function(String) isMyTeam,
    required bool Function(String, String) isMyPlayer,
    required bool Function(MatchModel) isMatchPlayed,
    required Map<String, DetailedPlayerStats> playerStatsMap,
    required List<ExpeditionCardResult> cardResults,
    required void Function(String scene, bool isWin, bool isDraw)
    onRecordSceneResult,
    void Function(bool isWin, bool isDraw)? onRecordIndividualResult,
  }) {
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
            final isDaihyo = b.matchType == '代表戦';
            if (isDaihyo) {
              hasDaihyo = true;
              if (isTargetRed) {
                if (b.redScore > b.whiteScore) {
                  daihyoIsMyWin = true;
                } else if (b.whiteScore > b.redScore) {
                  daihyoIsMyWin = false;
                }
              } else {
                if (b.whiteScore > b.redScore) {
                  daihyoIsMyWin = true;
                } else if (b.redScore > b.whiteScore) {
                  daihyoIsMyWin = false;
                }
              }
              continue;
            }

            if (isTargetRed) {
              myPoints += b.redScore;
              oppPoints += b.whiteScore;
              if (b.redScore > b.whiteScore) {
                myWins++;
              } else if (b.whiteScore > b.redScore) {
                oppWins++;
              }
            } else {
              myPoints += b.whiteScore;
              oppPoints += b.redScore;
              if (b.whiteScore > b.redScore) {
                myWins++;
              } else if (b.redScore > b.whiteScore) {
                oppWins++;
              }
            }

            // 🥋 団体戦内訳の選手個人成績集計
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
              if (b.redScore > b.whiteScore) {
                stats.win++;
                stats.teamWin++;
              } else if (b.redScore < b.whiteScore) {
                stats.loss++;
                stats.teamLoss++;
              } else {
                stats.draw++;
                stats.teamDraw++;
              }
            }
            if (isTargetWhite &&
                wPlayer.isNotEmpty &&
                isMyPlayer(wPlayer, wTeam)) {
              final stats = playerStatsMap.putIfAbsent(
                wPlayer,
                () => DetailedPlayerStats(),
              );
              if (b.whiteScore > b.redScore) {
                stats.win++;
                stats.teamWin++;
              } else if (b.whiteScore < b.redScore) {
                stats.loss++;
                stats.teamLoss++;
              } else {
                stats.draw++;
                stats.teamDraw++;
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

        final kScene = KendoSceneHelper.detectScene(firstMatch);
        final String sceneLabel = kScene == KendoMatchScene.honsen
            ? '本戦'
            : (kScene == KendoMatchScene.renseikai
                  ? '錬成'
                  : (kScene == KendoMatchScene.moushiawase ? '申合せ' : '団体戦'));
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
            isIndividual: false,
          ),
        );

        onRecordSceneResult(scene, isWin, isDraw);
      } else {
        // ⚔️ 個人戦ブロックの処理
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
          final isRedWin = m.redScore > m.whiteScore;
          final isWhiteWin = m.whiteScore > m.redScore;

          if (isTargetRed && rPlayer.isNotEmpty && isMyPlayer(rPlayer, rTeam)) {
            final stats = playerStatsMap.putIfAbsent(
              rPlayer,
              () => DetailedPlayerStats(),
            );
            if (isDraw) {
              stats.draw++;
              stats.individualDraw++;
              onRecordIndividualResult?.call(false, true);
            } else if (isRedWin) {
              stats.win++;
              stats.individualWin++;
              onRecordIndividualResult?.call(true, false);
            } else {
              stats.loss++;
              stats.individualLoss++;
              onRecordIndividualResult?.call(false, false);
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
              stats.individualDraw++;
              onRecordIndividualResult?.call(false, true);
            } else if (isWhiteWin) {
              stats.win++;
              stats.individualWin++;
              onRecordIndividualResult?.call(true, false);
            } else {
              stats.loss++;
              stats.individualLoss++;
              onRecordIndividualResult?.call(false, false);
            }
          }

          // 個人戦の対戦カード結果も追加
          final oppName = isTargetRed
              ? (wPlayer.isNotEmpty ? wPlayer : wTeam)
              : (rPlayer.isNotEmpty ? rPlayer : rTeam);
          final myScore = isTargetRed ? m.redScore : m.whiteScore;
          final oppScore = isTargetRed ? m.whiteScore : m.redScore;
          final bool isIndWin = isTargetRed ? isRedWin : isWhiteWin;

          cardResults.add(
            ExpeditionCardResult(
              cardTitle: '個人戦 (${m.matchType})',
              opponentTeamName: oppName,
              myWins: isIndWin ? 1 : 0,
              oppWins: (!isIndWin && !isDraw) ? 1 : 0,
              myPoints: myScore,
              oppPoints: oppScore,
              resultType: isIndWin ? '勝利' : (isDraw ? '引き分け' : '敗戦'),
              isWin: isIndWin,
              isDraw: isDraw,
              scene: m.matchScene,
              isIndividual: true,
            ),
          );
        }
      }
    }
  }
}
