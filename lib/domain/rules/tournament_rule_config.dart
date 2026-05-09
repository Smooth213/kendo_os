import 'package:freezed_annotation/freezed_annotation.dart';

part 'tournament_rule_config.freezed.dart';
part 'tournament_rule_config.g.dart';

// ==========================================
// ★ Phase 5: TournamentRuleConfig導入
// ==========================================

@freezed
abstract class TimeConfig with _$TimeConfig {
  const factory TimeConfig({
    @Default(3.0) double matchTimeMinutes,
    @Default(false) bool isRunningTime,
  }) = _TimeConfig;
  factory TimeConfig.fromJson(Map<String, dynamic> json) => _$TimeConfigFromJson(json);
}

@freezed
abstract class EnchoConfig with _$EnchoConfig {
  const factory EnchoConfig({
    @Default(false) bool isEnchoUnlimited,
    @Default(3.0) double enchoTimeMinutes,
    @Default(1) int enchoCount,
  }) = _EnchoConfig;
  factory EnchoConfig.fromJson(Map<String, dynamic> json) => _$EnchoConfigFromJson(json);
}

@freezed
abstract class ScoringConfig with _$ScoringConfig {
  const factory ScoringConfig({
    @Default(2) int ipponLimit,
    @Default(false) bool isIpponShobu,
  }) = _ScoringConfig;
  factory ScoringConfig.fromJson(Map<String, dynamic> json) => _$ScoringConfigFromJson(json);
}

@freezed
abstract class HansokuConfig with _$HansokuConfig {
  const factory HansokuConfig({
    @Default(2) int hansokuLimit,
  }) = _HansokuConfig;
  factory HansokuConfig.fromJson(Map<String, dynamic> json) => _$HansokuConfigFromJson(json);
}

@freezed
abstract class TeamConfig with _$TeamConfig {
  const factory TeamConfig({
    @Default(false) bool isKachinuki,
    @Default('大将対大将') String kachinukiUnlimitedType,
    @Default(true) bool hasRepresentativeMatch,
    @Default(true) bool isDaihyoIpponShobu,
  }) = _TeamConfig;
  factory TeamConfig.fromJson(Map<String, dynamic> json) => _$TeamConfigFromJson(json);
}

@freezed
abstract class DrawConfig with _$DrawConfig {
  const factory DrawConfig({
    @Default(false) bool hasHantei,
  }) = _DrawConfig;
  factory DrawConfig.fromJson(Map<String, dynamic> json) => _$DrawConfigFromJson(json);
}

/// 大会ルールの総本山 (Root Config)
@freezed
abstract class TournamentRuleConfig with _$TournamentRuleConfig {
  const factory TournamentRuleConfig({
    @Default(1) int schemaVersion, // ★ 5-4: Versioning
    @Default(TimeConfig()) TimeConfig time,
    @Default(EnchoConfig()) EnchoConfig encho,
    @Default(ScoringConfig()) ScoringConfig scoring,
    @Default(HansokuConfig()) HansokuConfig hansoku,
    @Default(TeamConfig()) TeamConfig team,
    @Default(DrawConfig()) DrawConfig draw,
  }) = _TournamentRuleConfig;
  factory TournamentRuleConfig.fromJson(Map<String, dynamic> json) => _$TournamentRuleConfigFromJson(json);
}