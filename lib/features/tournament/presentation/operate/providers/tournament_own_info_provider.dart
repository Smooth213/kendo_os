import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_registration_screen.dart'
    show customTeamNamesProvider;
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';

/// 🏆 大会に紐づく自チーム・登録選手・所属マッピング情報モデル
class TournamentOwnInfo {
  final Set<String> ownTeamNames;
  final Set<String> ownPlayerNames;
  final Map<String, String> playerToTeamMap;

  const TournamentOwnInfo({
    this.ownTeamNames = const {},
    this.ownPlayerNames = const {},
    this.playerToTeamMap = const {},
  });

  /// 赤または白サイドが自チームであるかを高精度に判定
  bool isOwnSide({
    required String teamPart,
    required String namePart,
    String? ruleTeamName,
  }) {
    final cleanTeam = teamPart.trim();
    final cleanName = namePart.trim();

    // 1. 登録された自チーム名と一致
    if (cleanTeam.isNotEmpty && ownTeamNames.contains(cleanTeam)) {
      return true;
    }

    // 2. 登録された自チーム選手名と一致（個人戦の選手名照合）
    if (cleanName.isNotEmpty && ownPlayerNames.contains(cleanName)) {
      return true;
    }

    // 3. ルールで明示的に指定された自チーム名と一致
    if (ruleTeamName != null && ruleTeamName.trim().isNotEmpty) {
      final cleanRule = ruleTeamName.trim();
      if (cleanTeam == cleanRule || cleanName == cleanRule) {
        return true;
      }
    }

    return false;
  }

  /// 選手名から登録所属チーム名を解決（該当がなければ null）
  String? resolveTeamForPlayer(String playerName) {
    final clean = playerName.trim();
    if (clean.isEmpty) return null;
    return playerToTeamMap[clean];
  }
}

/// 🏆 大会ごとの自チーム・選手・所属マッピングを提供するプロバイダー
final tournamentOwnInfoProvider = Provider.family<TournamentOwnInfo, String>((
  ref,
  tournamentId,
) {
  List<TeamModel> registeredTeams = const [];
  List<String> customNames = const [];

  try {
    if (tournamentId.isNotEmpty) {
      registeredTeams =
          ref.watch(registeredTeamsProvider(tournamentId)).value ??
          <TeamModel>[];
    }
  } catch (_) {
    // Firebase 未初期化テスト環境等の安全フォールバック
  }

  try {
    customNames = ref.watch(customTeamNamesProvider).value ?? <String>[];
  } catch (_) {
    // Firebase 未初期化テスト環境等の安全フォールバック
  }

  final ownTeamNames = <String>{...customNames};
  final ownPlayerNames = <String>{};
  final playerToTeamMap = <String, String>{};

  for (final team in registeredTeams) {
    final tName = team.teamName.trim();
    if (tName.isNotEmpty) {
      ownTeamNames.add(tName);
      for (final p in team.playerNames) {
        final pClean = p.trim();
        if (pClean.isNotEmpty) {
          ownPlayerNames.add(pClean);
          playerToTeamMap[pClean] = tName;
        }
      }
    }
  }

  return TournamentOwnInfo(
    ownTeamNames: ownTeamNames,
    ownPlayerNames: ownPlayerNames,
    playerToTeamMap: playerToTeamMap,
  );
});
