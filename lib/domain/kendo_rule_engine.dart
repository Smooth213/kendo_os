import '../models/match_model.dart';
import '../models/score_event.dart';
import '../models/match_rule.dart';
import 'strategy/match_strategy.dart';

// ★ Phase 4: ルール計算の結果をまとめて返すためのデータ構造
class MatchAnalysis {
  final MatchContext context;
  final Map<Side, List<PointDisplay>> displays; // ★ String ではなく Side をキーにする
  MatchAnalysis({required this.context, required this.displays});
}

// ★ Phase 4: UIから移動してきた表示用データモデルをドメイン層に正式採用
class PointDisplay {
  final String mark;
  final bool isFirstMatchPoint;
  PointDisplay(this.mark, this.isFirstMatchPoint);
}

// ★ Phase 1: ドメイン例外
class DomainException implements Exception {
  final String message;
  DomainException(this.message);
  @override
  String toString() => message;
}

class ValidationResult {
  final bool isValid;
  final String? reason;
  ValidationResult(this.isValid, [this.reason]);
}

enum MatchResultStatus { inProgress, redWin, whiteWin, draw }

class MatchContext {
  final int redIppon;
  final int whiteIppon;
  final int redHansoku;
  final int whiteHansoku;
  final bool isTimeUp;
  final int targetIppon;
  final bool hasHantei; // ★ Phase 7-1: 判定ありフラグを追加

  MatchContext({
    required this.redIppon,
    required this.whiteIppon,
    required this.redHansoku,
    required this.whiteHansoku,
    required this.isTimeUp,
    required this.targetIppon,
    required this.hasHantei,
  });
}

/// ==========================================
/// ★ 剣道ルールエンジンの完成形 (SSOT)
/// すべての「計算」「判定」をこのクラスに集約する
/// ==========================================
class KendoRuleEngine {
  
  /// 1. 歴史（Events）から現在の状況をすべて解析する最重要メソッド
  MatchAnalysis analyzeHistory(List<ScoreEvent> allEvents, MatchModel match, MatchRule? rule) {
    // A. 有効なイベントのみを抽出 (Undoの解決)
    final activeEvents = _filterActiveEvents(allEvents);

    // B. 各種カウンターの初期化
    int rPts = 0, wPts = 0, rHansoku = 0, wHansoku = 0;
    List<PointDisplay> redDisplays = [];
    List<PointDisplay> whiteDisplays = [];
    bool isFirstOfMatch = true;

    // C. イベントを順番に走査して一本と反則を計算
    for (var e in activeEvents) {
      if (e.type == PointType.hansoku) {
        if (e.side == Side.red) {
          rHansoku++;
          if (isHansokuIppon(rHansoku)) {
            wPts++;
            whiteDisplays.add(PointDisplay('反', isFirstOfMatch));
            isFirstOfMatch = false;
          }
        } else if (e.side == Side.white) {
          wHansoku++;
          if (isHansokuIppon(wHansoku)) {
            rPts++;
            redDisplays.add(PointDisplay('反', isFirstOfMatch));
            isFirstOfMatch = false;
          }
        }
      } else if (e.type == PointType.fusen) {
        // ★ 修正：不戦勝は即座に2本（◯◯）としてカウントする
        const fusenIppon = 2;
        if (e.side == Side.red) {
          rPts += fusenIppon;
          redDisplays.add(PointDisplay('◯', isFirstOfMatch));
          redDisplays.add(PointDisplay('◯', false));
        } else if (e.side == Side.white) {
          wPts += fusenIppon;
          whiteDisplays.add(PointDisplay('◯', isFirstOfMatch));
          whiteDisplays.add(PointDisplay('◯', false));
        }
        isFirstOfMatch = false;
      } else {
        final mark = _getPointMark(e.type);
        if (mark != null) {
          if (e.side == Side.red) {
            rPts++;
            redDisplays.add(PointDisplay(mark, isFirstOfMatch));
          } else if (e.side == Side.white) {
            wPts++;
            whiteDisplays.add(PointDisplay(mark, isFirstOfMatch));
          }
          isFirstOfMatch = false;
        }
      }
    }

    final strategy = MatchStrategyFactory.getStrategy(match);
    final target = strategy.getTargetIppon(match, rule);

    // ★ Phase 7-1: 延長戦・代表戦は強制的に「1本勝負（サドンデス）」に変更
    final finalTarget = (match.matchType == '延長戦' || match.matchType == '代表戦') ? 1 : target;

    final context = MatchContext(
      redIppon: rPts, whiteIppon: wPts,
      redHansoku: rHansoku, whiteHansoku: wHansoku,
      isTimeUp: false, 
      targetIppon: finalTarget,
      hasHantei: rule?.hasHantei ?? false, // ★ 判定の有無をルールから継承
    );

    return MatchAnalysis(
      context: context,
      displays: {Side.red: redDisplays, Side.white: whiteDisplays},
    );
  }

  /// 2. 勝敗の決定ロジック
  MatchResultStatus decideResult(MatchContext ctx) {
    if (ctx.redIppon >= ctx.targetIppon) return MatchResultStatus.redWin;
    if (ctx.whiteIppon >= ctx.targetIppon) return MatchResultStatus.whiteWin;
    if (ctx.isTimeUp) {
      if (ctx.redIppon > ctx.whiteIppon) return MatchResultStatus.redWin;
      if (ctx.whiteIppon > ctx.redIppon) return MatchResultStatus.whiteWin;
      
      // ★ Phase 7-1: 時間切れ・同点の場合、判定(Hantei)があるなら「引き分け」にせず入力待ちを継続
      if (ctx.hasHantei) {
        return MatchResultStatus.inProgress;
      }
      return MatchResultStatus.draw;
    }
    return MatchResultStatus.inProgress;
  }

