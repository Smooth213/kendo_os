import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/last_used_settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/setup_match_format_screen.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';

/// 試合形式設定のコミット・履歴保存ヘルパー
class MatchFormatSaveHelper {
  /// 設定をコミットして MatchRule をプロバイダに保存
  static MatchRule commitAndSaveRule({
    required WidgetRef ref,
    required String courtText,
    required String userNote,
    required List<TeamModel> registeredTeams,
    required String? selectedTeamId,
    required String matchType,
    required String category,
    required double matchTime,
    required bool isRunningTime,
    required bool isRenseikai,
    required bool hasExtension,
    required bool hasHantei,
    required int extCount,
    required double extTime,
    required String kachinukiUnlimitedType,
    required bool hasLeagueDaihyo,
    required String renseikaiType,
    required bool isDaihyoIpponShobu,
    required String winPointText,
    required String lossPointText,
    required String drawPointText,
    required String overallTimeText,
    required String selectedRuleScene,
  }) {
    final noteCombined = courtText.isNotEmpty
        ? (userNote.isNotEmpty ? '$courtText\n$userNote' : courtText)
        : userNote;

    if (userNote.isNotEmpty) {
      final words = userNote.split(' ');
      final currentHistory = ref.read(noteHistoryProvider);
      final updatedHistory = {
        ...words,
        ...currentHistory,
      }.toList().take(10).toList();
      ref.read(noteHistoryProvider.notifier).state = updatedHistory;
    }

    List<String> selectedBaseOrder = [];
    String teamNamePrefix = '';
    if (selectedTeamId != null) {
      for (var t in registeredTeams) {
        if (t.id == selectedTeamId) {
          selectedBaseOrder = t.playerNames;
          teamNamePrefix = t.teamName;
          break;
        }
      }
    }

    final teamSize = MatchFormatSetupHelper.calculateTeamSize(
      matchType: matchType,
      selectedTeamId: selectedTeamId,
      registeredTeams: registeredTeams,
    );

    final isLeague = matchType.contains('リーグ');
    final isKachinuki = matchType == '勝ち抜き戦';
    final generatedPositions = MatchFormatSetupHelper.generatePositions(
      teamSize,
    );

    final double winPt = double.tryParse(winPointText) ?? 0;
    final double lossPt = double.tryParse(lossPointText) ?? 0;
    final double drawPt = double.tryParse(drawPointText) ?? 0;
    final bool finalIsRunningTime = isRenseikai ? isRunningTime : false;

    ref.read(lastUsedSettingsProvider.notifier).state = {
      'matchType': matchType,
      'category': category,
      'matchTime': matchTime,
      'isRunningTime': finalIsRunningTime,
      'hasExtension': hasExtension,
      'hasHantei': hasHantei,
      'extensionCount': extCount,
      'extensionTimeMinutes': extTime,
      'isRenseikai': isRenseikai,
      'kachinukiUnlimitedType': kachinukiUnlimitedType,
      'hasLeagueDaihyo': hasLeagueDaihyo,
      'renseikaiType': renseikaiType,
      'isDaihyoIpponShobu': isDaihyoIpponShobu,
      'winPoint': winPt,
      'lossPoint': lossPt,
      'drawPoint': drawPt,
    };

    final rule = MatchFormatSetupHelper.createMatchRule(
      positions: generatedPositions,
      matchTime: matchTime,
      isRunningTime: finalIsRunningTime,
      isLeague: isLeague,
      category: category,
      noteCombined: noteCombined,
      isRenseikai: isRenseikai,
      baseOrder: selectedBaseOrder,
      teamName: teamNamePrefix,
      isKachinuki: isKachinuki,
      kachinukiUnlimitedType: kachinukiUnlimitedType,
      hasLeagueDaihyo: hasLeagueDaihyo,
      renseikaiType: renseikaiType,
      overallTimeMinutes: int.tryParse(overallTimeText) ?? 30,
      isDaihyoIpponShobu: isDaihyoIpponShobu,
      hasExtension: hasExtension,
      extTime: extTime,
      extCount: extCount,
      hasHantei: hasHantei,
      winPoint: winPt,
      lossPoint: lossPt,
      drawPoint: drawPt,
      selectedRuleScene: selectedRuleScene,
    );

    ref.read(matchRuleProvider.notifier).updateRule(rule);
    return rule;
  }
}
