// ★ 修正：match_model.dart は models/ フォルダにあるのが正解でした。
import 'package:kendo_os/models/match_model.dart'; 
import 'package:kendo_os/domain/match/score_event.dart';
import 'package:kendo_os/domain/match/match_rule.dart';
import 'package:kendo_os/domain/match/match_context.dart';
import 'package:kendo_os/domain/strategy/match_strategy.dart';
import 'package:kendo_os/domain/match/rules/rule_factory.dart'; // ★ 新規追加

// ★ 追加: 新しく切り出した集計ロジックを読み込み、外部(UI)へ横流しする
import 'package:kendo_os/domain/tournament/standings_calculator.dart';
export 'package:kendo_os/domain/tournament/standings_calculator.dart' show LeagueTeamStat;

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

// ★ MatchResultStatus と MatchContext は lib/domain/match/match_context.dart へ独立・純化しました

/// ==========================================
/// ★ 剣道ルールエンジンの完成形 (SSOT)
/// すべての「計算」「判定」をこのクラスに集約する
/// ==========================================
class KendoRuleEngine {
  // ★ Phase 6: RuleFactoryを使って、設定(MatchRule)から動的にルールセットを取得
  MatchRuleSet _getRuleSet(MatchRule? rule) => RuleFactory.fromConfig(rule);
  
  /// 1. 歴史（Events）から現在の状況をすべて解析する最重要メソッド
  MatchAnalysis analyzeHistory(List<ScoreEvent> allEvents, MatchModel match, MatchRule? rule) {
    // ★ 毎回、最新の設定(rule)に基づいて最適なルールセットを工場から調達する
    final ruleSet = _getRuleSet(rule);

    // A. 有効なイベントのみを抽出 (Undoの解決)
    final activeEvents = _filterActiveEvents(allEvents);

    // B. 初期状態の作成 (スコア0, 反則0)
    final strategy = MatchStrategyFactory.getStrategy(match);
    final target = strategy.getTargetIppon(match, rule);
    final finalTarget = (match.matchType == '延長戦' || match.matchType == '代表戦') ? 1 : target;
    
    final hasHantei = rule?.hasHantei ?? false;
    
    MatchContext currentContext = MatchContext(
      redIppon: 0, whiteIppon: 0,
      redHansoku: 0, whiteHansoku: 0,
      isTimeUp: false,
      targetIppon: finalTarget,
      hasHantei: hasHantei,
    );

    // C. ★ Phase 6: パイプライン処理 (動的に生成されたRuleSetを適用)
    currentContext = ruleSet.scoring.apply(activeEvents, currentContext);
    currentContext = ruleSet.hansoku.apply(activeEvents, currentContext);
    currentContext = ruleSet.time.apply(currentContext, 1.0);

    // D. 表示用データの構築（UIのための計算）
    final displays = _buildDisplays(activeEvents, currentContext);

    return MatchAnalysis(
      context: currentContext,
      displays: displays,
    );
  }

  /// 2. 勝敗の決定ロジック (動的生成されたVictoryRuleに委譲)
  MatchResultStatus decideResult(MatchContext ctx, [MatchRule? rule]) {
    return _getRuleSet(rule).victory.evaluate(ctx, 0, 0); 
  }

  /// 3. 反則が一本に到達したかの判定
  bool isHansokuIppon(int count) => count > 0 && count % 2 == 0;

  /// 4. 延長突入判定
  bool shouldEnterEncho(MatchContext ctx, bool allowsEncho, [MatchRule? rule]) {
    return ctx.isTimeUp && 
           ctx.redIppon == ctx.whiteIppon && 
           allowsEncho && 
           decideResult(ctx, rule) == MatchResultStatus.draw;
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
      if (e.isCanceled) continue; 
      if (e.type == PointType.undo) {
        if (active.isNotEmpty) active.removeLast();
      } else {
        active.add(e);
      }
    }
    return active;
  }

  // UI用のDisplay構築ロジック（既存の表示互換を維持）
  Map<Side, List<PointDisplay>> _buildDisplays(List<ScoreEvent> activeEvents, MatchContext finalContext) {
    List<PointDisplay> redDisplays = [];
    List<PointDisplay> whiteDisplays = [];
    bool isFirstOfMatch = true;
    int rHansoku = 0, wHansoku = 0;

    for (var e in activeEvents) {
      if (e.type == PointType.hansoku) {
        if (e.side == Side.red) {
          rHansoku++;
          if (isHansokuIppon(rHansoku)) {
            whiteDisplays.add(PointDisplay('反', isFirstOfMatch));
            isFirstOfMatch = false;
          }
        } else if (e.side == Side.white) {
          wHansoku++;
          if (isHansokuIppon(wHansoku)) {
            redDisplays.add(PointDisplay('反', isFirstOfMatch));
            isFirstOfMatch = false;
          }
        }
      } else if (e.type == PointType.fusen) {
        if (e.side == Side.red) {
          redDisplays.add(PointDisplay('◯', isFirstOfMatch));
          redDisplays.add(PointDisplay('◯', false));
        } else if (e.side == Side.white) {
          whiteDisplays.add(PointDisplay('◯', isFirstOfMatch));
          whiteDisplays.add(PointDisplay('◯', false));
        }
        isFirstOfMatch = false;
      } else {
        final mark = _getPointMark(e.type);
        if (mark != null) {
          if (e.side == Side.red) {
            redDisplays.add(PointDisplay(mark, isFirstOfMatch));
          } else if (e.side == Side.white) {
            whiteDisplays.add(PointDisplay(mark, isFirstOfMatch));
          }
          isFirstOfMatch = false;
        }
      }
    }
    return {Side.red: redDisplays, Side.white: whiteDisplays};
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
    
    if (groupMatches.length <= 1) {
      return GroupMatchStatus(
        isAllDone: currentMatch.status == 'finished' || currentMatch.status == 'approved'
      );
    }

    return _analyzeTeamMatchStatus(groupMatches, rule);
  }

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
      if (rWins == wWins && rPts == wPts) {
        return GroupMatchStatus(isAllDone: true, isTie: true);
      }
    }
    return GroupMatchStatus(isAllDone: isAllDone, isTie: false);
  }

  GroupMatchStatus _analyzeKachinukiStatus(MatchModel currentMatch, MatchRule? rule, Map<String, dynamic>? lastSettings) {
    bool isTie = false;
    bool isAllDone = false;

    if (currentMatch.redScore == currentMatch.whiteScore) {
      final bool isTaishoVsTaisho = currentMatch.redRemaining.isEmpty && currentMatch.whiteRemaining.isEmpty;
      if (isTaishoVsTaisho) {
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
      isAllDone = (currentMatch.redScore > currentMatch.whiteScore) 
          ? currentMatch.whiteRemaining.isEmpty 
          : currentMatch.redRemaining.isEmpty;
    }

    return GroupMatchStatus(isAllDone: isAllDone, isTie: isTie);
  }

  // ★ Phase 6: 順位算出ロジックを専用の StandingsCalculator に移譲
  static List<LeagueTeamStat> calculateLeagueStandings(List<MatchModel> matches, MatchRule rule) {
    return LeagueStandingsCalculator().calculate(matches, rule);
  }
}