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
    required bool isIpponShobu,
    required bool hasHantei,
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
    final bool isRenseikaiOrMoushiawase =
        sceneKey == 'renseikai' || sceneKey == 'moushiawase';

    final updatedMatches = <MatchModel>[];

    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      final baseRule = selectedPresetRule ?? m.rule ?? const MatchRule();

      final updatedRule = baseRule.copyWith(
        matchScene: sceneKey,
        isRenseikai: isRenseikaiBool,
        matchTimeMinutes: matchTime,
        isIpponShobu: isIpponShobu,
        hasHantei: (isRenseikaiOrMoushiawase || isDantai) ? false : hasHantei,
        enchoTimeMinutes: (isRenseikaiOrMoushiawase || isDantai)
            ? 0.0
            : baseRule.enchoTimeMinutes,
        isEnchoUnlimited: (isRenseikaiOrMoushiawase || isDantai)
            ? false
            : baseRule.isEnchoUnlimited,
        hasRepresentativeMatch: isRenseikaiOrMoushiawase
            ? false
            : baseRule.hasRepresentativeMatch,
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
