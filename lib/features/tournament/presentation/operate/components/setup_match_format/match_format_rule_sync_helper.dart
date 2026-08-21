import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';

/// 試合形式設定画面のカテゴリールール連動・シーン選択ヘルパー
class MatchFormatRuleSyncHelper {
  /// 試合名から上位戦（準決勝・決勝等）判定
  static bool isAdvancedMatchName({
    required String note,
    required String categoryName,
    required TournamentModel? tournament,
  }) {
    List<String>? customKeywords;
    if (tournament != null) {
      final ruleSet = tournament.categoryRules[categoryName];
      if (ruleSet != null && ruleSet.advancedKeywords.isNotEmpty) {
        customKeywords = ruleSet.advancedKeywords;
      }
    }

    return CategoryRuleMatchHelper.isAdvancedMatchName(
      note,
      customKeywords: customKeywords,
    );
  }

  /// カテゴリールール設定から初期シーンを決定
  static String determineInitialScene({
    required CategoryRuleSet ruleSet,
    required String currentScene,
    required bool isAdvanced,
  }) {
    String targetScene = currentScene;
    if (!ruleSet.useHonsenRule && targetScene == 'honsen') {
      targetScene = ruleSet.useRenseikaiRule
          ? 'renseikai'
          : (ruleSet.useMoushiawaseRule ? 'moushiawase' : 'honsen');
    }
    if (targetScene == 'honsen' && isAdvanced && ruleSet.useAdvancedRule) {
      targetScene = 'advanced';
    }
    return targetScene;
  }

  /// シーンに応じた MatchRule を取得
  static MatchRule getRuleForScene({
    required String scene,
    required CategoryRuleSet ruleSet,
  }) {
    switch (scene) {
      case 'renseikai':
        return ruleSet.renseikaiRule;
      case 'moushiawase':
        return ruleSet.moushiawaseRule;
      case 'advanced':
        return ruleSet.advancedRule;
      case 'honsen':
      default:
        return ruleSet.normalRule;
    }
  }
}
