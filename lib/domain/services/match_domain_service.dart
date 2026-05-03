import 'package:uuid/uuid.dart';
import '../entities/match_model.dart';
import '../rules/match_rule.dart';
import '../entities/score_event.dart';

/// 剣道の試合進行に関する純粋なドメインルールをカプセル化するサービス
class MatchDomainService {
  
  /// 欠員による不戦勝イベントを自動生成する
  List<ScoreEvent> generateAutoFusenEvents(MatchModel match) {
    if (match.status != 'waiting' && match.status != 'in_progress') {
      return [];
    }
    
    bool rMiss = match.redName.contains('欠員');
    bool wMiss = match.whiteName.contains('欠員');
    bool hasFusen = match.events.any((e) => e.isFusen);
    
    if ((rMiss || wMiss) && !hasFusen) {
      if (rMiss && !wMiss) {
        return _createDoubleFusen(Side.white, match.scorerId);
      } else if (wMiss && !rMiss) {
        return _createDoubleFusen(Side.red, match.scorerId);
      }
    }
    return [];
  }

  List<ScoreEvent> _createDoubleFusen(Side side, String? scorerId) {
    return [
      ScoreEvent(id: const Uuid().v4(), side: side, isFusen: true, timestamp: DateTime.now(), userId: scorerId, sequence: 1),
      ScoreEvent(id: const Uuid().v4(), side: side, isFusen: true, timestamp: DateTime.now(), userId: scorerId, sequence: 2),
    ];
  }

  /// 勝ち抜き戦の次の試合を生成する
  MatchModel? generateNextKachinukiMatch(MatchModel finishedMatch, MatchRule rule) {
    if (!finishedMatch.isKachinuki) {
      return null;
    }

    List<String> nextRedRem = List.from(finishedMatch.redRemaining);
    List<String> nextWhiteRem = List.from(finishedMatch.whiteRemaining);
    String nextRedName = finishedMatch.redName;
    String nextWhiteName = finishedMatch.whiteName;
    bool isMatchOver = false;
    bool isEncho = false;

    if (finishedMatch.redScore == finishedMatch.whiteScore) { 
      if (nextRedRem.isEmpty && nextWhiteRem.isEmpty) {
        if (rule.kachinukiUnlimitedType == '大将引き分け延長' && finishedMatch.matchType != '大将延長戦') {
          isMatchOver = false; 
          isEncho = true;
        } else {
          isMatchOver = true;
        }
      } else if (nextRedRem.isEmpty || nextWhiteRem.isEmpty) {
        isMatchOver = true;
      } else {
        nextRedName = nextRedRem.removeAt(0); 
        nextWhiteName = nextWhiteRem.removeAt(0);
      }
    } else if (finishedMatch.redScore > finishedMatch.whiteScore) { 
      if (nextWhiteRem.isEmpty) {
        isMatchOver = true; 
      } else {
        nextWhiteName = nextWhiteRem.removeAt(0);
      }
    } else { 
      if (nextRedRem.isEmpty) {
        isMatchOver = true;
      } else {
        nextRedName = nextRedRem.removeAt(0);
      }
    }

    if (!isMatchOver) {
      return MatchModel(
        id: const Uuid().v4(), tournamentId: finishedMatch.tournamentId, category: finishedMatch.category, groupName: finishedMatch.groupName,
        matchType: isEncho ? '大将延長戦' : '勝ち抜き戦', redName: nextRedName, whiteName: nextWhiteName,
        status: 'waiting', matchTimeMinutes: finishedMatch.matchTimeMinutes, isRunningTime: finishedMatch.isRunningTime,
        remainingSeconds: finishedMatch.matchTimeMinutes * 60, order: finishedMatch.order + 0.1, 
        note: isEncho ? '延長戦（1本勝負）' : finishedMatch.note, isKachinuki: true,
        redRemaining: nextRedRem, whiteRemaining: nextWhiteRem,
      );
    }
    return null;
  }

  /// 次の試合へ勝者/敗者の名前を引き継ぐ（オーケストレーション用に更新対象のみ返す）
  List<MatchModel> propagateNameToNextMatches(MatchModel finishedMatch, List<MatchModel> allMatches) {
    final isRedWin = finishedMatch.redScore > finishedMatch.whiteScore;
    final isWhiteWin = finishedMatch.whiteScore > finishedMatch.redScore;
    if (!isRedWin && !isWhiteWin) {
      return [];
    }

    final winnerName = isRedWin ? finishedMatch.redName : finishedMatch.whiteName;
    final loserName = isRedWin ? finishedMatch.whiteName : finishedMatch.redName;
    final winnerTag = 'winner(${finishedMatch.id})';
    final loserTag = 'loser(${finishedMatch.id})';

    List<MatchModel> updatedMatches = [];
    for (var m in allMatches) {
      if (m.status != 'finished') {
        bool updated = false;
        String nextRed = m.redName, nextWhite = m.whiteName;
        if (nextRed.contains(winnerTag)) { nextRed = nextRed.replaceFirst(winnerTag, winnerName); updated = true; }
        if (nextRed.contains(loserTag)) { nextRed = nextRed.replaceFirst(loserTag, loserName); updated = true; }
        if (nextWhite.contains(winnerTag)) { nextWhite = nextWhite.replaceFirst(winnerTag, winnerName); updated = true; }
        if (nextWhite.contains(loserTag)) { nextWhite = nextWhite.replaceFirst(loserTag, loserName); updated = true; }
        if (updated) {
          updatedMatches.add(m.copyWith(redName: nextRed, whiteName: nextWhite));
        }
      }
    }
    return updatedMatches;
  }
}