import 'package:kendo_os/domain/rules/tournament_rule_config.dart';

// ==========================================
// ★ Phase 8: Runtime Rule Validation
// ドメイン層でルールの矛盾や無効な設定を弾く堅牢なバリデーター
// ==========================================
class RuleConfigValidator {
  static List<String> validate(TournamentRuleConfig config) {
    final errors = <String>[];

    // 8-3: Semantic Validation (意味的矛盾の排除)
    if (config.time.matchTimeMinutes <= 0) {
      errors.add('試合時間は0分より大きい必要があります。');
    }

    if ((config.encho.isEnchoUnlimited || config.encho.enchoCount > 0) && config.encho.enchoTimeMinutes <= 0) {
      errors.add('延長戦を行う場合、延長時間は0分より大きい必要があります。');
    }

    if (config.scoring.ipponLimit <= 0 && !config.scoring.isIpponShobu) {
      errors.add('規定本数は1本以上である必要があります。');
    }

    if (config.hansoku.hansokuLimit < 0) {
      errors.add('反則回数の上限は0以上である必要があります。');
    }

    // 8-2: Dependency Validation (依存関係の矛盾の排除)
    if (config.team.isKachinuki && config.team.kachinukiUnlimitedType == '大将引き分け延長') {
      if (!config.encho.isEnchoUnlimited && config.encho.enchoCount == 0 && !config.draw.hasHantei) {
        errors.add('勝ち抜き戦(大将延長)が有効ですが、延長ルールまたは判定が設定されていません。');
      }
    }

    return errors;
  }
}