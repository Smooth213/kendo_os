import '../../models/match_model.dart';
import '../../models/match_rule.dart';
import '../kendo_rule_engine.dart';

// グループ（チーム戦・勝ち抜き戦）全体が終了したかどうかの結果をまとめるクラス
class GroupMatchStatus {
  final bool isAllDone;
  final bool isTie;
  GroupMatchStatus({required this.isAllDone, this.isTie = false});
}

// ★ フェーズ1 追加：試合終了時に次に何をすべきかを示す列挙型（アクションの選択肢）
enum NextMatchAction { continueMatch, startExtension, showHantei, finishMatch, goToDaihyosen }

// ★ すべての試合形式が必ず持つべき「戦略（ルール）」の設計図
abstract class MatchStrategy {
  // 試合単体の先取本数（基本2本、代表戦・延長は1本など）
  int getTargetIppon(MatchModel match, MatchRule? rule);
  
  // ★ フェーズ1 追加：同点時の次のアクションを決定するロジック
  NextMatchAction getNextActionOnTie({
    required MatchModel match,
    required Map<String, dynamic>? lastSettings,
  });
  
  // チーム全体（グループ）としての対戦が終了したか、同点かの判定
  GroupMatchStatus checkGroupStatus({
    required MatchModel currentMatch,
    required List<MatchModel> groupMatches,
    required int currentRedPoints,
    required int currentWhitePoints,
    required MatchRule? rule,
    Map<String, dynamic>? lastSettings, 
  });
}

// ==========================================
// 1. 通常の個人戦・基本マッチ用戦略
// ==========================================
class IndividualMatchStrategy implements MatchStrategy {
  @override
  int getTargetIppon(MatchModel match, MatchRule? rule) {
    if (match.note.contains('延長')) return 1;
    return 2;
  }

  @override
  NextMatchAction getNextActionOnTie({required MatchModel match, required Map<String, dynamic>? lastSettings}) {
    final bool hasExt = lastSettings?['hasExtension'] ?? true; 
    final int maxExt = lastSettings?['extensionCount'] ?? 1; 
    int currentExtCount = '延長'.allMatches(match.note).length;

    if (hasExt && (maxExt == -2 || maxExt == -1 || currentExtCount < maxExt)) {
      return NextMatchAction.startExtension;
    }
    
    if ((lastSettings?['hasHantei'] ?? true) || match.matchType.contains('個人戦')) {
      return NextMatchAction.showHantei;
    }
    
    return NextMatchAction.finishMatch;
  }

  @override
  GroupMatchStatus checkGroupStatus({
    required MatchModel currentMatch,
    required List<MatchModel> groupMatches,
    required int currentRedPoints,
    required int currentWhitePoints,
    required MatchRule? rule,
    Map<String, dynamic>? lastSettings,
  }) {
    // ★ Step 5-4: 独自の計算を廃止し、KendoRuleEngine に集約されたロジックを呼び出す
    return KendoRuleEngine().analyzeGroupStatus(
      currentMatch: currentMatch,
      groupMatches: groupMatches,
      rule: rule,
      lastSettings: lastSettings,
    );
  }
}

// ==========================================
// 2. 通常団体戦（星取り戦）用戦略
// ==========================================
class TeamMatchStrategy implements MatchStrategy {
  @override
  int getTargetIppon(MatchModel match, MatchRule? rule) {
    bool isDaihyoIppon = rule?.isDaihyoIpponShobu ?? false;
    
    if (match.matchType == '代表戦' && isDaihyoIppon) {
      return 1;
    }
    if (match.matchType == '代表戦' || match.matchType == '大将延長戦') {
      return 1; 
    }
    return 2;
  }

  @override
  NextMatchAction getNextActionOnTie({required MatchModel match, required Map<String, dynamic>? lastSettings}) {
    if (match.matchType == '代表戦') {
      final bool hasExt = lastSettings?['hasExtension'] ?? true;
      final int maxExt = lastSettings?['extensionCount'] ?? 1;
      final int currentExtCount = '延長'.allMatches(match.note).length;
      
      if (hasExt && (maxExt == -2 || maxExt == -1 || currentExtCount < maxExt)) {
        return NextMatchAction.startExtension;
      }
      return (lastSettings?['hasHantei'] ?? true) ? NextMatchAction.showHantei : NextMatchAction.finishMatch;
    }
    return NextMatchAction.finishMatch;
  }

  @override
  GroupMatchStatus checkGroupStatus({
    required MatchModel currentMatch,
    required List<MatchModel> groupMatches,
    required int currentRedPoints,
    required int currentWhitePoints,
    required MatchRule? rule,
    Map<String, dynamic>? lastSettings,
  }) {
    // ★ Step 5-4: 独自の計算を廃止し、KendoRuleEngine に集約されたロジックを呼び出す
    return KendoRuleEngine().analyzeGroupStatus(
      currentMatch: currentMatch,
      groupMatches: groupMatches,
      rule: rule,
      lastSettings: lastSettings,
    );
  }
}

// ==========================================
// 3. 勝ち抜き戦用戦略
// ==========================================
class KachinukiStrategy implements MatchStrategy {
  @override
  int getTargetIppon(MatchModel match, MatchRule? rule) {
    if (match.matchType == '大将延長戦' || match.note.contains('延長')) return 1;
    return 2;
  }

  @override
  NextMatchAction getNextActionOnTie({required MatchModel match, required Map<String, dynamic>? lastSettings}) {
    final bool isTaishoVsTaisho = match.redRemaining.isEmpty && match.whiteRemaining.isEmpty;
    final String kType = lastSettings?['kachinukiUnlimitedType'] ?? '';

    if (isTaishoVsTaisho && kType == '大将引き分け延長') {
      final bool hasExt = lastSettings?['hasExtension'] ?? true;
      final int maxExt = lastSettings?['extensionCount'] ?? 1;
      final int currentExtCount = '延長'.allMatches(match.note).length;

      if (hasExt && (maxExt == -2 || maxExt == -1 || currentExtCount < maxExt)) {
        return NextMatchAction.startExtension;
      }
      return (lastSettings?['hasHantei'] ?? true) ? NextMatchAction.showHantei : NextMatchAction.finishMatch;
    }
    return NextMatchAction.finishMatch;
  }

  @override
  GroupMatchStatus checkGroupStatus({
    required MatchModel currentMatch,
    required List<MatchModel> groupMatches,
    required int currentRedPoints,
    required int currentWhitePoints,
    required MatchRule? rule,
    Map<String, dynamic>? lastSettings,
  }) {
    // ★ Step 5-4: 独自の計算を廃止し、KendoRuleEngine に集約されたロジックを呼び出す
    return KendoRuleEngine().analyzeGroupStatus(
      currentMatch: currentMatch,
      groupMatches: groupMatches,
      rule: rule,
      lastSettings: lastSettings,
    );
  }
}

// ==========================================
// ★ 戦略ファクトリ
// ==========================================
class MatchStrategyFactory {
  static MatchStrategy getStrategy(MatchModel match, [int groupSize = 0]) {
    if (match.isKachinuki) return KachinukiStrategy();
    
    if (match.matchType.contains('個人戦') || 
        match.matchType.contains('リーグ戦') || 
        match.matchType.contains('錬成会') || 
        groupSize == 1) {
      return IndividualMatchStrategy();
    }

    if (match.groupName != null && match.groupName!.isNotEmpty) {
      return TeamMatchStrategy();
    }
    
    return IndividualMatchStrategy();
  }
}