import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_data_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_state_holder.dart'
    show MatchEditOwnTeamChoice;
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

/// 試合編集シートの一括保存ロジックヘルパー
class MatchEditSaveHelper {
  static Future<void> executeSave({
    required BuildContext context,
    required WidgetRef ref,
    required List<MatchModel> matches,
    required bool isDantai,
    required bool isSwapped,
    required bool initialOwnIsRed,
    MatchEditOwnTeamChoice? ownTeamChoice,
    required String groupInput,
    required String redTeamInput,
    required String whiteTeamInput,
    required String courtInput,
    required String? selectedPresetKey,
    required MatchRule? selectedPresetRule,
    required double matchTime,
    required bool isRunningTime,
    required bool isIpponShobu,
    int ipponLimit = 2,
    int hansokuLimit = 2,
    required bool hasExtension,
    required double enchoTime,
    required int enchoCount,
    required bool isEnchoUnlimited,
    required bool hasHantei,
    required bool hasRepresentativeMatch,
    required bool isDaihyoIpponShobu,
    required double daihyoMatchTime,
    required bool daihyoHasExtension,
    required double daihyoEnchoTime,
    required int daihyoEnchoCount,
    required bool isDaihyoEnchoUnlimited,
    required bool daihyoHasHantei,
    required String renseikaiType,
    required int overallTimeMinutes,
    bool isKachinuki = false,
    String kachinukiUnlimitedType = '大将対大将',
    bool isLeague = false,
    double winPoint = 3.0,
    double lossPoint = 0.0,
    double drawPoint = 1.0,
    required String userNote,
    required String status,
    required List<TextEditingController> redPlayerControllers,
    required List<TextEditingController> whitePlayerControllers,
    List<String>? initialRedPlayers,
    List<String>? initialWhitePlayers,
  }) async {
    final firstMatch = matches.first;
    final rawGroup = firstMatch.groupName ?? '';
    final isUuidGroup = RegExp(
      r'^[a-f0-9\-]{20,}$',
      caseSensitive: false,
    ).hasMatch(rawGroup);

    final String fallbackGroupKey =
        (rawGroup.isNotEmpty &&
            !isUuidGroup &&
            rawGroup != '1回戦' &&
            rawGroup != '2回戦')
        ? rawGroup
        : 'group_${firstMatch.id}';

    final String finalGroupName = isDantai
        ? (courtInput.isNotEmpty
              ? courtInput
              : (groupInput.isNotEmpty ? groupInput : fallbackGroupKey))
        : (courtInput.isNotEmpty
              ? courtInput
              : (groupInput.isNotEmpty
                    ? groupInput
                    : (firstMatch.groupName ?? '')));

    final String targetOwnTeamName;
    if (ownTeamChoice != null) {
      switch (ownTeamChoice) {
        case MatchEditOwnTeamChoice.red:
          targetOwnTeamName = redTeamInput;
          break;
        case MatchEditOwnTeamChoice.white:
          targetOwnTeamName = whiteTeamInput;
          break;
        case MatchEditOwnTeamChoice.none:
          targetOwnTeamName = '';
          break;
      }
    } else {
      final bool currentOwnIsRed = isSwapped
          ? !initialOwnIsRed
          : initialOwnIsRed;
      targetOwnTeamName = currentOwnIsRed ? redTeamInput : whiteTeamInput;
    }

    final String sceneKey = selectedPresetKey ?? 'honsen';
    final bool isRenseikaiBool = sceneKey == 'renseikai';

    final updatedMatches = <MatchModel>[];

    // 勝ち抜き戦用の選手名置換設定
    final oldRedPlayers = initialRedPlayers ?? [];
    final oldWhitePlayers = initialWhitePlayers ?? [];
    final newRedPlayers = redPlayerControllers
        .map((c) => c.text.trim())
        .toList();
    final newWhitePlayers = whitePlayerControllers
        .map((c) => c.text.trim())
        .toList();
    final redTeam = redTeamInput.trim();
    final whiteTeam = whiteTeamInput.trim();

    String resolveRedPlayer(String oldRawName, int fallbackIndex) {
      final extracted = MatchEditDataHelper.extractPlayerName(oldRawName);
      final idx = oldRedPlayers.indexOf(extracted);
      final targetIdx = idx >= 0 ? idx : fallbackIndex;
      final newPlayer = (targetIdx >= 0 && targetIdx < newRedPlayers.length)
          ? newRedPlayers[targetIdx]
          : extracted;
      return redTeam.isNotEmpty
          ? (newPlayer.isNotEmpty ? '$redTeam: $newPlayer' : redTeam)
          : newPlayer;
    }

    String resolveWhitePlayer(String oldRawName, int fallbackIndex) {
      final extracted = MatchEditDataHelper.extractPlayerName(oldRawName);
      final idx = oldWhitePlayers.indexOf(extracted);
      final targetIdx = idx >= 0 ? idx : fallbackIndex;
      final newPlayer = (targetIdx >= 0 && targetIdx < newWhitePlayers.length)
          ? newWhitePlayers[targetIdx]
          : extracted;
      return whiteTeam.isNotEmpty
          ? (newPlayer.isNotEmpty ? '$whiteTeam: $newPlayer' : whiteTeam)
          : newPlayer;
    }

    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      final baseRule = selectedPresetRule ?? m.rule ?? const MatchRule();

      final updatedRule = baseRule.copyWith(
        matchScene: sceneKey,
        isRenseikai: isRenseikaiBool,
        matchTimeMinutes: matchTime,
        isRunningTime: isRunningTime,
        isIpponShobu: isIpponShobu,
        ipponLimit: isIpponShobu ? 1 : ipponLimit,
        hansokuLimit: hansokuLimit,
        hasHantei: hasHantei,
        enchoTimeMinutes: hasExtension ? enchoTime : 0.0,
        isEnchoUnlimited: hasExtension && isEnchoUnlimited,
        enchoCount: hasExtension ? (isEnchoUnlimited ? -2 : enchoCount) : 0,
        hasRepresentativeMatch: isDantai ? hasRepresentativeMatch : false,
        isDaihyoIpponShobu: isDaihyoIpponShobu,
        daihyoMatchTimeMinutes: daihyoMatchTime,
        daihyoHasExtension: daihyoHasExtension,
        daihyoEnchoTimeMinutes: daihyoHasExtension ? daihyoEnchoTime : 0.0,
        daihyoEnchoCount: daihyoHasExtension
            ? (isDaihyoEnchoUnlimited ? -2 : daihyoEnchoCount)
            : 0,
        daihyoHasHantei: daihyoHasHantei,
        renseikaiType: renseikaiType,
        overallTimeMinutes: overallTimeMinutes,
        isKachinuki: isKachinuki,
        kachinukiUnlimitedType: kachinukiUnlimitedType,
        isLeague: isLeague,
        winPoint: winPoint,
        lossPoint: lossPoint,
        drawPoint: drawPoint,
        teamName: ownTeamChoice == MatchEditOwnTeamChoice.none
            ? ''
            : (targetOwnTeamName.isNotEmpty
                  ? targetOwnTeamName
                  : baseRule.teamName),
      );

      final String finalRedName;
      final String finalWhiteName;
      final List<String> finalRedRemaining;
      final List<String> finalWhiteRemaining;

      if (isKachinuki) {
        // 🏆 勝ち抜き戦の選手名・待機リスト連動更新
        final isOnlyWaitingFirstMatch =
            matches.length == 1 && m.status == 'waiting';

        if (isOnlyWaitingFirstMatch) {
          finalRedName = newRedPlayers.isNotEmpty
              ? (redTeam.isNotEmpty
                    ? (newRedPlayers[0].isNotEmpty
                          ? '$redTeam: ${newRedPlayers[0]}'
                          : redTeam)
                    : newRedPlayers[0])
              : redTeam;
          finalWhiteName = newWhitePlayers.isNotEmpty
              ? (whiteTeam.isNotEmpty
                    ? (newWhitePlayers[0].isNotEmpty
                          ? '$whiteTeam: ${newWhitePlayers[0]}'
                          : whiteTeam)
                    : newWhitePlayers[0])
              : whiteTeam;

          finalRedRemaining = newRedPlayers.length > 1
              ? newRedPlayers
                    .sublist(1)
                    .map(
                      (p) => redTeam.isNotEmpty
                          ? (p.isNotEmpty ? '$redTeam: $p' : redTeam)
                          : p,
                    )
                    .toList()
              : [];
          finalWhiteRemaining = newWhitePlayers.length > 1
              ? newWhitePlayers
                    .sublist(1)
                    .map(
                      (p) => whiteTeam.isNotEmpty
                          ? (p.isNotEmpty ? '$whiteTeam: $p' : whiteTeam)
                          : p,
                    )
                    .toList()
              : [];
        } else {
          // 進行中・終了後を含む全試合:
          // 該当選手が出場している全試合（勝ち抜いて複数回登場含む）で連動して新名前に置換
          finalRedName = resolveRedPlayer(m.redName, i == 0 ? 0 : -1);
          finalWhiteName = resolveWhitePlayer(m.whiteName, i == 0 ? 0 : -1);
          finalRedRemaining = m.redRemaining
              .map((rem) => resolveRedPlayer(rem, -1))
              .toList();
          finalWhiteRemaining = m.whiteRemaining
              .map((rem) => resolveWhitePlayer(rem, -1))
              .toList();
        }
      } else {
        // 通常の団体戦・個人戦
        final redPlayer = i < redPlayerControllers.length
            ? redPlayerControllers[i].text.trim()
            : '';
        final whitePlayer = i < whitePlayerControllers.length
            ? whitePlayerControllers[i].text.trim()
            : '';

        finalRedName = redTeam.isNotEmpty
            ? (redPlayer.isNotEmpty ? '$redTeam: $redPlayer' : redTeam)
            : redPlayer;

        finalWhiteName = whiteTeam.isNotEmpty
            ? (whitePlayer.isNotEmpty ? '$whiteTeam: $whitePlayer' : whiteTeam)
            : whitePlayer;

        finalRedRemaining = m.redRemaining;
        finalWhiteRemaining = m.whiteRemaining;
      }

      final prefixParts = <String>[];
      if (courtInput.isNotEmpty) prefixParts.add(courtInput);
      if (groupInput.isNotEmpty) prefixParts.add(groupInput);

      final headerPrefix = prefixParts.join(' ');
      final noteCombined = headerPrefix.isNotEmpty
          ? (userNote.isNotEmpty ? '$headerPrefix\n$userNote' : headerPrefix)
          : userNote;

      final updatedMatch = m.copyWith(
        redName: finalRedName,
        whiteName: finalWhiteName,
        redRemaining: finalRedRemaining,
        whiteRemaining: finalWhiteRemaining,
        groupName: finalGroupName,
        note: noteCombined,
        rule: updatedRule,
        matchScene: sceneKey,
        status: m.status,
        matchTimeMinutes: matchTime,
        hasExtension: hasExtension,
        extensionTimeMinutes: hasExtension ? enchoTime : null,
        extensionCount: hasExtension
            ? (isEnchoUnlimited ? -2 : enchoCount)
            : null,
        hasHantei: hasHantei,
      );

      updatedMatches.add(updatedMatch);
    }

    await ref
        .read(matchApplicationServiceProvider)
        .saveMatchesBulk(updatedMatches);

    if (context.mounted) {
      AppSnackBar.showSuccess(
        context,
        isDantai ? '団体戦の全試合情報を一括保存しました' : '試合情報を保存・更新しました',
      );
      Navigator.pop(context);
    }
  }
}
