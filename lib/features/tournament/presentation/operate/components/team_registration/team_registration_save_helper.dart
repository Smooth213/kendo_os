import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_name_history_provider.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/utils/text_sanitizer.dart';

/// チーム登録・保存・履歴更新ヘルパー
class TeamRegistrationSaveHelper {
  /// チームインスタンスを構築して保存し、履歴を更新
  static Future<void> saveTeamWithHistory({
    required WidgetRef ref,
    required String? editingTeamId,
    required String tournamentId,
    required String category,
    required String rawTeamName,
    required String matchType,
    required int playerCount,
    required Map<int, String> tempSelectedPlayers,
  }) async {
    final cleanTeamName = TextSanitizer.clean(rawTeamName);
    final team = TeamModel(
      id: editingTeamId ?? '',
      tournamentId: tournamentId,
      category: category,
      teamName: cleanTeamName,
      matchType: matchType,
      playerNames: List.generate(
        playerCount,
        (i) => tempSelectedPlayers[i] ?? '',
      ),
    );
    await ref.read(teamRepositoryProvider).saveTeam(team);
    ref.read(teamNameHistoryProvider.notifier).addHistory(rawTeamName.trim());
  }
}
