import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_order_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_providers.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// チーム登録ウィザード Page2: オーダー入力ステップの組み立てビュー
class TeamRegistrationPageTwoView extends ConsumerWidget {
  final int playerCount;
  final List<String> posNames;
  final List<PlayerModel> players;
  final TextEditingController teamNameController;
  final FocusNode teamNameFocusNode;
  final Map<int, String> tempSelectedPlayers;
  final int substituteCount;
  final String matchType;
  final AppThemeColors themeColors;
  final Future<void> Function(int index) onSelectPlayer;
  final VoidCallback onAddSubstitute;
  final VoidCallback onAddPlayerSlot;
  final ValueChanged<int> onRemoveSubstitute;
  final ValueChanged<int> onRemovePlayerSlot;

  const TeamRegistrationPageTwoView({
    super.key,
    required this.playerCount,
    required this.posNames,
    required this.players,
    required this.teamNameController,
    required this.teamNameFocusNode,
    required this.tempSelectedPlayers,
    required this.substituteCount,
    required this.matchType,
    required this.themeColors,
    required this.onSelectPlayer,
    required this.onAddSubstitute,
    required this.onAddPlayerSlot,
    required this.onRemoveSubstitute,
    required this.onRemovePlayerSlot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TeamRegistrationOrderStep(
      playerCount: playerCount,
      posNames: posNames,
      players: players,
      teamNameController: teamNameController,
      teamNameFocusNode: teamNameFocusNode,
      teamNameSuggestions: ref.watch(customTeamNamesProvider).value ?? [],
      tempSelectedPlayers: tempSelectedPlayers,
      substituteCount: substituteCount,
      matchType: matchType,
      themeColors: themeColors,
      onSelectPlayer: onSelectPlayer,
      onRemoveSubstitute: onRemoveSubstitute,
      onAddSubstitute: onAddSubstitute,
      onAddPlayerSlot: onAddPlayerSlot,
      onRemovePlayerSlot: onRemovePlayerSlot,
    );
  }
}
