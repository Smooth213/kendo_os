import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_edit_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_confirm_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_providers.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

/// チーム登録ウィザード Page3: 登録確認・チーム一覧ステップの組み立てビュー
class TeamRegistrationPageThreeView extends ConsumerWidget {
  final AsyncValue<List<TeamModel>> registeredTeamsAsync;
  final int playerCount;
  final String selectedCategory;
  final String teamName;
  final String matchType;
  final Map<int, String> tempSelectedPlayers;
  final AppThemeColors themeColors;
  final VoidCallback onAddNewTeam;

  const TeamRegistrationPageThreeView({
    super.key,
    required this.registeredTeamsAsync,
    required this.playerCount,
    required this.selectedCategory,
    required this.teamName,
    required this.matchType,
    required this.tempSelectedPlayers,
    required this.themeColors,
    required this.onAddNewTeam,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TeamRegistrationConfirmStep(
      registeredTeamsAsync: registeredTeamsAsync,
      playerCount: playerCount,
      selectedCategory: selectedCategory,
      teamName: teamName,
      matchType: matchType,
      tempSelectedPlayers: tempSelectedPlayers,
      themeColors: themeColors,
      onEditTeam: (t) {
        final players = ref.read(playerListProvider).value ?? <PlayerModel>[];
        TeamEditBottomSheet.show(
          context: context,
          team: t,
          players: players,
          onSave: (updatedTeam) async {
            await ref.read(teamRepositoryProvider).saveTeam(updatedTeam);
          },
        );
      },
      onUpdateCategory: (team, newCategory) async {
        try {
          final updated = team.copyWith(category: newCategory);
          await ref.read(teamRepositoryProvider).saveTeam(updated);
          if (context.mounted) {
            AppSnackBar.showSuccess(
              context,
              '「${team.teamName}」を「$newCategory」に変更しました',
            );
          }
        } catch (e) {
          if (context.mounted) {
            AppSnackBar.showError(context, 'カテゴリ変更エラー: $e');
          }
        }
      },
      onDeleteTeam: (teamId) =>
          ref.read(teamRepositoryProvider).deleteTeam(teamId),
      onAddNewTeam: onAddNewTeam,
    );
  }
}
