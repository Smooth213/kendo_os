import 'package:kendo_os/domain/entities/match_model.dart'; 
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/entities/match_context.dart';
import 'package:kendo_os/domain/services/match_strategy.dart';
import 'package:kendo_os/domain/rules/rule_factory.dart';
import 'package:kendo_os/domain/rules/tournament_rule_config.dart'; // ★ Phase 5

// ★ 追加: 新しく切り出した集計ロジックを読み込み、外部(UI)へ横流しする
import 'package:kendo_os/domain/services/standings_calculator.dart';
export 'standings_calculator.dart' show LeagueTeamStat;

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
  // ★ Phase 5: アダプター(toRuleConfig)経由で階層型ConfigとしてResolverを呼び出す
  MatchRuleSet _getRuleSet(TournamentRuleConfig config) => RuleResolver.build(config);
  
  /// 1. 歴史（Events）から現在の状況をすべて解析する最重要メソッド
  MatchAnalysis analyzeHistory(List<ScoreEvent> allEvents, MatchModel match, MatchRule? rule) {
    final safeRule = rule ?? const MatchRule();
    final config = safeRule.toRuleConfig; // ★ 新Configへ変換
    final ruleSet = _getRuleSet(config);

    final activeEvents = _filterActiveEvents(allEvents);

    final strategy = MatchStrategyFactory.getStrategy(match);
    int target = strategy.getTargetIppon(match, rule);

    // ★ 階層型Configの使用に書き換え
    if (config.scoring.isIpponShobu) {
      target = 1;
    } else if (config.scoring.ipponLimit != 2 && config.scoring.ipponLimit > 0) {
      target = config.scoring.ipponLimit;
    }

    final hasHantei = config.draw.hasHantei; // ★ 階層型Config
    
    MatchContext currentContext = MatchContext(
      redIppon: 0, whiteIppon: 0,
      redHansoku: 0, whiteHansoku: 0,
      isTimeUp: false,
      targetIppon: target, 
      hasHantei: hasHantei,
    );

    // 1. Scoring Rule 適用
    var ruleCtx = RuleContext(matchState: currentContext, events: activeEvents, tournamentConfig: config, clock: match.remainingSeconds.toDouble());
    var res = ruleSet.scoring.apply(ruleCtx);
    if (res.transition != null) currentContext = res.transition!.updatedState;

    // 2. Hansoku Rule 適用
    ruleCtx = RuleContext(matchState: currentContext, events: activeEvents, tournamentConfig: config, clock: match.remainingSeconds.toDouble());
    res = ruleSet.hansoku.apply(ruleCtx);
    if (res.transition != null) currentContext = res.transition!.updatedState;
    
    // 延長戦・代表戦（サドンデス）の規定本数を事後計算で補正
    if (match.matchType == '延長戦' || match.matchType == '代表戦') {
      int minScore = currentContext.redIppon < currentContext.whiteIppon 
          ? currentContext.redIppon 
          : currentContext.whiteIppon;
      currentContext = MatchContext(
        redIppon: currentContext.redIppon,
        whiteIppon: currentContext.whiteIppon,
        redHansoku: currentContext.redHansoku,
        whiteHansoku: currentContext.whiteHansoku,
        isTimeUp: currentContext.isTimeUp,
        targetIppon: minScore + 1,
        hasHantei: currentContext.hasHantei,
      );
    }

    // 3. Time Rule 適用
    ruleCtx = RuleContext(matchState: currentContext, events: activeEvents, tournamentConfig: config, clock: match.remainingSeconds.toDouble());
    res = ruleSet.time.apply(ruleCtx);
    if (res.transition != null) currentContext = res.transition!.updatedState;

    final displays = _buildDisplays(activeEvents, currentContext);

    return MatchAnalysis(
      context: currentContext,
      displays: displays,
    );
  }

  /// 2. 勝敗の決定ロジック (動的生成されたVictoryRuleに委譲)
  MatchResultStatus decideResult(MatchContext ctx, [MatchRule? rule]) {
    final safeRule = rule ?? const MatchRule();
    final config = safeRule.toRuleConfig;
    final ruleCtx = RuleContext(matchState: ctx, events: [], tournamentConfig: config, clock: 0);
    final res = _getRuleSet(config).victory.apply(ruleCtx);
    return res.transition?.resultStatus ?? MatchResultStatus.inProgress;
  }

  /// 3. 反則が一本に到達したかの判定
  bool isHansokuIppon(int count, [MatchRule? rule]) {
    final limit = (rule ?? const MatchRule()).toRuleConfig.hansoku.hansokuLimit;
    return limit > 0 && count > 0 && count % limit == 0;
  }

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
    
    // ★ Phase 2: Undoイベント専用のバリデーション（空の時にUndoさせない）
    if (event.isUndo || event.type == PointType.undo) {
      final activeEvents = _filterActiveEvents(match.events);
      if (activeEvents.isEmpty) {
        return ValidationResult(false, '取り消すイベントがありません。');
      }
      return ValidationResult(true); // Undoは試合終了後でも可能なためここで許可
    }
    
    // ★ Phase 2-3: Redoイベント専用のバリデーション
    if (event.isRestore || event.type == PointType.restore) {
      return ValidationResult(true); // Redoも試合終了後でも許可 (無効な場合はReducerが安全に無視する)
    }

    final bool isHanteiEvent = event.isHantei || event.type == PointType.hantei;
    
    if (match.status == 'finished' || match.status == 'approved') {
      if (!event.isUndo && !isHanteiEvent) {
        return ValidationResult(false, '試合は既に終了しています。');
      }
    }
    if (!event.isUndo && !event.isHansoku && !isHanteiEvent) {
      if (ctx.redIppon >= ctx.targetIppon || ctx.whiteIppon >= ctx.targetIppon) {
        return ValidationResult(false, '既に規定本数に達しています。');
      }
    }
    return ValidationResult(true);
  }

  // ★ Phase 5: Undoされたイベントをフィルタし、現在有効なイベントのみを返す（外部公開版）
  List<ScoreEvent> filterActiveEvents(List<ScoreEvent> events) {
    return _filterActiveEvents(events);
  }

  // --- 内部ヘルパー ---

  // ★ Phase 3 & Phase 2-5: Append-only対応の完全版Reducer
  // isCanceledを直接書き換えるMutationを廃止し、targetIdによる相殺(Compensation)を行う。
  // 古いデータとの後方互換性も完全に維持。
  List<ScoreEvent> _filterActiveEvents(List<ScoreEvent> events) {
    List<ScoreEvent> active = [];
    List<ScoreEvent> undone = []; 
    int pendingUndoCount = 0; 

    for (var e in events) {
      // 1. レガシー対応: 過去のバージョンで直接 isCanceled=true にされたイベント
      if (e.isCanceled) {
        pendingUndoCount++;
        continue; 
      }
      
      // 2. 取り刺し（Undo）イベントの処理
      if (e.isUndo || e.type == PointType.undo) {
        if (e.targetId.isNotEmpty) {
           // ★ 新アーキテクチャ: targetId に一致するイベントを active から消し、undone に退避
           final targetIndex = active.indexWhere((ev) => ev.id == e.targetId);
           if (targetIndex != -1) {
             undone.add(active.removeAt(targetIndex));
           }
        } else {
           // ★ レガシー対応: targetId が無い昔のUndoイベントの場合
           if (pendingUndoCount > 0) {
             pendingUndoCount--;
             continue; // すでに上の isCanceled=true で消えているはずなので無視
           }
           if (active.isNotEmpty) {
             undone.add(active.removeLast());
           }
        }
      } 
      // 3. やり直し（Redo / Restore）イベントの処理
      else if (e.isRestore || e.type == PointType.restore) {
        if (e.targetId.isNotEmpty) {
           final targetIndex = undone.indexWhere((ev) => ev.id == e.targetId);
           if (targetIndex != -1) {
             active.add(undone.removeAt(targetIndex));
           }
        } else {
           if (undone.isNotEmpty) {
             active.add(undone.removeLast());
           }
        }
      } 
      // 4. 通常の打突・反則・判定イベントの処理
      else {
        active.add(e);
        undone.clear(); // 新しいイベントが入ったら、過去のRedo(やり直し)の権利は消滅する
      }
    }
    return active;
  }

  Map<Side, List<PointDisplay>> _buildDisplays(List<ScoreEvent> activeEvents, MatchContext finalContext) {
    List<PointDisplay> redDisplays = [];
    List<PointDisplay> whiteDisplays = [];
    bool isFirstOfMatch = true;
    int rHansoku = 0, wHansoku = 0;

    for (var e in activeEvents) {
      if (e.isHansoku) {
        if (e.side == Side.red) {
          rHansoku++;
          if (isHansokuIppon(rHansoku)) { // ※本当はruleを渡したいがUI表示上の互換維持のため一旦そのまま
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
      } else if (e.isFusen) {
        if (e.side == Side.red) {
          redDisplays.add(PointDisplay('◯', isFirstOfMatch));
          redDisplays.add(PointDisplay('◯', false));
        } else if (e.side == Side.white) {
          whiteDisplays.add(PointDisplay('◯', isFirstOfMatch));
          whiteDisplays.add(PointDisplay('◯', false));
        }
        isFirstOfMatch = false;
      } else {
        final mark = _getPointMark(e);
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

  String? _getPointMark(ScoreEvent event) {
    if (event.isHantei) return '判定';
    if (event.isFusen) return '◯';
    switch (event.strikeType) {
      case StrikeType.men: return 'メ';
      case StrikeType.kote: return 'コ';
      case StrikeType.dou: return 'ド';
      case StrikeType.tsuki: return 'ツ';
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

  static List<LeagueTeamStat> calculateLeagueStandings(List<MatchModel> matches, MatchRule rule) {
    return LeagueStandingsCalculator().calculate(matches, rule);
  }
}