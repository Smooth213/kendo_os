import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

part 'category_rule_set.freezed.dart';
part 'category_rule_set.g.dart';

@freezed
abstract class CategoryRuleSet with _$CategoryRuleSet {
  const factory CategoryRuleSet({
    @Default(MatchRule()) MatchRule normalRule,
    @Default(MatchRule()) MatchRule advancedRule,
    @Default(false) bool useAdvancedRule,
    @Default(['準決勝', '準決', '決勝', 'final', '3位決定', '3決', 'ベスト4'])
    List<String> advancedKeywords,
    @Default('個人戦') String matchType,
    @Default(false) bool isMultiScene,
    @Default(true) bool useHonsenRule,
    @Default(true) bool useRenseikaiRule,
    @Default(true) bool useMoushiawaseRule,
    @Default(
      MatchRule(
        matchTimeMinutes: 2,
        isRunningTime: true,
        hasHantei: true,
        enchoCount: 0,
        isEnchoUnlimited: false,
        isRenseikai: true,
        matchScene: 'renseikai',
      ),
    )
    MatchRule renseikaiRule,
    @Default(
      MatchRule(
        matchTimeMinutes: 2,
        isRunningTime: true,
        hasHantei: true,
        enchoCount: 0,
        isEnchoUnlimited: false,
        isRenseikai: true,
        matchScene: 'moushiawase',
      ),
    )
    MatchRule moushiawaseRule,
  }) = _CategoryRuleSet;

  factory CategoryRuleSet.fromJson(Map<String, dynamic> json) =>
      _$CategoryRuleSetFromJson(json);
}
