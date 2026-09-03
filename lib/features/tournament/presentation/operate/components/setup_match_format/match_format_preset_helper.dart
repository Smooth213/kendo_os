import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_form_state.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_save_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_team_detail_dialog.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 対戦フォーマット設定（コート・見出しプリセット・ダイアログ補助等）の処理ヘルパー
class MatchFormatPresetHelper {
  const MatchFormatPresetHelper._();

  static const List<String> defaultNoteHistory = [
    '1回戦',
    '2回戦',
    '準決勝',
    '決勝',
    '第1試合',
    '第2コート',
  ];

  /// カンマ区切りの文字列 [current] に対して [preset] をトグル（追加または削除）し、
  /// カンマとスペースで整形した文字列を返す。
  static String togglePreset(String current, String preset) {
    final trimmedCurrent = current.trim();
    final trimmedPreset = preset.trim();

    if (trimmedPreset.isEmpty) return trimmedCurrent;
    if (trimmedCurrent.isEmpty) return trimmedPreset;

    final items = trimmedCurrent
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (items.contains(trimmedPreset)) {
      items.remove(trimmedPreset);
    } else {
      items.add(trimmedPreset);
    }

    return items.join(', ');
  }

  /// カンマ区切りの文字列から空要素を取り除き、正規化して返す
  static String normalizeCsv(String input) {
    return input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(', ');
  }

  /// チーム詳細・ポジション調整ダイアログの表示補助
  static void showTeamDetail({
    required BuildContext context,
    required TeamModel team,
    required AppThemeColors themeColors,
    required List<PlayerModel> players,
    required VoidCallback onTeamUpdated,
  }) {
    final baseLen = MatchFormatSetupHelper.calculateTeamSize(
      matchType: team.matchType,
      selectedTeamId: null,
      registeredTeams: [],
    );
    final posNames = MatchFormatSetupHelper.generatePositions(baseLen);

    MatchFormatTeamDetailDialog.show(
      context: context,
      team: team,
      posNames: posNames,
      themeColors: themeColors,
      players: players,
      onTeamUpdated: (_) => onTeamUpdated(),
    );
  }

  /// 対戦フォーマット設定の保存実行
  static void saveFormatSetup({
    required WidgetRef ref,
    required String courtText,
    required String userNote,
    required List<TeamModel> registeredTeams,
    required MatchFormatFormState state,
    required String category,
    required String winPointText,
    required String lossPointText,
    required String drawPointText,
    required String overallTimeText,
  }) {
    MatchFormatSaveHelper.commitAndSaveRule(
      ref: ref,
      courtText: courtText.trim(),
      userNote: userNote.trim(),
      registeredTeams: registeredTeams,
      selectedTeamId: state.selectedTeamId,
      matchType: state.matchType,
      category: category,
      matchTime: state.matchTime,
      isRunningTime: state.isRunningTime,
      isRenseikai: state.isRenseikai,
      hasExtension: state.hasExtension,
      hasHantei: state.hasHantei,
      extCount: state.extCount,
      extTime: state.extTime,
      kachinukiUnlimitedType: state.kachinukiUnlimitedType,
      hasLeagueDaihyo: state.hasLeagueDaihyo,
      renseikaiType: state.renseikaiType,
      isDaihyoIpponShobu: state.isDaihyoIpponShobu,
      winPointText: winPointText,
      lossPointText: lossPointText,
      drawPointText: drawPointText,
      overallTimeText: overallTimeText,
      selectedRuleScene: state.selectedRuleScene,
    );
  }
}
