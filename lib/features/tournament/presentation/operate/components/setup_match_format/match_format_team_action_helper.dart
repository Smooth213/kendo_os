import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_edit_bottom_sheet.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 🥋 対戦フォーマット設定画面におけるチーム編集・削除アクションのヘルパー
class MatchFormatTeamActionHelper {
  const MatchFormatTeamActionHelper._();

  /// チーム編集ボトムシートを開き、保存時のコールバックを実行
  static Future<void> handleEditTeam({
    required BuildContext context,
    required WidgetRef ref,
    required TeamModel team,
    required List<PlayerModel> players,
    required void Function(TeamModel updatedTeam) onSaved,
  }) async {
    await TeamEditBottomSheet.show(
      context: context,
      team: team,
      players: players,
      onSave: (updatedTeam) async {
        await ref.read(teamRepositoryProvider).saveTeam(updatedTeam);
        onSaved(updatedTeam);
      },
    );
  }

  /// チーム削除確認ダイアログを表示し、削除を実行
  static Future<void> handleDeleteTeam({
    required BuildContext context,
    required WidgetRef ref,
    required TeamModel team,
    required VoidCallback onDeleted,
  }) async {
    final confirm = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        titleWidget: const Text(
          'チームの削除',
          style: TextStyle(fontWeight: AppFontWeight.bold),
        ),
        content: Text('「${team.teamName}」を削除しますか？\n（この操作は取り消せません）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: AppKendoColors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '削除',
              style: TextStyle(
                color: AppKendoColors.redAccent,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(teamRepositoryProvider).deleteTeam(team.id);
      onDeleted();
      if (context.mounted) {
        AppSnackBar.showSuccess(context, 'チーム「${team.teamName}」を削除しました');
      }
    }
  }
}
