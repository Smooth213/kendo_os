import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_generator_provider.dart';
import 'package:kendo_os/shared/domain/entities/organization.dart';

/// ⚔️ 新規試合作成・自動生成サブミッションサービス
class NewMatchSubmissionService {
  const NewMatchSubmissionService();

  Future<bool> submitMatch({
    required WidgetRef ref,
    required String creationMode,
    required String? tournamentId,
    required String redName,
    required String whiteName,
    required String leagueParticipantsRaw,
    required Organization? redOrg,
    required TeamTemplate? redTeam,
    required Organization? whiteOrg,
    required TeamTemplate? whiteTeam,
    required String category,
    required String noteCombined,
    required bool countForStandings,
    required String selectedScene,
  }) async {
    final generator = ref.read(matchGeneratorProvider);

    if (creationMode == '単発試合') {
      if (redName.isEmpty || whiteName.isEmpty) {
        return false;
      }
      if (tournamentId == null) {
        return false;
      }

      final newMatch = MatchModel(
        id: const Uuid().v4(),
        matchType: '個人戦',
        redName: redName,
        whiteName: whiteName,
        source: 'manual',
        countForStandings: countForStandings,
        tournamentId: tournamentId,
        category: category,
        order: DateTime.now().millisecondsSinceEpoch.toDouble(),
        note: noteCombined,
        matchScene: selectedScene,
      );
      await ref.read(matchApplicationServiceProvider).saveMatch(newMatch);
      return true;
    } else if (creationMode == 'リーグ戦自動生成') {
      final participants = leagueParticipantsRaw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (participants.length < 2) {
        return false;
      }
      await generator.generateLeagueMatches(
        category,
        participants,
        countForStandings,
        noteCombined,
        tournamentId,
      );
      return true;
    } else if (creationMode == '団体戦テンプレ生成') {
      if (redOrg == null ||
          redTeam == null ||
          whiteOrg == null ||
          whiteTeam == null) {
        return false;
      }
      await generator.generateTeamMatchBouts(
        redTeam.name,
        redTeam.orderedMemberNames,
        whiteTeam.name,
        whiteTeam.orderedMemberNames,
        countForStandings,
        category: category,
        note: noteCombined,
        tournamentId: tournamentId,
      );
      return true;
    }

    return false;
  }
}