  /// 3. 反則が一本に到達したかの判定
  bool isHansokuIppon(int count) => count > 0 && count % 2 == 0;

  /// 4. 延長突入判定
  bool shouldEnterEncho(MatchContext ctx, bool allowsEncho) {
    return ctx.isTimeUp && 
           ctx.redIppon == ctx.whiteIppon && 
           allowsEncho && 
           decideResult(ctx) == MatchResultStatus.draw;
  }

  /// 5. 入力バリデーション
  ValidationResult validateEvent(MatchModel match, ScoreEvent event, MatchContext ctx) {
    if (match.events.any((e) => e.id == event.id)) {
      return ValidationResult(false, '重複入力です。');
    }
    if (match.status == 'finished' || match.status == 'approved') {
      return ValidationResult(false, '試合は既に終了しています。');
    }
    if (event.type != PointType.undo && event.type != PointType.hansoku) {
      if (ctx.redIppon >= ctx.targetIppon || ctx.whiteIppon >= ctx.targetIppon) {
        return ValidationResult(false, '既に規定本数に達しています。');
      }
    }
    return ValidationResult(true);
  }

  // --- 内部ヘルパー ---

  List<ScoreEvent> _filterActiveEvents(List<ScoreEvent> events) {
    List<ScoreEvent> active = [];
    for (var e in events) {
      // ★ Phase 4: キャンセル済みのイベントは歴史には残るが、計算からは完全に無視する
      if (e.isCanceled) continue; 
      
      // （※過去の互換性のために PointType.undo のロジックも残しておきます）
      if (e.type == PointType.undo) {
        if (active.isNotEmpty) active.removeLast();
      } else {
        active.add(e);
      }
    }
    return active;
  }

  String? _getPointMark(PointType type) {
    switch (type) {
      case PointType.men: return 'メ';
      case PointType.kote: return 'コ';
      case PointType.doIdo: return 'ド';
      case PointType.tsuki: return 'ツ';
      case PointType.fusen: return '◯';
      case PointType.hantei: return '判定';
      default: return null;
    }
  }

  /// ==========================================
  /// ★ Step 5-4: グループ（団体戦・勝ち抜き戦）全体の状況を解析
  /// ==========================================
  GroupMatchStatus analyzeGroupStatus({
    required MatchModel currentMatch,
    required List<MatchModel> groupMatches,
    required MatchRule? rule,
    Map<String, dynamic>? lastSettings,
  }) {
    if (currentMatch.isKachinuki) {
      return _analyzeKachinukiStatus(currentMatch, rule, lastSettings);
    }
    
    // 個人戦、または単発の試合の場合
    if (groupMatches.length <= 1) {
      return GroupMatchStatus(
        isAllDone: currentMatch.status == 'finished' || currentMatch.status == 'approved'
      );
    }

    // 通常団体戦の集計
    return _analyzeTeamMatchStatus(groupMatches, rule);
  }

  // --- 内部ロジックの集約 ---

  GroupMatchStatus _analyzeTeamMatchStatus(List<MatchModel> matches, MatchRule? rule) {
    bool isAllDone = matches.every((m) => m.status == 'finished' || m.status == 'approved');
    bool hasDaihyo = matches.any((m) => m.matchType == '代表戦');
    
    if (isAllDone && !hasDaihyo) {
      int rWins = 0, wWins = 0, rPts = 0, wPts = 0;
      for (var m in matches) {
        rPts += m.redScore;
        wPts += m.whiteScore;
        if (m.redScore > m.whiteScore) {
          rWins++;
        } else if (m.whiteScore > m.redScore) {
          wWins++;
        }
      }
      // 勝数・本数ともに同点の場合のみ「代表戦（タイ）」と判定
      if (rWins == wWins && rPts == wPts) {
        return GroupMatchStatus(isAllDone: true, isTie: true);
      }
    }
    return GroupMatchStatus(isAllDone: isAllDone, isTie: false);
  }

  GroupMatchStatus _analyzeKachinukiStatus(MatchModel currentMatch, MatchRule? rule, Map<String, dynamic>? lastSettings) {
    // 勝ち抜き戦はスコアが異なる（現在の試合の決着がチームの決着に直結する可能性がある）
    bool isTie = false;
    bool isAllDone = false;

    if (currentMatch.redScore == currentMatch.whiteScore) {
      final bool isTaishoVsTaisho = currentMatch.redRemaining.isEmpty && currentMatch.whiteRemaining.isEmpty;
      if (isTaishoVsTaisho) {
        // 大将同士が同点の場合のルール判定
        String kType = rule?.kachinukiUnlimitedType ?? '';
        int maxExt = lastSettings?['extensionCount'] ?? -2;
        int currentExt = '延長'.allMatches(currentMatch.note).length;
        
        bool canExtend = kType == '大将引き分け延長' && (maxExt == -2 || maxExt == -1 || currentExt < maxExt);
        if (canExtend && currentMatch.matchType != '大将延長戦' && currentMatch.status != 'finished') {
          isAllDone = false;
        } else {
          isAllDone = true;
          isTie = true;
        }
      } else {
        isAllDone = (currentMatch.redRemaining.isEmpty || currentMatch.whiteRemaining.isEmpty);
      }
    } else {
      // どちらかが勝った場合、負けた方のチームに控えがいなければ終了
      isAllDone = (currentMatch.redScore > currentMatch.whiteScore) 
          ? currentMatch.whiteRemaining.isEmpty 
          : currentMatch.redRemaining.isEmpty;
    }

    return GroupMatchStatus(isAllDone: isAllDone, isTie: isTie);
  }
}