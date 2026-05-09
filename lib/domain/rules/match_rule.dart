import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kendo_os/domain/rules/tournament_rule_config.dart'; // ★ Phase 5: 新Configをインポート

part 'match_rule.freezed.dart';
part 'match_rule.g.dart';

// ★ 修正: MatchRule自体は内部に別のモデルを持たないので、通常の @freezed だけでOKです
@freezed
abstract class MatchRule with _$MatchRule {
  const MatchRule._(); // ★ Phase 5: クラス内にGetterメソッドを持たせるためのPrivate Constructor

  const factory MatchRule({
    // ==========================================
    // 🛡️ Domain Rules (真の試合ルール：Phase 5でConfig化する対象)
    // ==========================================
    // --- Scoring & Hansoku (得点・反則) ---
    @Default(2) int ipponLimit,     // 何本取ったら勝ちか（通常2本、サドンデスは1本）
    @Default(2) int hansokuLimit,   // 反則何回で相手に1本入るか（通常2回）
    @Default(false) bool isIpponShobu,
    
    // --- Time (時間) ---
    @Default(3.0) double matchTimeMinutes,
    @Default(false) bool isRunningTime,
    
    // --- Draw & Encho (判定・延長) ---
    @Default(false) bool hasHantei,
    @Default(false) bool isEnchoUnlimited,
    @Default(3.0) double enchoTimeMinutes,
    @Default(1) int enchoCount,
    
    // --- Team & Kachinuki (団体・勝ち抜き) ---
    @Default(false) bool isKachinuki,
    @Default('大将対大将') String kachinukiUnlimitedType,
    @Default(true) bool hasRepresentativeMatch,
    @Default(true) bool isDaihyoIpponShobu,

    // ==========================================
    // ⚠️ Metadata / UI Settings (ルールではないもの)
    // 将来、TournamentMetadata や UIState 等に分離・排除すべき項目
    // ==========================================
    // --- UI / 表示用メタデータ ---
    @Default(['選手']) List<String> positions,
    @Default([]) List<String> baseOrder,
    @Default('') String teamName,
    @Default('') String category,
    @Default('') String note,
    
    // --- 進行・リーグ構成 ---
    @Default(false) bool isLeague,
    @Default([]) List<String> leagueOrder,
    @Default(false) bool hasLeagueDaihyo,
    @Default(0.0) double winPoint,
    @Default(0.0) double lossPoint,
    @Default(0.0) double drawPoint,

    // --- 特殊大会形式 (練成会等) ---
    @Default(false) bool isRenseikai,
    @Default('一試合制') String renseikaiType,
    @Default(30) int overallTimeMinutes,
  }) = _MatchRule;

  factory MatchRule.fromJson(Map<String, dynamic> json) => _$MatchRuleFromJson(json);

  // ==========================================
  // ★ Phase 5: 新しい TournamentRuleConfig への変換アダプター
  // 既存DBを壊さずに、ドメイン層のみ新アーキテクチャへ移行するための架け橋
  // ==========================================
  TournamentRuleConfig get toRuleConfig {
    return TournamentRuleConfig(
      time: TimeConfig(matchTimeMinutes: matchTimeMinutes, isRunningTime: isRunningTime),
      encho: EnchoConfig(isEnchoUnlimited: isEnchoUnlimited, enchoTimeMinutes: enchoTimeMinutes, enchoCount: enchoCount),
      scoring: ScoringConfig(ipponLimit: ipponLimit, isIpponShobu: isIpponShobu),
      hansoku: HansokuConfig(hansokuLimit: hansokuLimit),
      team: TeamConfig(
        isKachinuki: isKachinuki, 
        kachinukiUnlimitedType: kachinukiUnlimitedType, 
        hasRepresentativeMatch: hasRepresentativeMatch, 
        isDaihyoIpponShobu: isDaihyoIpponShobu
      ),
      draw: DrawConfig(hasHantei: hasHantei),
    );
  }
}