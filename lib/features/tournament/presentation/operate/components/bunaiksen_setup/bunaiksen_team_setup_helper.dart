import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:uuid/uuid.dart';

/// 部内戦の団体戦自動振り分け・試合モデル生成ヘルパー
class BunaiksenTeamSetupHelper {
  const BunaiksenTeamSetupHelper._();

  /// 学年順（同一年齢内は学年優先）でソートし、スネークドラフト法（蛇行配分）で紅組・白組に振り分ける
  static ({List<String?> redTeam, List<String?> whiteTeam}) autoAssignByGrade({
    required List<String> poolPlayers,
    required List<PlayerModel> masterPlayers,
    required int teamSize,
  }) {
    final sorted = List<String>.from(poolPlayers);
    sorted.sort((a, b) {
      final ga =
          masterPlayers.where((p) => p.name == a).firstOrNull?.grade ?? 99;
      final gb =
          masterPlayers.where((p) => p.name == b).firstOrNull?.grade ?? 99;
      return ga.compareTo(gb);
    });

    final red = List<String?>.filled(teamSize, null, growable: true);
    final white = List<String?>.filled(teamSize, null, growable: true);

    for (int i = 0; i < sorted.length; i++) {
      int pos = i ~/ 2;
      if (pos >= teamSize) break;
      if (i % 4 == 0 || i % 4 == 3) {
        if (red[pos] == null) {
          red[pos] = sorted[i];
        } else if (white[pos] == null) {
          white[pos] = sorted[i];
        }
      } else {
        if (white[pos] == null) {
          white[pos] = sorted[i];
        } else if (red[pos] == null) {
          red[pos] = sorted[i];
        }
      }
    }

    return (redTeam: red, whiteTeam: white);
  }

  /// 団体戦の試合モデルリストを生成する
  static List<MatchModel> generateTeamMatches({
    required int teamSize,
    required List<String> currentPositions,
    required List<String?> redTeam,
    required List<String?> whiteTeam,
    required MatchRule rule,
    required DateTime now,
  }) {
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final todayId = 'bunaiksen_$dateStr';
    final groupId = const Uuid().v4();
    final baseOrder = now.millisecondsSinceEpoch.toDouble();

    final List<MatchModel> matches = [];
    for (int i = 0; i < teamSize; i++) {
      final matchId = const Uuid().v4();
      final posName = i < currentPositions.length
          ? currentPositions[i]
          : '選手$i';
      matches.add(
        MatchModel(
          id: matchId,
          tournamentId: todayId,
          groupName: groupId,
          matchType: posName,
          redName: redTeam[i] ?? '未定',
          whiteName: whiteTeam[i] ?? '未定',
          matchTimeMinutes: rule.matchTimeMinutes,
          hasExtension: false,
          extensionTimeMinutes: 0.0,
          status: 'waiting',
          order: baseOrder + i,
          rule: rule.copyWith(
            isEnchoUnlimited: false,
            enchoTimeMinutes: 0.0,
            enchoCount: 0,
            hasHantei: false,
          ),
          note: '部内・団体戦',
        ),
      );
    }
    return matches;
  }
}
