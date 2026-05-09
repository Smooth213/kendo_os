import 'package:kendo_os/domain/rules/tournament_rule_config.dart';

// ==========================================
// ★ Phase 6: Preset System
// プリセットは「ルールそのもの」ではなく、
// TournamentRuleConfig の初期値を生成するための単なる「ひな形（テンプレート）」です。
// ==========================================

class RulePreset {
  final String id;
  final String name;
  final String description;
  final TournamentRuleConfig config; // ★ プリセットが吐き出す設定本体

  const RulePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.config,
  });

  // ==========================================
  // ★ 6-3: Official Presets (公式プリセット一覧)
  // ここで生成されたconfigをUIのStateに渡し、後は自由に編集(Editable)させる
  // ==========================================

  /// 1. 小学生練成会 (1分30秒一本勝負、延長なし、時間切れ判定)
  static const RulePreset elementaryRenseikai = RulePreset(
    id: 'elementary_renseikai',
    name: '小学生練成会',
    description: '1分30秒一本勝負、延長なし、判定あり',
    config: TournamentRuleConfig(
      time: TimeConfig(matchTimeMinutes: 1.5, isRunningTime: false),
      scoring: ScoringConfig(isIpponShobu: true, ipponLimit: 1),
      encho: EnchoConfig(isEnchoUnlimited: false, enchoCount: 0),
      draw: DrawConfig(hasHantei: true),
    ),
  );

  /// 2. 高体連団体戦 (4分3本勝負、延長なし、引き分け、代表戦のみ一本勝負)
  static const RulePreset highSchoolTeam = RulePreset(
    id: 'high_school_team',
    name: '高体連団体戦',
    description: '4分3本勝負、延長なし、引き分けあり、代表戦は任意の延長戦',
    config: TournamentRuleConfig(
      time: TimeConfig(matchTimeMinutes: 4.0, isRunningTime: false),
      scoring: ScoringConfig(isIpponShobu: false, ipponLimit: 2),
      encho: EnchoConfig(isEnchoUnlimited: false, enchoCount: 0),
      team: TeamConfig(
        isKachinuki: false,
        hasRepresentativeMatch: true, 
        isDaihyoIpponShobu: true,
      ),
      draw: DrawConfig(hasHantei: false),
    ),
  );

  /// 3. 道場大会・一般 (3分3本勝負、2分延長1回、その後判定)
  static const RulePreset dojoTournament = RulePreset(
    id: 'dojo_tournament',
    name: '道場大会（一般）',
    description: '3分3本勝負、2分延長1回、その後判定',
    config: TournamentRuleConfig(
      time: TimeConfig(matchTimeMinutes: 3.0),
      encho: EnchoConfig(isEnchoUnlimited: false, enchoTimeMinutes: 2.0, enchoCount: 1),
      draw: DrawConfig(hasHantei: true),
    ),
  );

  /// 全公式プリセットのリスト
  static const List<RulePreset> officials = [
    elementaryRenseikai,
    highSchoolTeam,
    dojoTournament,
  ];
}