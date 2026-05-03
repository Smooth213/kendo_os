import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/match_model.dart';
import 'bunaiksen_provider.dart';

final bunaiksenInfiniteEngineProvider = Provider((ref) => BunaiksenInfiniteEngine(ref));

class BunaiksenInfiniteEngine {
  final Ref ref;
  BunaiksenInfiniteEngine(this.ref);

  Future<MatchModel?> processMatchResult(MatchModel finishedMatch, String winnerColor) async {
    final queueNotifier = ref.read(bunaiksenInfiniteQueueProvider.notifier);
    final streakNotifier = ref.read(bunaiksenInfiniteStreakProvider.notifier);

    String? nextRed;
    String? nextWhite;

    if (winnerColor == 'red') {
      // 赤が勝ち残り
      nextRed = finishedMatch.redName;
      queueNotifier.moveToLast(finishedMatch.whiteName); // 負けた白は最後尾へ
      nextWhite = queueNotifier.popFirst(); // 次の挑戦者をポップ
      streakNotifier.incrementStreak(nextRed);
      streakNotifier.resetStreak(finishedMatch.whiteName);
    } else if (winnerColor == 'white') {
      // 白が勝ち残り（※剣道の勝ち抜きでは、勝者が「赤(元立ち位置)」に回る運用が多いため赤にセット）
      nextRed = finishedMatch.whiteName;
      queueNotifier.moveToLast(finishedMatch.redName); // 負けた赤は最後尾へ
      nextWhite = queueNotifier.popFirst();
      streakNotifier.incrementStreak(nextRed);
      streakNotifier.resetStreak(finishedMatch.redName);
    } else {
      // 引き分け（両者退場）
      queueNotifier.moveToLast(finishedMatch.redName);
      queueNotifier.moveToLast(finishedMatch.whiteName);
      nextRed = queueNotifier.popFirst();
      nextWhite = queueNotifier.popFirst();
      streakNotifier.resetStreak(finishedMatch.redName);
      streakNotifier.resetStreak(finishedMatch.whiteName);
    }

    if (nextRed == null || nextWhite == null) return null;

    // 次の試合を生成して返す
    return finishedMatch.copyWith(
      id: const Uuid().v4(),
      redName: nextRed,
      whiteName: nextWhite,
      redScore: 0,
      whiteScore: 0,
      status: 'waiting',
      order: DateTime.now().millisecondsSinceEpoch.toDouble(), 
    );
  }
}