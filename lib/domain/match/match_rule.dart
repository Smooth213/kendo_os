import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_rule.freezed.dart';
part 'match_rule.g.dart';

// ★ 修正: MatchRule自体は内部に別のモデルを持たないので、通常の @freezed だけでOKです
@freezed
abstract class MatchRule with _$MatchRule {
  const factory MatchRule({
    @Default(['選手']) List<String> positions,
    @Default(3.0) double matchTimeMinutes, // ★ 修正：1.5分などの小数に対応するため double に変更
    @Default(false) bool isRunningTime,
    @Default(false) bool isLeague,
    @Default('') String category,
    @Default('') String note,
    @Default(false) bool isRenseikai,
    @Default([]) List<String> baseOrder,
    @Default('') String teamName,
    @Default(false) bool isKachinuki,
    @Default('大将対大将') String kachinukiUnlimitedType,
    @Default(false) bool hasLeagueDaihyo,
    @Default('一試合制') String renseikaiType,
    @Default(30) int overallTimeMinutes,
    @Default(true) bool isDaihyoIpponShobu,
    @Default(true) bool hasRepresentativeMatch,
    @Default(false) bool isEnchoUnlimited, // ★ 修正：デフォルトを「無制限ではない（回数指定）」に変更
    @Default(3.0) double enchoTimeMinutes, // ★ 修正：小数を許容する
    @Default(1) int enchoCount, // ★ 追加：延長回数を記憶する引き出し
    @Default(false) bool hasHantei,
    @Default([]) List<String> leagueOrder,
    @Default(0.0) double winPoint,
    @Default(0.0) double lossPoint,
    @Default(0.0) double drawPoint,
  }) = _MatchRule;

  factory MatchRule.fromJson(Map<String, dynamic> json) => _$MatchRuleFromJson(json);
}