import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
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
        : (courtInput.isNotEmpty ? courtInput : groupInput);

    final bool currentOwnIsRed = isSwapped ? !initialOwnIsRed : initialOwnIsRed;
    final String targetOwnTeamName = currentOwnIsRed
        ? redTeamInput
        : whiteTeamInput;

    final String sceneKey = selectedPresetKey ?? 'honsen';
    final bool isRenseikaiBool = sceneKey == 'renseikai';

    final updatedMatches = <MatchModel>[];

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
        teamName: targetOwnTeamName.isNotEmpty
            ? targetOwnTeamName
            : baseRule.teamName,
      );

      final redPlayer = redPlayerControllers[i].text.trim();
      final whitePlayer = whitePlayerControllers[i].text.trim();

      final finalRedName = isDantai
          ? (redTeamInput.isNotEmpty
                ? (redPlayer.isNotEmpty
                      ? '$redTeamInput: $redPlayer'
                      : redTeamInput)
                : redPlayer)
          : redPlayer;

      final finalWhiteName = isDantai
          ? (whiteTeamInput.isNotEmpty
                ? (whitePlayer.isNotEmpty
                      ? '$whiteTeamInput: $whitePlayer'
                      : whiteTeamInput)
                : whitePlayer)
          : whitePlayer;

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
        groupName: finalGroupName,
        note: noteCombined,
        rule: updatedRule,
        matchScene: sceneKey,
        status: status,
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
